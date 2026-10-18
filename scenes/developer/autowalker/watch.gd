extends Node

@onready var runner = $Runner
@onready var panel = $Overlay/Panel/Controls

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	panel.get_node("Start").pressed.connect(_start)
	panel.get_node("Stop").pressed.connect(func(): runner.paused = true; runner.stopped = true)
	panel.get_node("Play").pressed.connect(func(): runner.paused = false; runner.progress_ms = Time.get_ticks_msec(); runner.start_ms = Time.get_ticks_msec())
	panel.get_node("Pause").pressed.connect(func(): runner.paused = true)
	panel.get_node("StepAction").pressed.connect(func(): runner.paused = true; runner.step_budget = 1; runner.progress_ms = Time.get_ticks_msec())
	panel.get_node("StepTurn").pressed.connect(func(): runner.paused = true; runner.step_turn = runner.turn_number(); runner.progress_ms = Time.get_ticks_msec())
	panel.get_node("Restart").pressed.connect(func(): runner.start())
	panel.get_node("Speed").item_selected.connect(func(index: int):
		runner.playback_speed = [0.5, 1.0, 2.0, 4.0][index]
		Utils.presentation_speed = runner.playback_speed)
	panel.get_node("LoadReplay").pressed.connect(func():
		if runner.load_replay(panel.get_node("ReplayPath").text):
			runner.start())
	if DisplayServer.get_name() == "headless":
		$Overlay.hide()

func _start() -> void:
	runner.replay.clear()
	runner.simulation_seed = int(panel.get_node("Seed").text)
	runner.policy_name = panel.get_node("Policy").get_item_text(panel.get_node("Policy").selected)
	runner.run_mode = panel.get_node("Mode").selected == 1
	runner.encounter = panel.get_node("Encounter").text
	runner.start()

func _process(_delta: float) -> void:
	if not is_instance_valid(runner.world) and not is_instance_valid(runner.run_node):
		return
	panel.get_node("Inspector").text = "Seed %d | %s | %s | turn %d\n%s\n%s" % [runner.simulation_seed, runner.policy_name, "paused" if runner.paused else "playing", runner.turn_number(), JSON.stringify(runner.interface.observe()), JSON.stringify(runner.decision)]
