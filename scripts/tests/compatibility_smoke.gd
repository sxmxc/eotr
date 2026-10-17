extends Node

var failures := 0
var resource_count := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	print("Talo test configuration: %s, offline=%s, socket=%s" % [TaloSettings.settings_path, Talo.settings.offline_mode, Talo.settings.auto_connect_socket])
	_check(Engine.get_version_info().string.begins_with("4.7.2"), "Godot 4.7.2 is required")
	_check(Talo.settings.offline_mode and not Talo.settings.auto_connect_socket, "Run with the offline Talo test configuration")
	if failures:
		get_tree().quit(1)
		return
	for directory: String in ["res://scripts", "res://scenes", "res://resources", "res://ui"]:
		_scan_resources(directory)
	print("Loaded %d first-party resources" % resource_count)
	GameSettings.show_tutorial = false
	GameSettings.telemetry_enabled = false
	TelemetryManager.track_event("compatibility_test", {"amount": 3, "duration": 1.25})
	TelemetryManager.track_stat("compatibility_test")
	_check(Talo.events.get_queue_size() == 0, "Unidentified/disabled telemetry must be skipped")
	_test_talo_event_contract()
	var menu: Control = load("res://scenes/menus/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	menu.queue_free()
	await get_tree().process_frame
	var sandbox: GameWorldSandbox = load("res://scenes/sandbox/gameworld_sandbox.tscn").instantiate()
	var previous_offline := Talo.settings.offline_mode
	get_tree().root.add_child(sandbox)
	await get_tree().create_timer(2.0).timeout
	_check(sandbox.player_stats != null, "Sandbox initializes player stats")
	_check(sandbox.tilemap.tile_map_data.size() > 0, "Sandbox generates a board")
	_check(TelemetryManager.suspended, "Sandbox suspends telemetry")
	sandbox.queue_free()
	await get_tree().process_frame
	_check(Talo.settings.offline_mode == previous_offline, "Sandbox restores offline mode")
	_check(not TelemetryManager.suspended, "Sandbox restores telemetry")
	var run_scene: Run = load("res://scenes/run/run.scn").instantiate()
	run_scene.run_bootstrap = RunBootstrap.new()
	run_scene.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
	run_scene.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
	get_tree().root.add_child(run_scene)
	await get_tree().create_timer(1.0).timeout
	_check(run_scene.player_stats != null and run_scene.run_stats != null, "New run initializes")
	_check(SaveGame.load_data() != null, "New run can save and load")
	var encounter := MapNode.new()
	encounter.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
	run_scene._on_game_world_entered(encounter)
	await get_tree().create_timer(1.5).timeout
	var world := run_scene.current_view.get_child(0) as GameWorld
	_check(world != null and world.player.stats != null, "Run enters combat")
	run_scene.queue_free()
	await get_tree().process_frame
	print("Compatibility smoke test: %d failures" % failures)
	get_tree().quit(1 if failures else 0)


func _test_talo_event_contract() -> void:
	var alias := TaloPlayerAlias.new({
		"id": 1, "service": "test", "identifier": "offline_test", "displayName": "Test",
		"lastSeenAt": "", "createdAt": "", "updatedAt": "",
		"player": {"id": "offline_test", "props": [], "groups": []},
	})
	Talo.current_alias = alias
	GameSettings.telemetry_enabled = true
	TelemetryManager.track_event("compatibility_test", {"amount": 3, "duration": 1.25})
	_check(Talo.events.get_queue_size() == 1, "Numeric event properties pass Talo's typed API")
	var identity_label: Label = load("res://scenes/menus/player_identity.gd").new()
	add_child(identity_label)
	_check(identity_label.text == "offline_test", "Identity label shows an existing alias")
	Talo.players.identified.emit(alias)
	_check(identity_label.text == "offline_test", "Identity signal accepts a TaloPlayerAlias")
	GameSettings.telemetry_enabled = false
	GameSettings.telemetry_changed.emit(false)
	_check(not Talo.has_identity() and Talo.events.get_queue_size() == 0, "Opt-out clears identity and pending events")
	_check(identity_label.text.is_empty(), "Opt-out clears the identity label")
	identity_label.queue_free()


func _scan_resources(directory: String) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.get_extension() not in ["gd", "tscn", "scn", "tres", "gdshader"]:
			continue
		var path := directory.path_join(file_name)
		_check(load(path) != null, "Load %s" % path)
		resource_count += 1
	for subdirectory: String in DirAccess.get_directories_at(directory):
		_scan_resources(directory.path_join(subdirectory))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
