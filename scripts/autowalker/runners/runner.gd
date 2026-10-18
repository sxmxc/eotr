extends Node

const Interface = preload("res://scripts/autowalker/core/gameplay_interface.gd")
const Policy = preload("res://scripts/autowalker/policies/policy.gd")
const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
const Progression = preload("res://scripts/autowalker/core/progression_interface.gd")
var run_mode := false
var run_node: Run
var ai_invalid_decisions := 0
var trace_generation := 0
var verify_watch := false
var captured := false
var interface = Interface.new()
var policy = Policy.new()
var world: GameWorld
var relics: RelicHandler
var simulation_seed := 1
var encounter := "res://resources/data/battles/tier_1_channelers_bulwark.tres"
var policy_name := "greedy"
var output := "res://build/autowalker"
var max_turns := 50
var max_actions := 500
var timeout_seconds := 120.0
var count := 1
var headless := false
var paused := true
var stopped := false
var busy := false
var step_budget := 0
var step_turn := -1
var delay := 0.0
var action_count := 0
var start_ms := 0
var progress_ms := 0
var results: Array = []
var trace: Array = []
var decision: Dictionary = {}
var replay: Dictionary = {}
var replay_index := 0
var report: Dictionary = {}
var obelisk_turn := -1
var summons := 0
var card_usage: Dictionary = {}
var initial_enemies := 0
var playback_speed := 1.0

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	headless = DisplayServer.get_name() == "headless"
	var args := OS.get_cmdline_user_args()
	verify_watch = args.has("--verify-watch")
	for arg in args:
		var parts := arg.trim_prefix("--").split("=", true, 1)
		if parts.size() != 2:
			continue
		match parts[0]:
			"mode": run_mode = parts[1] == "run"
			"seed": simulation_seed = int(parts[1])
			"policy": policy_name = parts[1]
			"encounter": encounter = parts[1]
			"count": count = maxi(1, int(parts[1]))
			"max-turns": max_turns = maxi(1, int(parts[1]))
			"max-actions": max_actions = maxi(1, int(parts[1]))
			"timeout": timeout_seconds = float(parts[1])
			"output": output = parts[1]
			"replay": load_replay(parts[1])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	GameSettings.show_tutorial = false
	TelemetryManager.configure_qa(output.path_join("events.jsonl"))
	Events.obelisk_destroyed.connect(func(): obelisk_turn = world.current_round if is_instance_valid(world) else -1)
	Events.enemy_spawned.connect(func(_enemy: Enemy, summoned: bool):
		if summoned: summons += 1)
	Events.enemy_decision_rejected.connect(func(_enemy: Enemy, _reason: String): ai_invalid_decisions += 1)
	if headless or args.has("--autostart"):
		start.call_deferred()

func load_replay(path: String) -> bool:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary or not value.has("trace") or not value.has("seed"):
		return false
	replay = value
	simulation_seed = int(value.seed)
	encounter = value.encounter
	policy_name = value.policy
	run_mode = value.get("mode", "encounter") == "run"
	return true

func start() -> void:
	if busy:
		return
	trace_generation += 1
	if is_instance_valid(world):
		if world.get_parent() == self:
			remove_child(world)
			world.queue_free()
	if is_instance_valid(relics):
		remove_child(relics)
		relics.queue_free()
	if is_instance_valid(run_node):
		remove_child(run_node)
		run_node.queue_free()
	await get_tree().process_frame
	seed(simulation_seed)
	RNG.instance.seed = simulation_seed
	policy.name = policy_name
	policy.rng.seed = simulation_seed ^ 0xA170
	trace.clear()
	card_usage.clear()
	decision.clear()
	action_count = 0
	replay_index = 0
	obelisk_turn = -1
	summons = 0
	ai_invalid_decisions = 0
	stopped = false
	paused = false
	get_tree().paused = false
	start_ms = Time.get_ticks_msec()
	progress_ms = start_ms
	interface.progression = null
	if run_mode:
		run_node = load("res://scenes/run/run.tscn").instantiate()
		run_node.run_bootstrap = RunBootstrap.new()
		run_node.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
		run_node.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
		add_child(run_node)
		interface.progression = Progression.new()
		interface.progression.run_node = run_node
		world = null
	else:
		world = WORLD.instantiate()
		relics = RELICS.instantiate()
		add_child(relics)
		add_child(world)
		world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
		world.run_stats = RunStats.new()
		world.battle_stats = load(encounter).duplicate(true)
		world.relics = relics
		world.start_world()
		initial_enemies = world.enemy_handler.get_child_count()
	interface.world = world
	Utils.presentation_speed = playback_speed
	report = {"seed": simulation_seed, "policy": policy_name, "policy_version": Policy.VERSION,
		"encounter": encounter, "build_version": ProjectSettings.get_setting("application/config/version"),
		"engine": Engine.get_version_info().string, "source_type": "bot", "mode": "run" if run_mode else "encounter",
		"initial_health": run_node.player_stats.health if run_mode else world.player_stats.health}
	TelemetryManager.client.set_context({"run_id": "autowalker-%d" % simulation_seed})
	TelemetryManager.track_event("simulation_started", {"seed": simulation_seed, "policy": policy_name, "encounter": encounter})

func _process(delta: float) -> void:
	if stopped or (not is_instance_valid(world) and not is_instance_valid(run_node)):
		return
	if run_mode:
		world = interface.progression.view() as GameWorld
		interface.world = world
	if paused and not busy and step_budget <= 0 and step_turn < 0:
		start_ms += int(delta * 1000)
		progress_ms += int(delta * 1000)
		return
	if run_mode and (run_node.player_stats.health <= 0 or interface.progression.view() is WinScreen):
		finish("loss" if run_node.player_stats.health <= 0 else "win")
		return
	if not run_mode and world.battle_over_handled:
		finish("win" if world.victory_committed else "loss")
		return
	var now := Time.get_ticks_msec()
	if now - start_ms > timeout_seconds * 1000:
		finish("timeout")
		return
	if now - progress_ms > 30000:
		finish("softlock", "No completed action or turn in 30 seconds")
		return
	if turn_number() > max_turns or action_count >= max_actions:
		finish("aborted", "Configured turn/action limit; not necessarily a defect")
		return
	if busy or not interface.ready_for_action():
		return
	if step_turn >= 0 and turn_number() > step_turn:
		step_turn = -1
		paused = true
		return
	delay -= delta
	if delay > 0:
		return
	act()

func act() -> void:
	busy = true
	var epoch := trace_generation
	var actions: Array[Dictionary] = interface.legal_actions()
	if actions.is_empty():
		busy = false
		return
	var before: String = interface.fingerprint()
	var action: Dictionary
	if not replay.is_empty():
		if replay_index >= replay.trace.size():
			busy = false
			finish("replay_complete")
			return
		var entry: Dictionary = replay.trace[replay_index]
		if entry.before != before:
			busy = false
			finish("divergence", "Checkpoint mismatch before action %d" % replay_index)
			return
		action = entry.action
		decision = {"action": action, "reason": "Recorded replay", "alternatives": []}
	else:
		decision = policy.choose(interface.observe(), actions)
		action = decision.action
	trace.append({"index": action_count, "turn": turn_number(), "action": action, "before": before, "checkpoint": interface.checkpoint(), "rng": str(RNG.instance.state)})
	var accepted: bool = await interface.execute(action)
	if epoch != trace_generation or stopped:
		return
	if not accepted:
		busy = false
		finish("invalid_action", "Action failed live validation")
		return
	if action.kind == "play_card":
		card_usage[action.card] = card_usage.get(action.card, 0) + 1
	action_count += 1
	replay_index += 1
	progress_ms = Time.get_ticks_msec()
	step_budget = maxi(0, step_budget - 1)
	delay = 0.4 / playback_speed if not headless else 0.0
	TelemetryManager.track_event("simulation_action", {"index": action_count, "action": action, "turn": turn_number()})
	busy = false
	if verify_watch and not captured and action_count >= 2:
		captured = true
		capture_watch.call_deferred()

func finish(outcome: String, reason: String = "") -> void:
	if stopped:
		return
	stopped = true
	trace_generation += 1
	busy = false
	report.merge({"outcome": outcome, "reason": reason, "turns": turn_number(), "actions": action_count,
		"damage_taken": report.initial_health - (run_node.player_stats.health if run_mode else world.player_stats.health), "obelisk_destroyed_turn": obelisk_turn,
		"summons": summons, "ai_invalid_decisions": ai_invalid_decisions, "invalid_actions": 1 if outcome == "invalid_action" else 0,
		"card_usage": card_usage.duplicate(), "duration_ms": Time.get_ticks_msec() - start_ms,
		"trace": trace.duplicate(true), "final_state": interface.checkpoint()}, true)
	var file := FileAccess.open(output.path_join("simulation-%d.json" % simulation_seed), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	TelemetryManager.track_event("simulation_completed", {"outcome": outcome, "seed": simulation_seed, "policy": policy_name, "turns": turn_number(), "duration_ms": report.duration_ms})
	TelemetryManager.client.flush()
	results.append(report.duplicate(true))
	print("AutoWalker bot seed=%d policy=%s outcome=%s turns=%d actions=%d %s" % [simulation_seed, policy_name, outcome, turn_number(), action_count, reason])
	if headless and results.size() < count:
		simulation_seed += 1
		start.call_deferred()
	elif headless or verify_watch:
		write_summary()
		get_tree().quit()

func write_summary() -> void:
	var summary := {"source_type": "bot", "simulations": results.size(), "wins": 0, "losses": 0, "aborted": 0, "failures": 0, "timeouts": 0, "softlocks": 0}
	for result in results:
		match result.outcome:
			"win": summary.wins += 1
			"loss": summary.losses += 1
			"aborted", "replay_complete": summary.aborted += 1
			_:
				summary.failures += 1
				if result.outcome == "timeout": summary.timeouts += 1
				if result.outcome == "softlock": summary.softlocks += 1
	summary["win_rate"] = float(summary.wins) / maxf(results.size(), 1)
	var file := FileAccess.open(output.path_join("summary.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(summary, "\t"))
	print("AutoWalker summary: " + JSON.stringify(summary))

func turn_number() -> int:
	return world.current_round if is_instance_valid(world) else (run_node.map.floors_climbed if is_instance_valid(run_node) else 0)

func capture_watch() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("watch.png"))
