extends Node

@export var automatic_start := true
@export var quit_when_finished := true

const Interface = preload("res://scripts/autowalker/core/gameplay_interface.gd")
const Policy = preload("res://scripts/autowalker/policies/policy.gd")
const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
const Progression = preload("res://scripts/autowalker/core/progression_interface.gd")
const Watchdog = preload("res://scripts/autowalker/core/watchdog.gd")
const Loadouts = preload("res://scripts/autowalker/core/loadouts.gd")
var player_class := "riftwalker"
var loadout_selection := "tier"
var health_percent := 100
var loadout_snapshot: Dictionary = {}
var watchdog = Watchdog.new()
var diagnostic_warnings: Array = []
var last_checkpoint: Dictionary = {}
var run_mode := false
var run_node: Run
var ai_invalid_decisions := 0
var invalid_actions := 0
var actions_this_turn := 0
var last_action_turn := -1
var trace_generation := 0
var verify_watch := false
var captured := false
var startup_error := ""
var launcher_stop_file := ""
var interface = Interface.new()
var policy = Policy.new()
var world: GameWorld
var relics: RelicHandler
var simulation_seed := 1
var encounter := "res://resources/data/battles/tier_1_channelers_bulwark.tres"
var policy_name := "greedy"
var output := "res://.qa-tmp/autowalker"
var max_turns := 50
var max_actions := 500
var max_actions_per_turn := 100
var timeout_seconds := 120.0
var count := 1
var headless := false
var paused := true
var stopped := false
var restart_requested := false
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
var simulation_run_id := ""
var trace_bytes := 0
const MAX_TRACE_BYTES := 16 * 1024 * 1024

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
			"class": player_class = parts[1]
			"loadout": loadout_selection = parts[1]
			"health-percent": health_percent = int(parts[1])
			"seed": simulation_seed = int(parts[1])
			"policy": policy_name = parts[1]
			"encounter": encounter = parts[1]
			"count": count = maxi(1, int(parts[1]))
			"max-turns": max_turns = maxi(1, int(parts[1]))
			"max-actions": max_actions = maxi(1, int(parts[1]))
			"max-actions-per-turn": max_actions_per_turn = maxi(1, int(parts[1]))
			"timeout": timeout_seconds = float(parts[1])
			"output": output = parts[1]
			"stop-file": launcher_stop_file = parts[1]
			"replay":
				if not load_replay(parts[1]):
					startup_error = "Cannot load replay: " + parts[1]
	if player_class not in ["riftwalker", "synthforged"]:
		startup_error = "Invalid player class"
	if loadout_selection not in ["tier", "starter", "tier_0", "tier_1", "tier_2", "legacy"] or health_percent < 1 or health_percent > 100:
		startup_error = "Invalid loadout or health percent"
	if run_mode and (loadout_selection != "tier" or health_percent != 100):
		startup_error = "Encounter loadouts cannot be applied to run mode"
	if not startup_error.is_empty():
		printerr(startup_error)
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	GameSettings.show_tutorial = false
	TelemetryManager.configure_qa(output.path_join("events.jsonl"))
	Events.obelisk_destroyed.connect(func(): obelisk_turn = world.current_round if is_instance_valid(world) else -1)
	Events.enemy_spawned.connect(func(_enemy: Enemy, summoned: bool):
		if summoned: summons += 1)
	Events.enemy_decision_rejected.connect(func(_enemy: Enemy, _reason: String): ai_invalid_decisions += 1)
	Events.enemy_action_completed.connect(func(_enemy: Enemy): progress_ms = Time.get_ticks_msec())
	if automatic_start and (headless or args.has("--autostart")):
		start.call_deferred()

func load_replay(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary or not value.has("trace") or not value.has("seed"):
		return false
	replay = value
	simulation_seed = int(value.seed)
	encounter = value.encounter
	policy_name = value.policy
	player_class = value.get("player_class", "riftwalker")
	run_mode = value.get("mode", "encounter") == "run"
	loadout_selection = value.get("loadout_selection", "tier" if run_mode else "legacy")
	health_percent = int(value.get("health_percent", 100))
	return true

func start() -> void:
	if busy:
		restart_requested = true
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
	trace_bytes = 0
	diagnostic_warnings.clear()
	last_checkpoint.clear()
	watchdog.checked_round = -1
	card_usage.clear()
	decision.clear()
	action_count = 0
	replay_index = 0
	obelisk_turn = -1
	summons = 0
	ai_invalid_decisions = 0
	invalid_actions = 0
	actions_this_turn = 0
	last_action_turn = -1
	stopped = false
	paused = false
	get_tree().paused = false
	start_ms = Time.get_ticks_msec()
	progress_ms = start_ms
	interface.progression = null
	loadout_snapshot = {"loadout": "run_progression", "loadout_selection": "tier", "loadout_version": 1,
		"loadout_fingerprint": "run_progression_v1", "loadout_basis": "live_progression"}
	# Run/encounter startup emits events immediately, so bind context first.
	simulation_run_id = TelemetryManager.begin_qa_simulation()
	if run_mode:
		run_node = load("res://scenes/run/run.tscn").instantiate()
		run_node.run_bootstrap = RunBootstrap.new()
		run_node.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
		run_node.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/%s_starting_stats.tres" % player_class)
		add_child(run_node)
		interface.progression = Progression.new()
		interface.progression.run_node = run_node
		world = null
	else:
		world = WORLD.instantiate()
		relics = RELICS.instantiate()
		add_child(relics)
		add_child(world)
		world.player_stats = load("res://resources/data/stats/player/%s_starting_stats.tres" % player_class).create_instance()
		world.run_stats = RunStats.new()
		world.battle_stats = load(encounter).duplicate(true)
		var campaign := ActDefinition.campaign()
		for act_index in campaign.size():
			if campaign[act_index].encounters.find(world.battle_stats.encounter_id):
				world.run_stats.act_index = act_index
				TelemetryManager.progression_context = {"act": act_index + 1, "act_id": campaign[act_index].act_id,
					"encounter_id": world.battle_stats.encounter_id, "encounter_category": EncounterDefinition.Category.keys()[world.battle_stats.category]}
				break
		world.relics = relics
		loadout_snapshot = Loadouts.apply(world.player_stats, relics, loadout_selection, world.battle_stats.battle_tier, health_percent)
		if replay.has("loadout_fingerprint") and replay.loadout_fingerprint != loadout_snapshot.loadout_fingerprint:
			printerr("Replay loadout changed; regenerate the recording")
			get_tree().quit(1)
			return
		world.start_world()
		initial_enemies = world.enemy_handler.get_child_count()
	interface.world = world
	Utils.presentation_speed = playback_speed
	report = {"seed": simulation_seed, "policy": policy_name, "policy_version": Policy.VERSION,
		"encounter": "run" if run_mode else encounter, "build_version": ProjectSettings.get_setting("application/config/version"),
		"engine": Engine.get_version_info().string, "source_type": "bot", "mode": "run" if run_mode else "encounter",
		"initial_health": run_node.player_stats.health if run_mode else world.player_stats.health,
		"metrics_version": 2, "session_id": TelemetryManager.client.session_id, "run_id": simulation_run_id}
	if player_class != "riftwalker": report["player_class"] = player_class
	report.merge(loadout_snapshot, true)
	TelemetryManager.track_event("simulation_started", {"seed": simulation_seed, "policy": policy_name, "encounter": "run" if run_mode else encounter}, 1, loadout_snapshot)

func _process(delta: float) -> void:
	if not launcher_stop_file.is_empty() and FileAccess.file_exists(launcher_stop_file):
		paused = true
		if busy:
			return
		stopped = true
		restart_requested = false
		set_process(false)
		TelemetryManager.request_quit()
		return
	if restart_requested and not busy:
		restart_requested = false
		start()
		return
	if stopped:
		return
	if not is_instance_valid(world) and not is_instance_valid(run_node):
		if not report.is_empty():
			finish("unexpected_teardown", "Simulation scene disappeared")
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
	if TelemetryManager.qa_turns > max_turns:
		finish("aborted", "Configured cumulative turn limit reached", "turn_limit")
		return
	if action_count >= max_actions:
		finish("aborted", "Configured simulation action limit reached", "action_limit")
		return
	if busy or not interface.ready_for_action():
		return
	if is_instance_valid(world) and not world.battle_over_handled:
		var inspection: Dictionary = watchdog.inspect(world)
		if not inspection.fatal.is_empty():
			finish("invariant_failure", inspection.fatal)
			return
		for warning in inspection.warnings:
			if not warning in diagnostic_warnings:
				diagnostic_warnings.append(warning)
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
	if last_action_turn != turn_number():
		last_action_turn = turn_number()
		actions_this_turn = 0
	if actions_this_turn >= max_actions_per_turn:
		busy = false
		finish("aborted", "Per-turn legal-action limit; possible bot cycling", "per_turn_action_limit")
		return
	var epoch := trace_generation
	var actions: Array[Dictionary] = interface.legal_actions()
	if actions.is_empty():
		busy = false
		return
	var before: String = interface.fingerprint()
	last_checkpoint = interface.checkpoint()
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
	var trace_entry := {"index": action_count, "turn": turn_number(), "action": action, "before": before, "checkpoint": interface.checkpoint(), "rng": str(RNG.instance.state)}
	trace_bytes += JSON.stringify(trace_entry).to_utf8_buffer().size()
	if trace_bytes > MAX_TRACE_BYTES:
		busy = false
		finish("aborted", "Local replay trace reached the 16 MiB limit", "trace_limit")
		return
	trace.append(trace_entry)
	var accepted: bool = await interface.execute(action)
	if epoch != trace_generation or stopped:
		return
	if not accepted:
		busy = false
		invalid_actions += 1
		if invalid_actions >= 3 or not replay.is_empty():
			finish("invalid_action", "Action failed live validation")
		return
	if action.kind == "play_card":
		card_usage[action.card] = card_usage.get(action.card, 0) + 1
	action_count += 1
	actions_this_turn += 1
	replay_index += 1
	progress_ms = Time.get_ticks_msec()
	step_budget = maxi(0, step_budget - 1)
	delay = 0.4 / playback_speed if not headless else 0.0
	TelemetryManager.track_event("simulation_action", {"index": action_count, "action": action, "turn": turn_number()})
	busy = false
	if verify_watch and not captured and action_count >= 2:
		captured = true
		capture_watch.call_deferred()

func finish(outcome: String, reason: String = "", reason_code: String = "") -> void:
	if stopped:
		return
	stopped = true
	trace_generation += 1
	busy = false
	var final_health: int = report.initial_health
	if is_instance_valid(run_node):
		final_health = run_node.player_stats.health
	elif is_instance_valid(world):
		final_health = world.player_stats.health
	var final_state: Dictionary = interface.checkpoint() if is_instance_valid(world) or is_instance_valid(run_node) else last_checkpoint
	var stats: PlayerStats = run_node.player_stats if is_instance_valid(run_node) else (world.player_stats if is_instance_valid(world) else null)
	var current_view: Node = interface.progression.view() if run_mode and is_instance_valid(run_node) else world
	var details := {"reason": reason.left(512), "reason_code": reason_code if not reason_code.is_empty() else outcome,
		"scene": current_view.scene_file_path if is_instance_valid(current_view) else "",
		"policy_version": Policy.VERSION, "encounter": report.encounter,
		"current_encounter": world.battle_stats.encounter_id if is_instance_valid(world) and world.battle_stats else "",
		"actions": action_count, "actions_this_turn": actions_this_turn,
		"max_turns": max_turns, "max_actions": max_actions, "max_actions_per_turn": max_actions_per_turn,
		"timeout_seconds": timeout_seconds, "final_health": final_health,
		"invalid_actions": invalid_actions, "ai_invalid_decisions": ai_invalid_decisions,
		"warning_count": diagnostic_warnings.size(), "last_action": trace.back().action if not trace.is_empty() else {}}
	details.merge(loadout_snapshot, true)
	report.merge(details, true)
	report.merge({"outcome": outcome, "reason": reason, "turns": TelemetryManager.qa_turns,
		"last_battle_turn": turn_number() if is_instance_valid(world) else 0,
		"floors_climbed": run_node.run_stats.completed_floors + run_node.map.floors_climbed if is_instance_valid(run_node) else 0, "actions": action_count,
		"damage_taken": stats.total_health_damage if stats else 0,
		"net_health_loss": report.initial_health - final_health, "healing_received": stats.total_healing if stats else 0,
		"obelisk_destroyed_turn": obelisk_turn,
		"summons": summons, "ai_invalid_decisions": ai_invalid_decisions, "invalid_actions": invalid_actions,
		"card_usage": card_usage.duplicate(), "duration_ms": Time.get_ticks_msec() - start_ms,
		"trace": trace.duplicate(true), "final_state": final_state, "warnings": diagnostic_warnings.duplicate()}, true)
	var file := FileAccess.open(output.path_join("simulation-%d.json" % simulation_seed), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report))
		file.close()
	prune_reports()
	TelemetryManager.track_event("simulation_completed", {"outcome": outcome, "seed": simulation_seed, "policy": policy_name,
		"mode": report.mode, "turns": report.turns, "last_battle_turn": report.last_battle_turn,
		"floors_climbed": report.floors_climbed, "damage_taken": report.damage_taken,
		"net_health_loss": report.net_health_loss, "healing_received": report.healing_received, "duration_ms": report.duration_ms}, 2, details)
	TelemetryManager.flush()
	var compact := report.duplicate(true)
	compact.erase("trace")
	compact.erase("final_state")
	results.append(compact)
	print("AutoWalker bot seed=%d policy=%s outcome=%s turns=%d actions=%d %s" % [simulation_seed, policy_name, outcome, report.turns, action_count, reason])
	if headless and results.size() < count:
		simulation_seed += 1
		start.call_deferred()
	elif headless or verify_watch:
		TelemetryManager.track_event("session_ended", {"duration_ms": Time.get_ticks_msec() - TelemetryManager.session_start_ms})
		await TelemetryManager.flush_pending()
		write_summary()
		if quit_when_finished:
			await Utils.stop_audio_for_shutdown()
			get_tree().quit()

func write_summary() -> void:
	var summary := {"source_type": "bot", "simulations": results.size(), "wins": 0, "losses": 0, "aborted": 0, "failures": 0, "timeouts": 0, "softlocks": 0}
	summary.merge({"policy": policy_name, "policy_version": Policy.VERSION, "encounter": "run" if run_mode else encounter,
		"metrics_version": 2, "session_id": TelemetryManager.client.session_id, "mode": "run" if run_mode else "encounter",
		"build_version": ProjectSettings.get_setting("application/config/version"), "turn_counts": [],
		"damage_taken": [], "net_health_loss": [], "healing_received": [], "floors_climbed": [],
		"obelisk_destructions": 0, "obelisk_destroyed_turns": [], "summons": 0,
		"invalid_actions": 0, "ai_invalid_decisions": 0, "duration_ms": 0, "card_usage": {}})
	summary.merge(loadout_snapshot, true)
	for result in results:
		summary.turn_counts.append(result.turns)
		summary.damage_taken.append(result.damage_taken)
		summary.net_health_loss.append(result.net_health_loss)
		summary.healing_received.append(result.healing_received)
		summary.floors_climbed.append(result.floors_climbed)
		if result.obelisk_destroyed_turn >= 0:
			summary.obelisk_destructions += 1
			summary.obelisk_destroyed_turns.append(result.obelisk_destroyed_turn)
		for metric in ["summons", "invalid_actions", "ai_invalid_decisions", "duration_ms"]:
			summary[metric] += result.get(metric, 0)
		for card in result.card_usage:
			summary.card_usage[card] = summary.card_usage.get(card, 0) + result.card_usage[card]
		match result.outcome:
			"win": summary.wins += 1
			"loss": summary.losses += 1
			"aborted", "replay_complete": summary.aborted += 1
			_:
				summary.failures += 1
				if result.outcome == "timeout": summary.timeouts += 1
				if result.outcome == "softlock": summary.softlocks += 1
	summary["win_rate"] = float(summary.wins) / maxf(results.size(), 1)
	summary["telemetry"] = TelemetryManager.health()
	var file := FileAccess.open(output.path_join("summary.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(summary, "\t"))
	print("AutoWalker summary: " + JSON.stringify(summary))

func turn_number() -> int:
	return world.current_round if is_instance_valid(world) else (run_node.map.floors_climbed if is_instance_valid(run_node) else 0)

func prune_reports() -> void:
	var records: Array[Dictionary] = []
	var total := 0
	for filename in DirAccess.get_files_at(output):
		if not filename.begins_with("simulation-") or not filename.ends_with(".json"):
			continue
		var path := output.path_join(filename)
		var report_file := FileAccess.open(path, FileAccess.READ)
		if not report_file:
			continue
		var size := report_file.get_length()
		report_file.close()
		total += size
		records.append({"path": path, "bytes": size, "modified": FileAccess.get_modified_time(path)})
	records.sort_custom(func(a: Dictionary, b: Dictionary): return a.modified < b.modified)
	var remaining := records.size()
	for record in records:
		if record.path == output.path_join("simulation-%d.json" % simulation_seed):
			continue
		if remaining > 32 or total > 64 * 1024 * 1024:
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(record.path)) == OK:
				remaining -= 1
				total -= int(record.bytes)

func capture_watch() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("watch.png"))
