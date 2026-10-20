extends Node
## Development-only recorder around the real AutoWalker combat executor.
@onready var runner = $Runner
var elapsed := 0.0
var duration := 12.0
var output := ""
var events: Array = []
var seen := 0
var done := false

func _ready() -> void:
	if not OS.is_debug_build() or DisplayServer.get_name() == "headless":
		printerr("Visual capture requires a debug build and a real rendering display.")
		get_tree().quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="): duration = float(arg.get_slice("=", 1))
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
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
