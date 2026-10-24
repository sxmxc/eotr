extends "res://scripts/tests/compatibility_smoke.gd"

func _run() -> void:
	_check(Engine.get_version_info().string.begins_with("4.7.2"), "Godot 4.7.2 is required")
	_check(TelemetryManager.client.config.transport == "null", "Settings QA uses offline telemetry")
	await _settings_checks()
	await _pause_checks()
	await _rail_checks()
	await _message_feed_checks()
	print("Settings and rail tests: %d failures" % failures)
	await Utils.stop_audio_for_shutdown()
	get_tree().quit(1 if failures else 0)

func _settings_checks() -> void:
	var original := GameSettings.get_current_settings()
	var config := ConfigFile.new()
	config.set_value("graphics", "resolution", 99)
	config.set_value("audio", "master_volume", -2.0)
	config.set_value("audio", "sfx_volume", "invalid")
	config.set_value("graphics", "fullscreen", "invalid")
	config.save(GameSettings.SETTINGS_PATH)
	var sanitized := GameSettings.get_current_settings()
	_check(sanitized.resolution == 0 and sanitized.master_volume == 0.0 and sanitized.sfx_volume == 1.0 and sanitized.fullscreen, "Partial/invalid settings keep valid defaults and clamp volumes")
	_check(GameSettings.save_settings(original), "Restore settings fixture")
	var menu := load("res://scenes/menus/settings_menu.tscn").instantiate() as Control
	menu.embedded = true
	add_child(menu)
	await _settle_ui()
	_check(menu.save_button.disabled and menu.resolution_button.item_count == 4, "Unchanged settings disable Apply; all window sizes are populated")
	menu.fullscreen_button.button_pressed = false
	menu.resolution_button.select(2)
	menu.resolution_button.item_selected.emit(2)
	menu.get_node("%MusicVolumeSlider").value = 0.37
	menu.get_node("%UIVolumeSlider").value = 0.42
	menu.get_node("%VSyncButton").button_pressed = false
	menu.telemetry_check_box.button_pressed = true
	menu.tutorial_checkbox.button_pressed = false
	_check(not menu.save_button.disabled and not menu.resolution_button.disabled, "Window and audio edits enable Apply")
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")), 0.37 * GameSettings.music_base_volume), "Music preview scales the authored mix")
	_check(not GameSettings.telemetry_enabled, "Telemetry preview does not grant consent before Apply")
	await _capture("settings-edited")
	if DisplayServer.get_name() != "headless":
		var window_size := DisplayServer.window_get_size()
		var window_position := DisplayServer.window_get_position()
		var vsync := DisplayServer.window_get_vsync_mode()
		GameSettings.apply_display(menu._read_controls())
		DisplayServer.window_set_position(Vector2i(-32000, -32000))
		await _settle_ui()
		_check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_size() == Vector2i(1280, 720), "Native display applies the selected window size")
		_check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "Native display applies VSync preference")
		await _capture("settings-720p")
		DisplayServer.window_set_size(Vector2i(1100, 650))
		GameSettings.apply_display(menu._read_controls())
		_check(DisplayServer.window_get_size() == Vector2i(1100, 650), "Unchanged display preferences preserve a manually resized window")
		DisplayServer.window_set_size(window_size)
		DisplayServer.window_set_position(window_position)
		DisplayServer.window_set_vsync_mode(vsync)
	menu.save_button.pressed.emit()
	await get_tree().process_frame
	var saved := GameSettings.get_current_settings()
	_check(saved.resolution == 2 and not saved.fullscreen and not saved.vsync_enabled and is_equal_approx(saved.music_volume, 0.37) and is_equal_approx(saved.ui_volume, 0.42) and not saved.tutorial_enabled and saved.telemetry_enabled, "Apply persists all new and existing fields")
	menu = load("res://scenes/menus/settings_menu.tscn").instantiate()
	menu.embedded = true
	add_child(menu)
	menu.master_volume_slider.value = 0.0
	menu.get_node("%MusicVolumeSlider").value = 0.0
	menu.cancel_button.pressed.emit()
	await get_tree().process_frame
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master")), saved.master_volume), "Cancel restores previewed Master volume")
	_check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")), saved.music_volume * GameSettings.music_base_volume), "Cancel restores previewed Music volume")
	menu = load("res://scenes/menus/settings_menu.tscn").instantiate()
	menu.embedded = true
	add_child(menu)
	menu.get_node("%DefaultsButton").pressed.emit()
	_check(not menu.save_button.disabled and menu.fullscreen_button.button_pressed and menu.get_node("%MusicVolumeSlider").value == 1.0 and not menu.telemetry_check_box.button_pressed, "Defaults stage changes and preserve opt-in privacy")
	DirAccess.remove_absolute(GameSettings.SETTINGS_PATH)
	DirAccess.make_dir_absolute(GameSettings.SETTINGS_PATH)
	menu.save_button.pressed.emit()
	_check(not menu.is_queued_for_deletion() and menu.get_node("%SaveError").visible, "Failed save keeps settings open with a visible recovery message")
	DirAccess.remove_absolute(GameSettings.SETTINGS_PATH)
	menu.cancel_button.pressed.emit()
	await get_tree().process_frame
	_check(GameSettings.save_settings(original), "Restore initial settings after checks")

func _pause_checks() -> void:
	var pause := load("res://scenes/run/pause_menu.tscn").instantiate() as PauseMenu
	add_child(pause)
	pause._pause()
	pause.save_and_quit_button.pressed.emit()
	var ui_click_found := false
	for child: Node in SoundManager.ui_sound_effects.get_children():
		var player := child as AudioStreamPlayer
		if player and player.stream == AudioLibrary.ui_click and player.bus == &"UI":
			ui_click_found = true
	_check(ui_click_found, "Pause menu clicks use the UI bus controlled by Interface sounds")
	pause.get_node("%SettingsButton").pressed.emit()
	await _settle_ui()
	_check(get_tree().paused and is_instance_valid(pause.settings_menu), "Settings opens inside pause without replacing the run")
	pause.settings_menu.master_volume_slider.value = 0.23
	await _capture("settings-paused")
	await _press_escape()
	await _settle_ui()
	_check(get_tree().paused and not is_instance_valid(pause.settings_menu) and pause.get_node("%SettingsButton").has_focus(), "Escape cancels settings and returns focus to the paused menu")
	pause._unpause()
	_check(not get_tree().paused, "Resume still releases pause after settings")
	pause.queue_free()
	await get_tree().process_frame

func _rail_checks() -> void:
	GameSettings.show_tutorial = false
	RNG.instance.seed = 472001
	var relics := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(relics)
	var world := load("res://scenes/game_world/game_world.tscn").instantiate() as GameWorld
	add_child(world)
	world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
	world.run_stats = RunStats.new()
	world.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
	world.relics = relics
	world.start_world()
	await get_tree().create_timer(0.7).timeout
	var hidden_count := 0
	for enemy: Enemy in world.enemy_handler.get_children():
		if world.tilemap.is_tile_behind_fog(enemy.current_tile_position):
			hidden_count += 1
			var row := enemy.queue_button
			_check(row.visible and row.disabled and row.get_node("%EnemyName").text == "Unknown enemy", "Fogged enemy has an anonymous disabled row")
			_check(not row.get_node("%HealthRow").visible and row.get_node("%HealthValue").text.is_empty() and row.get_node("%IntentIcon").texture == null, "Unknown rows clear health, block and intent information")
			row._select()
			row._hover(true)
			_check(not enemy.stats_ui.visible and not enemy.queue_hovered, "Unknown row cannot inspect or highlight a hidden enemy")
	_check(hidden_count > 0, "Seed exercises fog placeholders")
	await _capture("rail-fog")
	world.tilemap.hide_fog()
	await _settle_ui()
	for enemy: Enemy in world.enemy_handler.get_children():
		var row := enemy.queue_button
		_check(not row.disabled and row.get_node("%HealthBar").value == enemy.stats.health, "Revealing fog binds live enemy health")
	var actor := world.enemy_handler.get_child(1) as Enemy
	actor.stats.health = maxi(1, actor.stats.max_health / 2)
	actor.stats.block = 7
	var entry := actor.queue_button
	_check(entry.get_node("%HealthBar").value == actor.stats.health and entry.get_node("%Block").text == "7 block", "Damage and block refresh separate fields immediately")
	entry.pressed.emit()
	_check(actor.stats_ui.inspection_pinned, "Revealed row retains selection and full inspection")
	await _capture("rail-inspected")
	actor.stats_ui.close_inspection()
	await _capture("rail-revealed")
	# Real catalog resource and action; position is a controlled fixture to expose Strike.
	actor.stats = load("res://resources/data/enemies/rift/hollow_siphon.tres")
	await _settle_ui()
	var cells := world.tilemap.get_surrounding_tiles_in_radius(actor.get_player_tile_position(), 2)
	for cell: Vector2i in cells:
		if world.tilemap.is_tile_free(cell):
			actor.current_tile_position = cell
			break
	actor.update_action()
	actor.update_intent()
	await _settle_ui()
	_check(entry.get_node("%Plan").text.contains("Attack") and entry.get_node("%Plan").text.contains("Range 2") and entry.get_node("%Plan").text.contains("Heals"), "Hollow Siphon summary retains damage, hits, range and healing cue")
	await _capture("rail-siphon")
	var plan := entry.get_node("%Plan") as Label
	_check(plan.global_position.y + plan.size.y <= entry.global_position.y + entry.size.y - 6.0, "Two-line intent fits inside its row with bottom padding")
	world.tilemap.fog_state.erase(actor.current_tile_position)
	world.tilemap.presentation_changed.emit()
	_check(entry.disabled and entry.get_node("%EnemyName").text == "Unknown enemy" and entry.get_node("%HealthValue").text.is_empty(), "Returning fog clears previously revealed information")
	actor.is_dying = true
	entry.refresh()
	_check(not entry.visible, "Dying hidden enemies do not leave placeholders")
	world.queue_free()
	relics.queue_free()
	await get_tree().process_frame

func _message_feed_checks() -> void:
	var feed := preload("res://ui/world_ui/world_message_container.tscn").instantiate() as WorldMessageContainer
	add_child(feed)
	feed.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	feed.size = Vector2(260, 240)
	# A burst evicts rows before their deferred scrolling callbacks run.
	for index in 6:
		feed.show_message(WorldMessageData.new("Outcome %d: " % index + "received 4 damage. ".repeat(8), WorldMessageData.Priority.IMPORTANT))
	await _settle_ui()
	var rows := feed.get_node("LiveScroll/LiveRows") as VBoxContainer
	_check(rows.get_child_count() == 4 and feed.history.size() == 6, "Message bursts keep four live outcomes and all history")
	var latest := rows.get_child(-1) as WorldMessage
	_check(latest.message_text_label.text.begins_with("Outcome 5:"), "Message burst retains the newest outcome")
	var scroll := feed.get_node("LiveScroll") as ScrollContainer
	_check(scroll.scroll_vertical > 0, "Message burst scrolls to the surviving newest outcome")
	# The list may also be emptied before deferred presentation work executes.
	feed.show_message(WorldMessageData.new("Final outcome", WorldMessageData.Priority.CRITICAL))
	for row in rows.get_children():
		rows.remove_child(row)
		row.queue_free()
	await _settle_ui()
	_check(rows.get_child_count() == 0 and feed.history.size() == 7, "Emptying live rows before scrolling preserves history")
	feed.queue_free()
	await get_tree().process_frame

func _capture(screen: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-ui"):
		return
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	if get_viewport().use_hdr_2d and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		for y: int in frame.get_height():
			for x: int in frame.get_width():
				frame.set_pixel(x, y, frame.get_pixel(x, y).linear_to_srgb())
		frame.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute("res://.qa-tmp/settings-rail")
	frame.save_png("res://.qa-tmp/settings-rail/verified-%s.png" % screen)
