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
	RNG.instance.seed = 472001
	for directory: String in ["res://scripts", "res://scenes", "res://resources", "res://ui"]:
		_scan_resources(directory)
	print("Loaded %d first-party resources" % resource_count)
	_test_ambient_particles()
	await _test_battle_presentation()
	GameSettings.show_tutorial = false
	GameSettings.telemetry_enabled = false
	TelemetryManager.track_event("compatibility_test", {"amount": 3, "duration": 1.25})
	TelemetryManager.track_stat("compatibility_test")
	_check(Talo.events.get_queue_size() == 0, "Unidentified/disabled telemetry must be skipped")
	_test_talo_event_contract()
	var menu: Control = load("res://scenes/menus/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--capture-ui"):
		await get_tree().create_timer(1.1).timeout
	await _capture("menu")
	menu.queue_free()
	await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--capture-ui"):
		for screen: String in ["class_selector", "settings_menu"]:
			var supporting: Control = load("res://scenes/menus/%s.tscn" % screen).instantiate()
			get_tree().root.add_child(supporting)
			await get_tree().create_timer(0.4).timeout
			await _capture(screen)
			supporting.queue_free()
			await get_tree().process_frame
	var data_editor: DataEditor = load("res://scenes/devtools/data_editor.tscn").instantiate()
	get_tree().root.add_child(data_editor)
	await get_tree().process_frame
	_check(data_editor.card_type.item_count == Enums.CardType.size(), "Data editor populates card types")
	_check(data_editor.card_target.item_count == Enums.TargetType.size(), "Data editor populates card targets")
	_check(data_editor.card_rarity.item_count == Enums.CardRarity.size(), "Data editor populates card rarities")
	_check(data_editor.registry_rarity.item_count == Enums.CardRarity.size() + 1, "Data editor populates registry rarities")
	_check(data_editor.card_rarity_filter.item_count == Enums.CardRarity.size() + 1, "Data editor populates rarity filter")
	_check(not data_editor.card_records.is_empty(), "Data editor reaches resource list initialization")
	data_editor.queue_free()
	await get_tree().process_frame
	var sandbox: GameWorldSandbox = load("res://scenes/sandbox/gameworld_sandbox.tscn").instantiate()
	var previous_offline := Talo.settings.offline_mode
	get_tree().root.add_child(sandbox)
	await get_tree().create_timer(2.0).timeout
	_check(sandbox.player_stats != null, "Sandbox initializes player stats")
	_check(sandbox.tilemap.tile_map_data.size() > 0, "Sandbox generates a board")
	_check(TelemetryManager.suspended, "Sandbox suspends telemetry")
	await _test_overhaul_lifetimes(sandbox)
	sandbox.queue_free()
	await get_tree().process_frame
	_check(Talo.settings.offline_mode == previous_offline, "Sandbox restores offline mode")
	_check(not TelemetryManager.suspended, "Sandbox restores telemetry")
	var run_scene: Run = load("res://scenes/run/run.tscn").instantiate()
	run_scene.run_bootstrap = RunBootstrap.new()
	run_scene.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
	run_scene.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
	get_tree().root.add_child(run_scene)
	await get_tree().create_timer(1.0).timeout
	_check(run_scene.player_stats != null and run_scene.run_stats != null, "New run initializes")
	_check(SaveGame.load_data() != null, "New run can save and load")
	_test_save_overwrite(run_scene)
	await _capture("map")
	if OS.get_cmdline_user_args().has("--capture-ui"):
		var legend := run_scene.map_legend.get_node("MapLegend")
		legend.toggle.button_pressed = true
		await _capture("legend")
		legend.toggle.button_pressed = false
		run_scene.relic_tooltip.show_tooltip(run_scene.player_stats.starting_relic)
		await _capture("relic")
		run_scene.relic_tooltip.hide()
		run_scene._on_bounty_board_button_pressed()
		await _capture("bounties")
		run_scene.bounty_board_popup.hide()
	var encounter := MapNode.new()
	encounter.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
	run_scene._on_game_world_entered(encounter)
	await get_tree().create_timer(1.5).timeout
	var world := run_scene.current_view.get_child(0) as GameWorld
	_check(world != null and world.player.stats != null, "Run enters combat")
	await _test_card_interaction(world)
	if OS.get_cmdline_user_args().has("--capture-ui"):
		run_scene.map_legend.hide()
		await _capture("fog")
		world.tilemap.hide_fog()
		Events.rounds_until_shrink_updated.emit(1)
		await get_tree().create_timer(0.5).timeout
		await _capture("combat")
		await _capture_aim_and_inspection(world)
		var first_card := world.game_world_ui.hand.get_child(0) as CardUI
		first_card._on_mouse_entered()
		await get_tree().create_timer(0.16).timeout
		await _capture("hover")
		first_card._on_mouse_exited()
		for i in range(6):
			world.game_world_ui.hand.add_card(first_card.card.duplicate())
		world.player_stats.energy = 0
		await get_tree().create_timer(0.25).timeout
		await _capture("full-hand")
		world._handle_battle_over("Victory", BattleOverPanel.Type.WIN)
		await get_tree().create_timer(0.9, true).timeout
		await _capture("victory")
		get_tree().paused = false
		run_scene.map.last_map_node = encounter
		run_scene._show_regular_rewards()
		await get_tree().create_timer(0.25).timeout
		await _capture("rewards")
	run_scene.queue_free()
	await get_tree().process_frame
	print("Compatibility smoke test: %d failures" % failures)
	get_tree().quit(1 if failures else 0)


func _test_save_overwrite(run_scene: Run) -> void:
	var first := SaveGame.load_data()
	var health := first.player_stats.max_health
	first.current_health = 17
	first.player_stats.max_health = 17
	first.last_map_node = first.map_data[0][0]
	_check(first.save_data(), "Save replacement succeeds")
	if OS.get_cmdline_user_args().has("--exercise-save-failure"):
		_test_save_failure(first)
	var second := SaveGame.load_data()
	_check(second.current_health == 17 and second.player_stats.max_health == 17, "Same-process reload reads overwritten nested state")
	first.player_stats.max_health = 3
	_check(second.player_stats.max_health == 17, "Loaded resource graphs are independent")
	_check(second.last_map_node == second.map_data[0][0], "Save graph preserves shared map-node references")
	first.player_stats.max_health = health
	_check(run_scene.save_data.save_data(), "Restore original test run save")


func _test_overhaul_lifetimes(sandbox: GameWorldSandbox) -> void:
	var clock: RunTimerUI = load("res://ui/run_ui/run_time_ui.tscn").instantiate()
	add_child(clock)
	clock.start()
	OS.delay_msec(125)
	_check(clock.elapsed_time >= 0.12, "Clock counts delayed frames without timer callbacks")
	get_tree().paused = true
	var paused_time := clock.elapsed_time
	OS.delay_msec(100)
	_check(absf(clock.elapsed_time - paused_time) < 0.01, "Clock excludes pause")
	get_tree().paused = false
	Engine.time_scale = 0.1
	OS.delay_msec(100)
	_check(clock.elapsed_time >= paused_time + 0.09, "Clock includes hit-stop at real elapsed duration")
	Engine.time_scale = 1.0
	clock.stop()
	clock.resume_from(123.0)
	_check(clock.get_pretty_time() == "00:02:03", "Clock resumes saved active time")
	clock.queue_free()
	var parent := Node2D.new()
	parent.rotation = 0.7
	parent.scale = Vector2(2.0, 1.5)
	add_child(parent)
	var target := Node2D.new()
	target.position = Vector2(40, 30)
	parent.add_child(target)
	Utils.shake(target, 10.0, 0.1)
	Utils.shake(target, 6.0, 0.1)
	await get_tree().create_timer(0.15).timeout
	_check(target.position.is_equal_approx(Vector2(40, 30)), "Overlapping shakes restore local origin under a transformed parent")
	Utils.shake(target, 5.0)
	parent.queue_free()
	var handler := sandbox.enemy_handler
	var battle: BattleStats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres")
	handler.setup_enemies(battle)
	await get_tree().create_timer(0.05).timeout
	var enemy := handler.get_child(0) as Enemy
	var entry := enemy.queue_button
	entry.bind_enemy(enemy)
	entry.bind_enemy(enemy)
	_check(enemy.queue_button == entry, "Queue supports repeated explicit binding")
	var stats := enemy.stats
	entry.queue_free()
	await get_tree().process_frame
	stats.block += 1
	_check(enemy.queue_button == null, "Freed queue entry releases enemy reference")
	handler.setup_enemies(battle)
	await get_tree().create_timer(0.05).timeout
	var template := battle.enemies.instantiate()
	_check(handler.get_child_count() == template.get_child_count(), "Repeated encounter setup replaces enemies")
	template.free()


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


func _test_ambient_particles() -> void:
	var texture := load("res://resources/vfx/menu_emission_points.res") as ImageTexture
	_check(texture != null, "Load binary emission texture")
	var image := texture.get_image()
	_check(image.get_size() == Vector2i(2048, 81) and image.get_format() == Image.FORMAT_RGF, "Preserve floating point emission coordinates")
	var cases := {
		"menus/main_menu": [1, 1587.0, 272.0],
		"map/map": [-1, 1598.0, 170.0],
		"rest/rest": [1, 1587.0, 272.0],
		"shop/shop": [1, 1598.0, 170.0],
		"treasure/treasure": [2, 1587.0, 272.0],
		"battle_rewards/battle_rewards": [2, 1587.0, 272.0],
		"win_screen/win_screen": [11, 1587.0, 272.0],
	}
	for path: String in cases:
		var scene: Node = load("res://scenes/%s.tscn" % path).instantiate()
		var particles: CanvasLayer = scene.get_node("ParticlesLayer")
		_check(particles.layer == cases[path][0], "Preserve particle layer: %s" % path)
		_check(particles.get_child_count() == 6, "Preserve six particle emitters: %s" % path)
		_check(particles.get_node("GPUParticles2D3").position.x == cases[path][1], "Preserve right emitter position: %s" % path)
		_check(particles.get_node("GPUParticles2D5").position.x == cases[path][2], "Preserve left emitter position: %s" % path)
		for emitter: GPUParticles2D in particles.get_children():
			_check(emitter.process_material.emission_point_texture == texture, "Share emission texture: %s" % path)
		scene.free()


func _test_battle_presentation() -> void:
	var packed: PackedScene = load("res://ui/world_ui/battle_presentation.tscn")
	var first: BattlePresentation = packed.instantiate()
	var second: BattlePresentation = packed.instantiate()
	add_child(first)
	add_child(second)
	var first_rect: ColorRect = first.get_node("BattleVignette")
	var second_rect: ColorRect = second.get_node("BattleVignette")
	_check(first_rect.material != second_rect.material, "Battle overlays own separate shader parameters")
	first.play_intro()
	_check(first.visible and first.get_node("BattleVignette/BeatLabel").text == first.intro_text, "Battle intro displays")
	await get_tree().create_timer(0.5).timeout
	_check(not first.visible, "Battle intro hides after animation")
	first.play_outro(true)
	_check(first.get_node("BattleVignette/BeatLabel").text == first.win_text, "Battle victory displays")
	_check(second_rect.material.get_shader_parameter("effect_color") == Color(0.05, 0.05, 0.08, 0.65), "Victory tint does not affect another overlay")
	first.queue_free()
	second.queue_free()
	await get_tree().process_frame


func _scan_resources(directory: String) -> void:
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.get_extension() not in ["gd", "tscn", "scn", "tres", "res", "gdshader"]:
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


func _capture(screen: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture-ui"):
		return
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	if get_viewport().use_hdr_2d and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		# Encode linear HDR values before reducing to 8 bits, avoiding crushed shadows.
		for y in frame.get_height():
			for x in frame.get_width():
				frame.set_pixel(x, y, frame.get_pixel(x, y).linear_to_srgb())
		frame.convert(Image.FORMAT_RGBA8)
	frame.save_png("res://overhaul-%s.png" % screen)


func _test_save_failure(data: SaveGame) -> void:
	# Deliberately exercise real I/O failure only in the isolated validation project.
	if ProjectSettings.get_setting("application/config/name") != "eotr_compatibility_validation":
		return
	var previous := FileAccess.get_sha256(SaveGame.SAVE_PATH)
	const PENDING := "user://savegame.pending.res"
	_check(DirAccess.make_dir_absolute(PENDING) == OK, "Create isolated write-failure fixture")
	_check(not data.save_data(), "Write failure is recoverable")
	_check(FileAccess.get_sha256(SaveGame.SAVE_PATH) == previous, "Failed write preserves previous save bytes")
	var dialog := Utils.get_node_or_null("SaveError") as AcceptDialog
	_check(dialog != null and dialog.visible, "Write failure is visible to the player")
	if dialog:
		dialog.hide()
	DirAccess.remove_absolute(PENDING)
	print("Expected save failure verified; original save retained.")


func _test_card_interaction(world: GameWorld) -> void:
	var card := world.game_world_ui.hand.get_child(0) as CardUI
	var inspected_enemy := world.enemy_handler.get_child(0) as Enemy
	Events.enemy_selected.emit(inspected_enemy)
	_check(inspected_enemy.stats_ui.inspection_pinned, "Enemy selection pins contextual stats")
	Events.enemy_info_hide_requested.emit()
	_check(not inspected_enemy.stats_ui.inspection_pinned, "Turn cleanup releases contextual inspection")
	card._on_mouse_entered()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	card._on_gui_input(press)
	_check(card.card_state_machine.current_state.state == CardState.State.CLICKED, "Card press selects")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	card._input(release)
	_check(card.card_state_machine.current_state.state == CardState.State.BASE, "Release without drag returns to hand")
	await get_tree().create_timer(0.02).timeout
	card._on_mouse_entered()
	card._on_gui_input(press)
	card._input(InputEventMouseMotion.new())
	_check(card.card_state_machine.current_state.state == CardState.State.DRAGGING, "Mouse motion starts card drag")
	var cancel := InputEventMouseButton.new()
	cancel.button_index = MOUSE_BUTTON_RIGHT
	cancel.pressed = true
	card._input(cancel)
	_check(card.get_parent() == world.game_world_ui.hand and card.card_state_machine.current_state.state == CardState.State.BASE, "Right click cancels drag and restores hand")
	card._on_mouse_exited()
	await get_tree().create_timer(0.2).timeout
	var hidden_cells: Array[Vector2i] = []
	for enemy: Enemy in world.enemy_handler.get_children():
		if world.tilemap.is_tile_behind_fog(enemy.current_tile_position):
			hidden_cells.append(enemy.current_tile_position)
			_check(not enemy.queue_button.visible, "Queue does not expose enemies through fog")
	world.tilemap.show_target_highlights(hidden_cells)
	_check(world.tilemap.target_highlight_layer.active_target_highlights.is_empty(), "Target overlay does not expose hidden hexes")
	world.tilemap.clear_target_highlights()


func _capture_aim_and_inspection(world: GameWorld) -> void:
	var card: CardUI
	for candidate: CardUI in world.game_world_ui.hand.get_children():
		if candidate.card.id == "arcane_bolt":
			card = candidate
			break
	if card:
		var machine := card.card_state_machine
		machine._on_transition_requested(machine.current_state, CardState.State.DRAGGING)
		machine._on_transition_requested(machine.current_state, CardState.State.AIMING)
		var targets := card.card.get_valid_targets(card, card.player_modifiers)
		if not targets.is_empty():
			var screen_point := world.tilemap.base_layer.get_global_transform_with_canvas() * world.tilemap.base_layer.map_to_local(targets[0])
			get_viewport().warp_mouse(screen_point)
			var motion := InputEventMouseMotion.new()
			motion.position = screen_point
			motion.global_position = screen_point
			get_viewport().push_input(motion, true)
		await get_tree().create_timer(0.25).timeout
		_check(card.global_position.y >= get_viewport().get_visible_rect().size.y - 300.0, "Aiming card stays in hand zone")
		var selector := get_tree().get_first_node_in_group("target_selector") as TargetSelector
		_check(selector.targeting and selector.card_arc.get_point_count() > 1, "Aiming draws the targeting arc")
		_check(not world.tilemap.get_node("CardTargetHighlights").active_target_highlights.is_empty(), "Aiming displays legal target outlines")
		await _capture("aim")
		var cancel := InputEventMouseButton.new()
		cancel.button_index = MOUSE_BUTTON_RIGHT
		cancel.pressed = true
		card._input(cancel)
		await get_tree().create_timer(0.25).timeout
	var enemy := world.enemy_handler.get_child(0) as Enemy
	Events.enemy_selected.emit(enemy)
	await _capture("enemy-inspect")
	_check(enemy.stats_ui.get_parent() == world.game_world_ui, "Enemy inspection belongs to screen-space HUD")
	Events.enemy_info_hide_requested.emit()
