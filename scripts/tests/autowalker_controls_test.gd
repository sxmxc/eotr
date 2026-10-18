extends Node

var failures := 0

class FakeUpload:
	extends Node
	var batches: Array = []
	var result := {"ok": true}
	func deliver(batch: Array) -> Dictionary:
		batches.append(batch.duplicate(true))
		await get_tree().create_timer(0.01).timeout
		return result.duplicate()
	func purge() -> void:
		pass

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
	test_health_metrics()
	test_report_retention()
	await test_qa_upload()
	if OS.get_cmdline_user_args().has("--telemetry-only"):
		TelemetryManager.suspended = true
		await get_tree().process_frame
		print("AutoWalker telemetry tests: %d failures" % failures)
		get_tree().quit(1 if failures else 0)
		return
	var watch: Node = load("res://scenes/developer/autowalker/watch.tscn").instantiate()
	var runner = watch.get_node("Runner")
	runner.automatic_start = false
	runner.quit_when_finished = false
	runner.output = "res://qa/controls-test"
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

func test_health_metrics() -> void:
	var stats := Stats.new()
	stats.max_health = 20
	stats.health = 20
	stats.block = 5
	stats.take_damage(8)
	stats.heal(2)
	stats.take_direct_damage(25)
	check(stats.total_health_damage == 22 and stats.total_healing == 2 and stats.health == 0,
		"Health metrics include healing, exclude block and clamp overkill to actual health loss")
	var fresh: Stats = stats.create_instance()
	check(fresh.total_health_damage == 0 and fresh.total_healing == 0, "New stats reset cumulative counters")

func test_report_retention() -> void:
	var runner = load("res://scripts/autowalker/runners/runner.gd").new()
	runner.output = "res://qa/report-retention-test"
	runner.simulation_seed = 39
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(runner.output))
	for index in 40:
		var file := FileAccess.open(runner.output.path_join("simulation-%d.json" % index), FileAccess.WRITE)
		file.store_string("{}")
		file.close()
	runner.prune_reports()
	check(DirAccess.get_files_at(runner.output).size() == 32,
		"Watch retention caps completed simulation files even without the Python launcher")
	check(FileAccess.file_exists(runner.output.path_join("simulation-39.json")), "Retention preserves the current report")
	runner.free()

func test_qa_upload() -> void:
	var config := preload("res://addons/godot_telemetry/resources/telemetry_config.gd").new()
	config.enabled = true
	config.transport = "http"
	config.endpoint = "http://invalid.test/v1/events"
	config.game_id = "echoes_of_the_rift"
	config.environment = "production"
	config.batch_size = 2
	config.retry_base_seconds = 0.01
	var old_consent := GameSettings.telemetry_enabled
	GameSettings.telemetry_enabled = true
	var path := "res://qa/qa-upload-test.jsonl"
	TelemetryManager.configure_qa(path, config)
	var upload: Node = TelemetryManager.qa_upload
	upload.set_process(false)
	check(upload.config.endpoint == config.endpoint and config.environment == "production", "QA preserves configured endpoint without mutating the original resource")
	check(upload.config.environment == "qa" and upload.config.profile == "qa", "QA enables bot diagnostics in the QA environment")
	upload.transport.queue_free()
	var fake := FakeUpload.new()
	upload.add_child(fake)
	upload.transport = fake
	TelemetryManager.set_context({"run_id": "upload-test"})
	TelemetryManager.track_event("stat_changed", {"stat": "test", "change": 1})
	TelemetryManager.track_event("stat_changed", {"stat": "test", "change": 2})
	check(await TelemetryManager.flush_pending(1.0), "Shutdown drain delivers every queued batch asynchronously")
	check(fake.batches.size() == 2 and upload.diagnostics.delivered == 3, "HTTP upload acknowledges more than one batch")
	var event: Dictionary = fake.batches[0][1]
	check(event.source_type == "bot" and event.environment == "qa" and event.run_id == "upload-test", "Backend events carry bot source, QA environment and current run")
	check(event.session_id == TelemetryManager.client.session_id, "Local and uploaded events share session context")
	fake.result = {"ok": false, "retryable": true, "error": "offline"}
	TelemetryManager.track_event("stat_changed", {"stat": "test", "change": 3})
	TelemetryManager.flush()
	await until(func(): return not upload.busy)
	check(upload.queue.size() == 1 and upload.retries == 1, "Backend outage retains pending events for retry")
	check(TelemetryManager.client.queue.is_empty() and FileAccess.file_exists(path), "Local JSONL completes independently of failed uploads")
	var retry_id: String = upload.queue[0].event_id
	fake.result = {"ok": true}
	upload.retry_at = 0.0
	check(await TelemetryManager.flush_pending(1.0), "Backend recovery drains pending telemetry")
	check(fake.batches.back()[0].event_id == retry_id, "Upload retry preserves its event ID")
	var file := FileAccess.open(path, FileAccess.READ)
	var local_count := 0
	while file and not file.eof_reached():
		if not file.get_line().is_empty():
			local_count += 1
	check(local_count == 4, "Backend retry does not duplicate local QA events")
	if file:
		file.close()
	upload.config.queue_capacity = 1
	TelemetryManager.track_event("stat_changed", {"stat": "test", "change": 4})
	TelemetryManager.track_event("stat_changed", {"stat": "test", "change": 5})
	TelemetryManager.client.flush()
	check(upload.queue.size() == 1 and upload.diagnostics.dropped == 1, "Upload queue remains bounded during backpressure")
	check(TelemetryManager.client.queue.is_empty(), "Remote queue pressure does not block the independent local client")
	GameSettings.telemetry_changed.emit(false)
	TelemetryManager.track_event("stat_changed", {"stat": "test", "change": 4})
	check(upload.queue.is_empty(), "Remote upload honors consent withdrawal")
	config.enabled = false
	TelemetryManager.configure_qa(path, config)
	check(not is_instance_valid(TelemetryManager.qa_upload), "Disabled backend keeps QA telemetry local")
	check(FileAccess.get_file_as_string(path).is_empty(), "New QA session truncates previous JSONL samples")
	var run_id := TelemetryManager.begin_qa_simulation()
	TelemetryManager.track_event("run_started", {"player_class": "Riftwalker"})
	TelemetryManager.track_event("encounter_started", {"encounter": "test", "width": 10, "height": 10})
	check(TelemetryManager.client.queue.back().run_id == run_id,
		"Run start and encounter startup keep the preassigned simulation identity")
	var next_run := TelemetryManager.begin_qa_simulation()
	check(next_run != run_id and TelemetryManager.client.queue.back().run_id == run_id,
		"Repeated seeds get unique identities without changing queued envelopes")
	TelemetryManager.track_event("player_turn_started", {"turn_number": 1, "player_class": "Riftwalker", "energy": 3, "health": 20})
	TelemetryManager.track_event("player_turn_started", {"turn_number": 1, "player_class": "Riftwalker", "energy": 3, "health": 20})
	check(TelemetryManager.qa_turns == 2, "QA counts turns across battle-local counter resets")
	GameSettings.telemetry_enabled = old_consent
	GameSettings.telemetry_changed.emit(old_consent)
