extends Node
## Development-only recorder around the real AutoWalker combat executor.
@onready var runner = $Runner
var elapsed := 0.0
var duration := 12.0
var output := ""
var events: Array = []
var seen := 0
var done := false
var expansion_fixture := false
var synthforged_fixture := false
var synthforged_started := false
var ruin_fixture := false
var ruin_stage := 0
var ruin_time := 0.0
var capture_frames := false
var frame_index := 0
const FRAME_TIMES := [1.5, 4.0, 8.0]

func _ready() -> void:
	if not OS.is_debug_build() or DisplayServer.get_name() == "headless":
		printerr("Visual capture requires a debug build and a real rendering display.")
		get_tree().quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture-frames": capture_frames = true
		if arg == "--fixture=synthforged": synthforged_fixture = true
		if arg == "--fixture=expansion":
			expansion_fixture = true
			synthforged_fixture = true
		if arg == "--fixture=ruin": ruin_fixture = true
		if arg.begins_with("--duration="): duration = float(arg.get_slice("=", 1))
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if capture_frames: Engine.max_fps = 60
	Events.card_played.connect(func(card: Card): mark("card_played", {"card": card.id, "name": card.name}))
	Events.enemy_action_completed.connect(func(enemy: Enemy): mark("enemy_action_completed", {"name": enemy.stats.enemy_name}))
	Events.player_turn_started.connect(func(): mark("player_turn_started", {}))
	Events.player_turn_ended.connect(func(): mark("player_turn_ended", {}))
	runner.start.call_deferred()

func mark(kind: String, details: Dictionary) -> void:
	events.append({"time": elapsed, "kind": kind, "details": details})

func _process(delta: float) -> void:
	if done: return
	elapsed += delta
	if capture_frames and frame_index < FRAME_TIMES.size() and elapsed >= FRAME_TIMES[frame_index]:
		frame_index += 1
		_capture_environment_frame(frame_index)
	if synthforged_fixture and is_instance_valid(runner.world):
		runner.paused = true
		if not synthforged_started and runner.world.player_handler.hand_ready:
			synthforged_started = true
			_run_synthforged_fixture()
	if ruin_fixture and is_instance_valid(runner.world):
		runner.paused = true
		if runner.world.tilemap.has_start_tile_effects_pending():
			return
		if ruin_stage == 0 and elapsed >= 1.0:
			_activate_ruin("block_tile_effect")
		elif ruin_stage == 1 and elapsed >= ruin_time + 1.5:
			_activate_ruin("empty_tile_effect")
	while seen < runner.trace.size():
		mark("action_started", runner.trace[seen].action)
		seen += 1
	if elapsed < duration: return
	done = true
	var data := {"duration": elapsed, "fps": Engine.get_frames_per_second(), "events": events,
		"trace": runner.trace, "state": runner.interface.observe() if is_instance_valid(runner.world) else {},
		"seed": runner.simulation_seed, "encounter": runner.encounter,
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"clock": "Movie Writer fixed process delta; action starts observed within one frame"}
	var file := FileAccess.open(output.path_join("timing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	get_tree().quit()

func _capture_environment_frame(index: int) -> void:
	await RenderingServer.frame_post_draw
	var name := "frame-%02d.png" % index
	get_viewport().get_texture().get_image().save_png(output.path_join(name))
	mark("rendered_frame", {"file": name, "time": elapsed})

func _activate_ruin(effect_id: String) -> void:
	# Explicit fixture setup: repeat activation on the occupied tile through real gameplay.
	var board: ProcGenTilemap = runner.world.tilemap
	board.tile_map_data[board.player_position].type = Enums.TileType.ANCIENT_RUIN
	board.ruin_tile_effects.assign([load("res://resources/data/tile_effects/%s.tres" % effect_id)])
	board.presentation_changed.emit()
	mark("ruin_activation", {"effect": effect_id, "cell": str(board.player_position)})
	board.apply_tile_effects()
	ruin_stage += 1
	ruin_time = elapsed
	_capture_ruin_phases(ruin_stage)

func _capture_ruin_phases(stage: int) -> void:
	for phase: String in ["contact", "rise", "recovery"]:
		await get_tree().create_timer(0.12 if phase != "recovery" else 0.5).timeout
		await RenderingServer.frame_post_draw
		var filename := "ruin-%d-%s.png" % [stage, phase]
		get_viewport().get_texture().get_image().save_png(output.path_join(filename))
		mark("ruin_frame", {"file": filename, "phase": phase})


func _run_synthforged_fixture() -> void:
	if expansion_fixture:
		var expansion := ExpansionCardFixture.new()
		mark("fixture_setup", {"fixture": "expansion", "class": runner.world.player_stats.player_class_name, "note": "Real CardUI with controlled resources/statuses/terrain/allies; no natural-run claim."})
		var findings := await expansion.run(runner.world, _capture_synthforged)
		mark("fixture_completed", {"failures": findings})
		for finding in findings: printerr("Expansion visual fixture: " + finding)
		return
	var fixture := SynthforgedCardFixture.new()
	mark("fixture_setup", {"fixture": "synthforged", "note": "Authored cards through CardUI; high energy/hostile HP, revealed resource cells, repositioned targets, fresh allies per card."})
	var failures := await fixture.run(runner.world, _capture_synthforged)
	var lifecycle := SynthforgedLifecycleFixture.new()
	failures.append_array(await lifecycle.run(runner.world, _capture_synthforged))
	mark("fixture_completed", {"failures": failures})
	for failure: String in failures: printerr("Synthforged visual fixture: " + failure)

func _capture_synthforged(card_id: String, phase: String, delay: float) -> void:
	if delay > 0: await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var filename := "synthforged-%s-%s.png" % [card_id, phase]
	get_viewport().get_texture().get_image().save_png(output.path_join(filename))
	mark("synthforged_frame", {"card": card_id, "phase": phase, "file": filename})
