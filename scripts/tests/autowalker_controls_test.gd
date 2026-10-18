extends Node

var failures := 0

func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func until(predicate: Callable, seconds: float = 10.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return predicate.call()

func run() -> void:
	var watch: Node = load("res://scenes/developer/autowalker/watch.tscn").instantiate()
	var runner = watch.get_node("Runner")
	runner.automatic_start = false
	runner.quit_when_finished = false
	runner.output = "res://build/controls-test"
	add_child(watch)
	await runner.start()
	runner.paused = true
	check(await until(func(): return runner.interface.ready_for_action()), "Initial action boundary resolves while bot paused")
	check(runner.action_count == 0, "Pause prevents new actions")
	var controls: Node = watch.get_node("Overlay/Panel/Controls")
	controls.get_node("StepAction").pressed.emit()
	check(await until(func(): return runner.action_count == 1 and not runner.busy), "Step one actual action")
	await get_tree().create_timer(0.1).timeout
	check(runner.action_count == 1 and runner.paused, "Action step stays paused")
	var first_turn: int = runner.turn_number()
	controls.get_node("StepTurn").pressed.emit()
	check(await until(func(): return runner.turn_number() > first_turn and runner.step_turn == -1 and not runner.busy), "Turn step resolves enemies and pauses on next turn")
	check(await until(func(): return runner.interface.ready_for_action()), "Stepped turn finishes drawing before teardown")
	var scale_before := Engine.time_scale
	controls.get_node("Speed").item_selected.emit(3)
	check(runner.playback_speed == 4.0 and Utils.presentation_speed == 4.0 and Engine.time_scale == scale_before, "Speed changes presentation without global simulation time")
	controls.get_node("Stop").pressed.emit()
	check(runner.stopped, "Stop control")
	await get_tree().create_timer(1.0).timeout
	watch.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	Utils.presentation_speed = 1.0
	TelemetryManager.suspended = true
	print("AutoWalker controls tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
