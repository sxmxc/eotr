extends Node

var failures := 0
var resource_count := 0

class ConsentSplash extends "res://scenes/splash_screens/splash_screen.gd":
	var continuations := 0
	func _continue_to_menu() -> void:
		continuations += 1


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(Engine.get_version_info().string.begins_with("4.7.2"), "Godot 4.7.2 is required")
	_check(TelemetryManager.client.config.transport == "null", "Validation must use backend-free Null telemetry")
	if failures:
		get_tree().quit(1)
		return
	RNG.instance.seed = 472001
	if OS.get_cmdline_user_args().has("--ui-layout-only"):
		await _test_ui_composition()
		print("Compatibility smoke test: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--presentation-review"):
		await _review_presentation()
		print("Compatibility smoke test: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--map-only"):
		GameSettings.show_tutorial = false
		var run_scene: Run = load("res://scenes/run/run.tscn").instantiate()
		run_scene.run_bootstrap = RunBootstrap.new()
		run_scene.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
		run_scene.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
		get_tree().root.add_child(run_scene)
		await get_tree().create_timer(1.0).timeout
		await _test_route_and_icon_feedback(run_scene)
		for route: Line2D in run_scene.map.lines.get_children():
			var origin: MapNode = route.get_meta("from_node")
			var destination: MapNode = route.get_meta("to_node")
			var face := PackedVector2Array([Vector2(-16, -26), Vector2(-31, 0), Vector2(-16, 26), Vector2(16, 26), Vector2(31, 0), Vector2(16, -26)])
			_check(not Geometry2D.is_point_in_polygon(route.points[0] - origin.position, face), "Route stops outside source node")
			_check(not Geometry2D.is_point_in_polygon(route.points[1] - destination.position, face), "Route stops outside destination node")
		for entry: MapNodeUI in run_scene.map.map_nodes.get_children():
			_check(entry.get_node("Visuals/Face").color.a == 1.0, "Node face conceals underlying connections")
		var current: MapNode
		for entry: MapNodeUI in run_scene.map.map_nodes.get_children():
			if entry.available and current == null:
				current = entry.map_node
			entry.available = false
		current.selected = true
		run_scene.map.last_map_node = current
		run_scene.map.floors_climbed = 1
		run_scene.map.unlock_next_map_node()
		run_scene.map.center_camera_on_current_floor()
		await get_tree().create_timer(1.1).timeout
		await _capture("map")
		var legend := run_scene.map_legend.get_node("MapLegend")
		legend.toggle.button_pressed = true
		await _capture("legend")
		legend.toggle.button_pressed = false
		var rewards: BattleRewards = load("res://scenes/battle_rewards/battle_rewards.tscn").instantiate()
		run_scene.map.hide_map()
		run_scene.map_legend.hide()
		rewards.run_stats = run_scene.run_stats
		rewards.player_stats = run_scene.player_stats
		get_tree().root.add_child(rewards)
		rewards.add_resource_reward(3)
		await _settle_ui()
		_check(rewards.rewards.get_child(0).reward_icon == load("res://assets/rift/ui/resource.svg"), "Resource reward uses the same crystal as the HUD and shop")
		await _capture("resource-reward")
		rewards.queue_free()
		run_scene.queue_free()
		await get_tree().process_frame
		print("Compatibility smoke test: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--event-room-only"):
		await _test_telemetry_disclaimer()
		await _test_supporting_rooms()
		await _test_event_choices()
		print("Compatibility smoke test: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--ui-transactions-only"):
		GameSettings.show_tutorial = false
		GameSettings.telemetry_enabled = false
		var run_scene: Run = load("res://scenes/run/run.tscn").instantiate()
		run_scene.run_bootstrap = RunBootstrap.new()
		run_scene.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
		run_scene.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
		get_tree().root.add_child(run_scene)
		await _settle_ui()
		var encounter := MapNode.new()
		encounter.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
		await _test_reward_and_shop(run_scene, encounter)
		run_scene.queue_free()
		await get_tree().process_frame
		print("Compatibility smoke test: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	for directory: String in ["res://scripts", "res://scenes", "res://resources", "res://ui"]:
		_scan_resources(directory)
	print("Loaded %d first-party resources" % resource_count)
	_test_scene_ownership()
	_test_ambient_particles()
	await _test_battle_presentation()
	if DisplayServer.get_name() != "headless":
		await _test_shader_fades()
	if OS.get_cmdline_user_args().has("--vfx-only"):
		if DisplayServer.get_name() != "headless":
			await _test_lunge_presentation()
		print("Compatibility smoke test: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	GameSettings.show_tutorial = false
	GameSettings.telemetry_enabled = false
	TelemetryManager.track_event("compatibility_test", {"amount": 3, "duration": 1.25})
	TelemetryManager.track_stat("compatibility_test")
	GameSettings.telemetry_changed.emit(false)
	_check(TelemetryManager.client.queue.is_empty(), "Disabled telemetry clears pending events")
	_test_telemetry_event_contract()
	var menu: Control = load("res://scenes/menus/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--capture-ui"):
		await get_tree().create_timer(1.1).timeout
	await _capture("menu")
	menu.queue_free()
	await get_tree().process_frame
	await _test_ui_composition()
	if OS.get_cmdline_user_args().has("--capture-ui"):
		await _capture_production_deck()
	if OS.get_cmdline_user_args().has("--capture-ui"):
		for screen: String in ["class_selector", "settings_menu"]:
			var supporting: Control = load("res://scenes/menus/%s.tscn" % screen).instantiate()
			get_tree().root.add_child(supporting)
			await get_tree().create_timer(0.4).timeout
			await _capture(screen)
			if screen == "class_selector":
				supporting._on_synthforge_button_pressed()
				await get_tree().create_timer(0.3).timeout
				await _capture("class-synthforged")
				supporting._on_voidbinder_button_pressed()
				await get_tree().create_timer(0.3).timeout
				await _capture("class-voidbinder")
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
	var previous_suspended := TelemetryManager.suspended
	get_tree().root.add_child(sandbox)
	await get_tree().create_timer(2.0).timeout
	_check(sandbox.player_stats != null, "Sandbox initializes player stats")
	_check(sandbox.tilemap.tile_map_data.size() > 0, "Sandbox generates a board")
	_check(TelemetryManager.suspended, "Sandbox suspends telemetry")
	await _test_overhaul_lifetimes(sandbox)
	await _test_hand_cycle(sandbox)
	sandbox.queue_free()
	await get_tree().process_frame
	_check(TelemetryManager.suspended == previous_suspended, "Sandbox restores telemetry")
	var run_scene: Run = load("res://scenes/run/run.tscn").instantiate()
	run_scene.run_bootstrap = RunBootstrap.new()
	run_scene.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
	run_scene.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
	get_tree().root.add_child(run_scene)
	await get_tree().create_timer(1.0).timeout
	_check(run_scene.player_stats != null and run_scene.run_stats != null, "New run initializes")
	_check(SaveGame.load_data() != null, "New run can save and load")
	run_scene.pause_menu._pause()
	_check(get_tree().paused and run_scene.pause_menu.visible, "Extracted pause menu opens and pauses")
	run_scene.pause_menu._unpause()
	_check(not get_tree().paused and not run_scene.pause_menu.visible, "Extracted pause menu resumes")
	run_scene.tutorial_ui.display_tutorial()
	_check(get_tree().paused and run_scene.tutorial_ui.visible, "Extracted run tutorial opens")
	run_scene.tutorial_ui._on_button_pressed()
	_test_save_overwrite(run_scene)
	await _test_event_choices()
	await _test_route_and_icon_feedback(run_scene)
	await _capture("map")
	if OS.get_cmdline_user_args().has("--capture-ui"):
		var legend := run_scene.map_legend.get_node("MapLegend")
		legend.toggle.button_pressed = true
		await _capture("legend")
		legend.toggle.button_pressed = false
		var bounty: ThemedIconButton = run_scene.map_legend.get_node("BountyBoardButton")
		bounty._on_mouse_entered()
		await _capture("icon-hover")
		bounty._on_mouse_exited()
		run_scene.hud.relic_tooltip.show_tooltip(run_scene.player_stats.starting_relic)
		await _capture("relic")
		run_scene.hud.relic_tooltip.hide()
		run_scene._on_bounty_board_button_pressed()
		await _capture("bounties")
		run_scene.hud.bounty_board_popup.hide()
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
		# Production gate: actual CardUI instances in the actual battle hand.
		var art_hand: PlayerHand = world.game_world_ui.hand
		for old_card: Node in art_hand.get_children():
			art_hand.remove_child(old_card)
			old_card.queue_free()
		for art_id: String in ["arcane_bolt", "arcane_blast", "phase_step", "adrenaline_rush", "eldritch_barrier"]:
			art_hand.add_card(load("res://resources/data/cards/riftwalker/%s.tres" % art_id).duplicate())
		await get_tree().create_timer(0.3).timeout
		await _capture("card-art-gate")
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
	await _test_reward_and_shop(run_scene, encounter)
	run_scene.map.floors_climbed = MapGenerator.FLOORS
	run_scene.run_stats.act_index = run_scene.acts.size() - 1
	run_scene._on_battle_won()
	await _settle_ui()
	_check(run_scene.current_view.get_child_count() == 1 and run_scene.current_view.get_child(0) is WinScreen, "Final victory replaces the previous view completely")
	_check(not get_tree().paused, "Final victory leaves the run unpaused")
	run_scene.queue_free()
	await get_tree().process_frame
	print("Compatibility smoke test: %d failures" % failures)
	await Utils.stop_audio_for_shutdown()
	get_tree().quit(1 if failures else 0)


func _click_control(control: Control) -> void:
	# Native offscreen windows have no OS pointer hover; exercise their keyboard
	# path. Headless runs exercise the mouse path through the same GUI controls.
	if DisplayServer.get_name() != "headless":
		control.grab_focus()
		for pressed: bool in [true, false]:
			var event := InputEventAction.new()
			event.action = &"ui_accept"
			event.pressed = pressed
			get_viewport().push_input(event, true)
		await _settle_ui()
		return
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	get_viewport().push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = point
		event.global_position = point
		event.pressed = pressed
		get_viewport().push_input(event, true)
	# Keep the synthetic click in one frame: an offscreen native window polls
	# the physical pointer between frames and can cancel a held test button.
	await _settle_ui()


func _test_reward_and_shop(run_scene: Run, encounter: MapNode) -> void:
	var previous := run_scene.current_view.get_child(0) if run_scene.current_view.get_child_count() > 0 else null
	if previous is GameWorld:
		previous._handle_battle_over("Victory", BattleOverPanel.Type.WIN)
		await get_tree().create_timer(0.4, true).timeout
		get_tree().paused = false
	run_scene.map.last_map_node = encounter
	run_scene._show_regular_rewards()
	await _settle_ui()
	var rewards := run_scene.current_view.get_child(0) as BattleRewards
	if OS.get_cmdline_user_args().has("--capture-ui"):
		await get_tree().create_timer(0.3).timeout
		await _capture("rewards")
	var deck_size := run_scene.player_stats.deck.cards.size()
	rewards._show_card_rewards()
	await _settle_ui()
	var choices := rewards.ui_layer.get_child(rewards.ui_layer.get_child_count() - 1) as CardRewards
	_check(choices != null and choices.cards.get_child_count() > 0, "Reward choices populate")
	if not choices or choices.cards.get_child_count() == 0:
		return
	var option := choices.cards.get_child(0) as CardMenuUI
	_check(option.visuals.get_global_rect().end.y <= choices.skip_button.global_position.y, "Reward cards do not overlap Skip")
	for entry: CardMenuUI in choices.cards.get_children():
		_check(entry.visuals.card_text_label.get_content_height() <= entry.visuals.card_text_label.size.y, "Reward card rules remain inside the face")
	await _capture("reward-selection")
	await _click_control(option)
	_check(choices.card_popup.visible and choices.selected_card == option.card, "Clicking a reward card opens confirmation")
	await _capture("reward-confirm")
	await _test_inspection_cancel(run_scene, choices.card_popup)
	await _click_control(option)
	await _click_control(choices.card_popup.confirm_button)
	_check(run_scene.player_stats.deck.cards.size() == deck_size + 1, "Taking a reward adds exactly one card")
	rewards._show_card_rewards()
	await _settle_ui()
	choices = rewards.ui_layer.get_child(rewards.ui_layer.get_child_count() - 1) as CardRewards
	await _click_control(choices.skip_button)
	_check(run_scene.player_stats.deck.cards.size() == deck_size + 1, "Skipping leaves the deck unchanged")
	run_scene.run_stats.gold = 0
	run_scene.run_stats.resources = 0
	run_scene._on_shop_entered()
	await _settle_ui()
	var shop := run_scene.current_view.get_child(0) as Shop
	for item: ShopCard in shop.cards.get_children():
		_check(item.buy_button.disabled, "Unaffordable shop cards disable Buy")
		_check(item.current_card_ui.visuals.get_global_rect().end.y <= item.price.global_position.y, "Shop prices stay below the card face")
		_check(item.price.get_global_rect().end.y <= item.buy_button.global_position.y, "Shop price and Buy do not overlap")
	await _capture("shop-unaffordable")
	run_scene.run_stats.gold = 1000
	run_scene.run_stats.resources = 100
	shop._update_items()
	await _capture("shop")
	if shop.cards.get_child_count() > 0:
		var item := shop.cards.get_child(0) as ShopCard
		await _click_control(item.current_card_ui)
		_check(shop.card_popup.visible, "Shop cards open inspection on click")
		await _capture("shop-inspect")
		await _test_inspection_cancel(run_scene, shop.card_popup)
		await _click_control(item.current_card_ui)
		await _click_control(shop.card_popup.close_button)
		_check(not shop.card_popup.visible, "Shop inspection closes with Back")
		var cost := item.gold_cost
		deck_size = run_scene.player_stats.deck.cards.size()
		await _click_control(item.buy_button)
		_check(run_scene.run_stats.gold == 1000 - cost and run_scene.player_stats.deck.cards.size() == deck_size + 1, "Shop purchase charges once and adds one card")
		if shop.cards.get_child_count() > 0:
			var next_item := shop.cards.get_child(0) as ShopCard
			cost += next_item.gold_cost
			await _click_control(next_item.buy_button)
			_check(run_scene.run_stats.gold == 1000 - cost, "Further purchases do not revisit freed item controls")
	if shop.relics.get_child_count() > 0:
		var item := shop.relics.get_child(0) as ShopRelic
		var cost := item.resource_cost
		var relic_id := item.relic.id
		await _click_control(item.buy_button)
		_check(run_scene.run_stats.resources == 100 - cost and run_scene.relic_handler.has_relic(relic_id), "Relic purchase charges once and grants its relic")


func _press_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame


func _test_inspection_cancel(run_scene: Run, popup: CardPopup) -> void:
	await _press_escape()
	_check(not popup.visible, "Escape closes active card inspection")
	_check(not get_tree().paused and not run_scene.pause_menu.visible, "Closing inspection does not also pause")
	# Recover after a failed baseline assertion so later transactions can run.
	run_scene.pause_menu._unpause()
	popup.hide_popup()
	await _press_escape()
	_check(get_tree().paused and run_scene.pause_menu.visible, "Escape without inspection opens pause")
	await _press_escape()
	_check(not get_tree().paused and not run_scene.pause_menu.visible, "Escape resumes from pause")


func _test_route_and_icon_feedback(run_scene: Run) -> void:
	var content := run_scene.map_legend.find_child("LegendContent", true, false)
	var rows: VBoxContainer = content.get_node("%VBoxContainer")
	_check(rows.get_child_count() == 7, "Legend includes all seven encounter types")
	for row: Node in rows.get_children():
		var kind: StringName = row.get_meta("map_node_type")
		var icon: TextureRect = row.get_child(0)
		_check(icon.texture == rows.get_theme_icon(kind, &"MapNode"), "Legend matches map icon for " + kind)
	var bounty: ThemedIconButton = run_scene.map_legend.get_node("BountyBoardButton")
	var original_size := bounty.size
	for i in 20:
		bounty._on_mouse_entered()
		_check(bounty.self_modulate == bounty.get_theme_color(&"hover", &"IconButton"), "Hover uses shared theme color")
		bounty._on_mouse_exited()
	_check(bounty.material == null and bounty.size == original_size, "Repeated hover preserves icon bounds without aura shader")
	var node := preload("res://scenes/map/map_node_ui.tscn").instantiate() as MapNodeUI
	add_child(node)
	node.map_node = MapNode.new()
	node.map_node.type = Enums.MapNodeType.MONSTER
	node.available = true
	node.clicked.connect(func(_data: MapNode): node.available = false)
	_check(node.select_route(), "Available route can be entered")
	_check(node.get_node("RouteLabel").text == "Entering", "Entry never flashes a premature cleared label")
	_check(not node.select_route(), "Entering route rejects duplicate selection")
	node.queue_free()
	await get_tree().process_frame
	var keyboard_node := preload("res://scenes/map/map_node_ui.tscn").instantiate() as MapNodeUI
	add_child(keyboard_node)
	keyboard_node.map_node = MapNode.new()
	keyboard_node.available = true
	keyboard_node.get_node("KeyboardFocus").grab_focus()
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	Input.parse_input_event(accept)
	await get_tree().process_frame
	accept = InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = false
	Input.parse_input_event(accept)
	await get_tree().process_frame
	_check(keyboard_node.map_node.selected, "Keyboard activation enters an available route node")
	keyboard_node.queue_free()
	await get_tree().process_frame


func _capture_production_deck() -> void:
	var cards: Array[Card] = []
	for folder: String in ["common", "riftwalker"]:
		var directory := "res://resources/data/cards/" + folder
		var files := DirAccess.get_files_at(directory)
		files.sort()
		for file: String in files:
			if file.ends_with(".tres"):
				cards.append(load(directory.path_join(file)) as Card)
	var fixture := Control.new()
	fixture.size = Vector2(1920, 1080)
	add_child(fixture)
	for first in range(0, cards.size(), 10):
		var pile := CardPile.new()
		for card: Card in cards.slice(first, mini(first + 10, cards.size())):
			pile.add_card(card)
		var view := load("res://ui/card_pile/card_pile_view.tscn").instantiate() as CardPileView
		view.card_pile = pile
		fixture.add_child(view)
		view.show_current_view("Deck")
		await _settle_ui()
		await _capture("illustrated-deck-%d" % (first / 10 + 1))
		view.queue_free()
		await get_tree().process_frame
	fixture.queue_free()
	await get_tree().process_frame


func _test_ui_composition() -> void:
	var fixture := Control.new()
	fixture.size = Vector2(1920, 1080)
	add_child(fixture)
	var card: Card = load("res://resources/data/cards/riftwalker/arcane_bolt.tres")
	var pile := CardPile.new()
	for i in range(12):
		pile.add_card(card.duplicate())
	var view: CardPileView = load("res://ui/card_pile/card_pile_view.tscn").instantiate()
	view.card_pile = pile
	fixture.add_child(view)
	view.show_current_view("Deck")
	await _settle_ui()
	var wide_row: float = view.card_container.get_child(0).position.y
	_check(view.card_container.get_child(6).position.y == wide_row, "Wide collection fits several cards on a row")
	await _capture("pile-wide")
	fixture.size = Vector2(1280, 720)
	await _settle_ui()
	_check(view.card_container.get_child(6).position.y > wide_row, "Native card flow wraps at a narrower width")
	_check(view.back_button.get_global_rect().end.x <= fixture.size.x, "Pile navigation stays inside a narrower layout")
	for entry: CardMenuUI in view.card_container.get_children():
		var visual_rect := entry.visuals.get_global_rect()
		_check(visual_rect.position.x >= entry.global_position.x and visual_rect.end.x <= entry.get_global_rect().end.x, "Card visuals fit their container slots")
	await _capture("pile-narrow")
	view.queue_free()
	await get_tree().process_frame
	var selection: CardCostSelection = load("res://ui/card_selection/card_cost_selection.tscn").instantiate()
	fixture.add_child(selection)
	var request := CardCostSelectionRequest.new()
	request.cards = pile.cards
	request.max_select = 2
	request.body = "Select cards to pay this cost. The remaining cards stay in your deck."
	selection._on_card_cost_selection_requested(request)
	await _settle_ui()
	_check(selection.card_container.size.x > 0 and selection.card_container.size.y > 0, "Selection content is sized by its containers")
	_check(selection.confirm_button.get_global_rect().end.x <= fixture.size.x, "Selection actions stay inside the layout")
	var option := selection.card_container.get_child(0) as CardMenuUI
	_check(not option.visuals.card_text_label.text.contains("%s"), "Selection cards show resolved descriptions")
	option.set_selected(true)
	option.selection_toggled.emit(option.card, true)
	_check(not selection.confirm_button.disabled, "Recomposed selection can enable confirmation")
	await _capture("selection-narrow")
	fixture.size = Vector2(1920, 1080)
	await _settle_ui()
	await _capture("selection-wide")
	option.set_selected(false)
	var face := option.visuals.background_texture
	var shared_style := face.get_theme_stylebox("panel")
	option.visuals.set_boosted_effect(true)
	_check(face.get_theme_stylebox("panel") != shared_style, "Card state selects another theme style")
	var other := selection.card_container.get_child(1) as CardMenuUI
	_check(other.visuals.background_texture.get_theme_stylebox("panel") == shared_style, "Changing one card does not mutate shared styles")
	var authored := load("res://ui/card_ui/card_visuals.tscn").instantiate() as CardVisuals
	authored.get_node("CardBackgroundTexture").theme_type_variation = &"CardFaceModified"
	fixture.add_child(authored)
	authored.set_hover_outline(true)
	authored.set_hover_outline(false)
	_check(authored.background_texture.theme_type_variation == &"CardFaceModified", "Returning from hover preserves the face style authored in the scene")
	authored.card = load("res://resources/data/cards/riftwalker/corroding_shot.tres")
	await _settle_ui()
	_check(authored.card_text_label.get_content_height() <= authored.card_text_label.size.y, "Long card rules fit without clipping mechanics (%s / %s, %s)" % [authored.card_text_label.get_content_height(), authored.card_text_label.size.y, authored.card_text_label.theme_type_variation])
	fixture.queue_free()
	await get_tree().process_frame


func _settle_ui() -> void:
	for i in range(5):
		await get_tree().process_frame


func _test_hand_cycle(sandbox: GameWorldSandbox) -> void:
	var handler := sandbox.player_handler
	var hand := handler.player_hand
	var stats := sandbox.player_stats
	var cards: Array[Card] = []
	for card_ui: CardUI in hand.get_cards():
		cards.append(card_ui.card)
	_check(not cards.is_empty(), "Hand cycle starts with drawn cards")
	stats.draw_pile.clear()
	stats.discard.clear()
	var observed := {"signals": 0, "count": -1, "hand_count": -1}
	var on_discard := func():
		observed.signals += 1
		observed.count = stats.discard.cards.size()
		observed.hand_count = hand.get_child_count()
	Events.player_hand_discarded.connect(on_discard)
	handler.discard_cards()
	_check(observed.signals == 1 and observed.count == cards.size(), "Discard is committed before the next phase is notified")
	_check(observed.hand_count == 0, "Discard notification observes an empty hand")
	# Simulate closing the battle before discard animations finish.
	for child: Node in sandbox.ui.get_children():
		if child is CardUI:
			child.queue_free()
	await get_tree().process_frame
	_check(stats.discard.cards.size() == cards.size(), "Stopping discard animations preserves every card")
	handler.discard_cards()
	_check(stats.discard.cards.size() == cards.size(), "Repeated cleanup cannot duplicate discards")
	Events.player_hand_discarded.disconnect(on_discard)
	for i in range(cards.size()):
		handler.draw_card()
	_check(hand.get_child_count() == cards.size(), "Discarded hand can be reshuffled and drawn immediately")
	_check(stats.draw_pile.is_empty() and stats.discard.is_empty(), "Redraw consumes available cards exactly once")
	handler.draw_card()
	_check(hand.get_child_count() == cards.size(), "Drawing from empty piles creates no card UI")
	var drawn := {"signals": 0}
	var on_drawn := func(): drawn.signals += 1
	Events.player_hand_drawn.connect(on_drawn)
	handler.draw_cards(0)
	_check(drawn.signals == 1, "Zero-card draws still complete the draw phase")
	handler.draw_cards(cards.size() + 2)
	await get_tree().create_timer((cards.size() + 2) * PlayerHandler.HAND_DRAW_INTERVAL + 0.2).timeout
	_check(drawn.signals == 2 and hand.get_child_count() == cards.size(), "Overdrawing an exhausted deck completes without phantom cards")
	Events.player_hand_drawn.disconnect(on_drawn)
	var discarded_ui := hand.get_cards()
	# Exercise the standalone fallback as well as normal animation completion.
	sandbox.ui.remove_from_group("ui_layer")
	handler.discard_cards()
	sandbox.ui.add_to_group("ui_layer")
	_check(hand.get_child_count() == 0 and stats.discard.cards.size() == cards.size(), "Standalone discard also detaches the hand immediately")
	await get_tree().create_timer(0.4).timeout
	for card_ui in discarded_ui:
		_check(not is_instance_valid(card_ui), "Completed discard animations release their controls")
	_check(stats.discard.cards.size() == cards.size(), "Animation completion does not duplicate discarded cards")
	var exhaust_card := cards[0].duplicate(true) as Card
	exhaust_card.exhaust = true
	var exhaust_before := stats.exhaust_pile.cards.size()
	hand.add_card(exhaust_card)
	handler.discard_cards()
	_check(stats.exhaust_pile.cards.size() == exhaust_before + 1 and stats.exhaust_pile.cards.has(exhaust_card), "Unplayed Exhaust cards enter the exhaust pile at end of turn")
	_check(not stats.discard.cards.has(exhaust_card), "Unplayed Exhaust cards never enter the reshuffle pool")
	handler.discard_cards()
	_check(stats.exhaust_pile.cards.size() == exhaust_before + 1, "Repeated cleanup cannot duplicate exhausted cards")
	# A draw tween belongs to the handler, which can outlive the player.
	drawn.signals = 0
	Events.player_hand_drawn.connect(on_drawn)
	handler.draw_cards(3)
	var pending_draw := handler._draw_tween
	pending_draw.custom_step(0.001)
	var count_before := hand.get_child_count()
	sandbox.player.queue_free()
	_check(not handler._can_draw(), "Queued player deletion prevents further draws")
	await get_tree().process_frame
	handler.draw_card()
	handler.draw_cards(0)
	await get_tree().create_timer(0.5).timeout
	_check(not pending_draw.is_valid(), "Player removal cancels the pending draw tween")
	_check(drawn.signals == 0 and not handler.hand_ready, "Cancelled draws never complete the player phase")
	_check(hand.get_child_count() == count_before, "Freed player draws leave the hand unchanged")
	Events.player_hand_drawn.disconnect(on_drawn)


func _test_telemetry_disclaimer() -> void:
	_check(not SettingsData.new().telemetry_enabled, "Fresh settings leave optional telemetry disabled")
	var original := GameSettings.get_current_settings()
	original.fullscreen = false
	GameSettings.save_settings(original)
	var packed: PackedScene = load("res://scenes/splash_screens/splash_screen.tscn")
	for enabled: bool in [false, true]:
		var splash = packed.instantiate()
		splash.set_script(ConsentSplash)
		add_child(splash)
		await get_tree().create_timer(0.8).timeout
		_check(not splash.accept_button.disabled and not splash.decline_button.disabled, "Both telemetry choices become available after the splash")
		_check(splash.decline_button.has_focus(), "Optional telemetry does not default focus to sharing")
		if not enabled:
			await _capture("telemetry-disclaimer")
		await _click_control(splash.accept_button if enabled else splash.decline_button)
		splash._choose_telemetry(not enabled)
		_check(GameSettings.telemetry_enabled == enabled and GameSettings.get_current_settings().telemetry_enabled == enabled, "Telemetry choice is applied and persisted")
		_check(TelemetryManager.client.consent == enabled, "Telemetry client follows the saved consent choice")
		await get_tree().create_timer(0.3).timeout
		_check(splash.continuations == 1, "Both choices continue to the menu exactly once")
		_check(not TelemetryManager._quitting, "Declining optional telemetry never quits the game")
		splash.queue_free()
		await get_tree().process_frame
	GameSettings.save_settings(original)


func _test_supporting_rooms() -> void:
	var stats: PlayerStats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
	stats.health = 10
	var run_stats := RunStats.new()
	var hud = load("res://ui/run_ui/run_hud.tscn").instantiate()
	add_child(hud)
	hud.bind_run(stats, run_stats)
	var rest: Rest = load("res://scenes/rest/rest.tscn").instantiate()
	add_child(rest)
	rest.player_stats = stats
	await _settle_ui()
	_check(rest.get_node("%RecoveryAmount").text.contains(str(ceili(stats.max_health * 0.3))), "Campfire previews the actual recovery amount")
	await _capture("campfire")
	var expected := mini(stats.max_health, stats.health + ceili(stats.max_health * 0.3))
	await _click_control(rest.rest_button)
	rest._on_rest_button_pressed()
	_check(stats.health == expected, "Campfire restores 30 percent once even with repeated input")
	await get_tree().create_timer(1.1).timeout
	rest.queue_free()
	await get_tree().process_frame
	var relics: RelicHandler = load("res://scenes/relic_handler/relic_handler.tscn").instantiate()
	add_child(relics)
	var treasure: Treasure = load("res://scenes/treasure/treasure.tscn").instantiate()
	add_child(treasure)
	treasure.player_stats = stats
	treasure.relic_handler = relics
	treasure.generate_relic()
	await _settle_ui()
	_check(treasure.found_relic != null, "Treasure preserves the eligible relic reward pool")
	await _capture("treasure")
	var observed := {"count": 0}
	var on_reward := func(_relic: Relic): observed.count += 1
	Events.treasure_room_exited.connect(on_reward)
	await _click_control(treasure.open_button)
	treasure._open_treasure()
	await get_tree().create_timer(0.7).timeout
	_check(observed.count == 1, "Opening a treasure cache announces exactly one reward")
	Events.treasure_room_exited.disconnect(on_reward)
	treasure.queue_free()
	relics.queue_free()
	hud.queue_free()
	await get_tree().process_frame


func _test_event_choices() -> void:
	var room: EventRoom = load("res://scenes/event/event_room.tscn").instantiate()
	add_child(room)
	var stats: PlayerStats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
	stats.health = 10
	var run_stats := RunStats.new()
	room.setup_event(stats, run_stats, null)
	room._current_event = EventRoom.EVENTS[1]
	room._populate_event()
	_check(room.option_a_button.disabled and room.option_b_button.disabled, "Caravan disables trades without their required currency")
	_check(room.option_a_button.text.contains("Requires 10 gold"), "Unavailable gold trade explains its requirement")
	_check(room.option_b_button.text.contains("Requires 1 resource"), "Unavailable resource trade explains its requirement")
	await _settle_ui()
	await _capture("event-unaffordable")
	room._on_option_a_pressed()
	run_stats.resources = 1
	_check(not room.option_b_button.disabled, "Failed gold trade preserves the alternative and updates live affordability")
	run_stats.gold = 9
	_check(room.option_a_button.disabled, "Gold below the price remains insufficient")
	run_stats.gold = 10
	_check(not room.option_a_button.disabled, "Exact gold price enables the trade without reopening the event")
	await _settle_ui()
	await _capture("event-affordable")
	await _click_control(room.option_a_button)
	_check(run_stats.gold == 0 and stats.health == 16, "Caravan salve charges ten gold and heals six HP")
	_check(room.option_a_button.disabled and room.option_b_button.disabled, "Successful trade consumes the event choice")
	_check(room.leave_button.has_focus(), "Resolved event moves keyboard focus to Leave")
	room._on_option_a_pressed()
	room._on_option_b_pressed()
	run_stats.gold = 100
	_check(stats.health == 16 and run_stats.resources == 1, "Repeated callbacks cannot claim another event reward")
	_check(room.option_a_button.disabled and room.option_b_button.disabled, "Currency updates cannot reopen a resolved event")
	await _capture("event-resolved")
	room._populate_event()
	run_stats.resources = 0
	room._on_option_b_pressed()
	_check(not room.option_a_button.disabled, "Failed resource trade preserves the affordable gold alternative")
	run_stats.resources = 1
	var common := run_stats.common_weight
	var uncommon := run_stats.uncommon_weight
	var rare := run_stats.rare_weight
	await _click_control(room.option_b_button)
	_check(run_stats.resources == 0, "Intel charges exactly one resource")
	_check(is_equal_approx(run_stats.common_weight, common - 0.5) and is_equal_approx(run_stats.uncommon_weight, uncommon + 0.25) and is_equal_approx(run_stats.rare_weight, rare + 0.05), "Intel preserves the authored reward odds change")
	room._current_event = EventRoom.EVENTS[2]
	room._populate_event()
	var gold := run_stats.gold
	room._on_option_a_pressed()
	room._on_option_a_pressed()
	_check(run_stats.gold == gold + 25 and run_stats.resources == 1, "Free event reward can only be claimed once")
	room._current_event = EventRoom.EVENTS[0]
	for remaining_block in [0, 2, 10]:
		room._populate_event()
		stats.health = 10
		stats.block = remaining_block
		var damage_before := stats.total_health_damage
		var resources_before := run_stats.resources
		await _click_control(room.option_a_button)
		_check(stats.health == 6, "Rift Echo costs four HP with %d block" % remaining_block)
		_check(stats.block == remaining_block, "Event HP cost preserves combat block")
		_check(stats.total_health_damage == damage_before + 4, "Event HP loss is included in run damage accounting")
		room._on_option_a_pressed()
		_check(stats.health == 6 and run_stats.resources == resources_before + 1, "Rift Echo charges and rewards exactly once")
	room.queue_free()
	await get_tree().process_frame


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
	var battle: EncounterDefinition = load("res://resources/data/battles/tier_1_channelers_bulwark.tres")
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


func _test_telemetry_event_contract() -> void:
	GameSettings.telemetry_enabled = true
	GameSettings.telemetry_changed.emit(true)
	TelemetryManager.client.register_schema("compatibility_test", {"version": 1, "additionalProperties": true})
	TelemetryManager.track_event("compatibility_test", {"amount": 3, "duration": 1.25})
	_check(TelemetryManager.client.queue.size() == 1, "Telemetry reaches the standalone addon without an identity")
	if not TelemetryManager.client.queue.is_empty():
		var event: Dictionary = TelemetryManager.client.queue.back()
		_check(event.properties.amount == 3 and event.properties.duration == 1.25, "Telemetry preserves numeric properties")
		_check(event.session_id.length() == 32, "Telemetry uses a random session identifier")
	GameSettings.telemetry_enabled = false
	GameSettings.telemetry_changed.emit(false)
	_check(TelemetryManager.client.queue.is_empty() and not TelemetryManager.client.consent, "Opt-out clears pending events and revokes consent")
	TelemetryManager.track_event("compatibility_test", {"amount": 4})
	_check(TelemetryManager.client.queue.is_empty(), "Opt-out prevents subsequent recording")


func _test_lunge_presentation() -> void:
	GameSettings.show_tutorial = false
	var relics := load("res://scenes/relic_handler/relic_handler.tscn").instantiate() as RelicHandler
	add_child(relics)
	var world := load("res://scenes/game_world/game_world.tscn").instantiate() as GameWorld
	add_child(world)
	world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
	world.run_stats = RunStats.new()
	world.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
	world.relics = relics
	world.start_world()
	world.tilemap.hide_fog()
	await get_tree().create_timer(0.6).timeout
	world.player.stats.block = 1000
	var actor: MovingEnemy
	for unit in world.enemy_handler.get_children():
		if unit is MovingEnemy and unit.flying:
			actor = unit
			break
	_check(actor != null, "Native attack fixture includes a flying actor")
	if actor:
		for path: String in ["bat/bat_enemy_attack_action", "blob/blob_attack_action", "horror/horror_attack_action", "bulwark/bulwark_cleave_action", "wasp/wasp_enemy_attack_action", "void_spectre/void_spectre_attack_action"]:
			var action := load("res://scenes/enemy/%s.gd" % path).new() as EnemyAction
			action.enemy = actor
			action.target = world.player
			action.intent = Intent.new()
			action.visual_fx = load("res://ui/fx/claw_slash_fx.tscn")
			if path.begins_with("wasp/"):
				action.set("curse_fx_scene", load("res://ui/fx/curse_fx.tscn"))
			actor.add_child(action)
			var origin := actor.global_transform
			var health := world.player.stats.health
			action.perform_action()
			await get_tree().create_timer(0.2).timeout
			_check(actor.global_transform.is_equal_approx(origin), "Attack windup preserves the authoritative entity transform: %s" % path)
			_check(not actor.animation_player.is_playing(), "Flying idle cannot overwrite the active lunge: %s" % path)
			await get_tree().create_timer(1.4).timeout
			_check(actor.animation_player.is_playing(), "Attack restores flying idle: %s" % path)
			_check(world.player.stats.health == health, "Fully blocked native attack preserves health: %s" % path)
			action.queue_free()
	world.queue_free()
	relics.queue_free()
	await get_tree().process_frame

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
			_check(emitter.amount <= 8 and emitter.process_material.initial_velocity_max <= 4.0, "Ambient presentation stays within the quiet-motion budget: %s" % path)
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
	_check(is_zero_approx(first_rect.modulate.a), "Intro starts transparent before its first animation frame")
	_check(first.visible and first.get_node("BattleVignette/BeatLabel").text == first.intro_text, "Battle intro displays")
	await get_tree().create_timer(0.5).timeout
	_check(not first.visible, "Battle intro hides after animation")
	first.play_intro()
	get_tree().paused = true
	await first.finished
	_check(not first.visible, "Intro cannot freeze over a paused tutorial")
	get_tree().paused = false
	first.play_outro(true)
	_check(is_zero_approx(first_rect.modulate.a), "Victory starts transparent")
	_check(first.get_node("BattleVignette/BeatLabel").text == first.win_text, "Battle victory displays")
	_check(second_rect.material.get_shader_parameter("effect_color") == Color(0.05, 0.05, 0.08, 0.65), "Victory tint does not affect another overlay")
	await first.finished
	_check(not first.visible and is_zero_approx(first_rect.modulate.a), "Outro completion occurs after the overlay disappears")
	first.queue_free()
	second.queue_free()
	await get_tree().process_frame


func _test_scene_ownership() -> void:
	var cases := {
		"res://scenes/run/run.tscn": ["TopBar", "TopBar/TopBarPopupView/DeckView"],
		"res://scenes/game_world/game_world.tscn": ["GameWorldUI/PlayerUI/Stats", "GameWorldUI/PlayerUI/Stats/Content/StatusSlot/StatusHandler"],
		"res://scenes/sandbox/gameworld_sandbox.tscn": ["DevGameWorldUI/DevPanel", "DevGameWorldUI/DevPanel/Panel/MarginContainer/VBoxContainer/EnemyRow/EnemyTierFilter"],
		"res://scenes/battle_rewards/card_rewards.tscn": ["CardPopup", "CardPopup/Center/Surface/Padding/Content/Actions/ConfirmButton"],
	}
	for path: String in cases:
		var original: Node = load(path).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		var packed := PackedScene.new()
		_check(packed.pack(original) == OK, "Pack composed scene: " + path)
		var saved := "user://composition_roundtrip.tscn"
		_check(ResourceSaver.save(packed, saved) == OK, "Save composed scene: " + path)
		var restored: Node = (ResourceLoader.load(saved, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
		var component: Node = restored.get_node_or_null(cases[path][0])
		var owned: Node = restored.get_node_or_null(cases[path][1])
		_check(component != null and owned != null and owned.owner == component, "Scene boundaries survive native save/load: " + path)
		_check(not FileAccess.get_file_as_string(saved).contains("#StatusHandler"), "No generated status attachment artifacts: " + path)
		original.free()
		restored.free()
	DirAccess.remove_absolute("user://composition_roundtrip.tscn")


func _test_shader_fades() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 128)
	viewport.transparent_bg = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var rect := ColorRect.new()
	rect.size = Vector2(viewport.size)
	viewport.add_child(rect)
	for scene_path: String in ["res://ui/world_ui/battle_presentation.tscn", "res://ui/world_ui/battle_over_panel.tscn"]:
		var scene: Node = load(scene_path).instantiate()
		var source: ColorRect = scene.get_node("BattleVignette" if scene is BattlePresentation else "VignetteRect")
		rect.material = source.material
		for opacity: float in [0.0, 0.5, 1.0]:
			rect.modulate.a = opacity
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var pixel := viewport.get_texture().get_image().get_pixel(1, 1)
			var expected_alpha := opacity if scene is BattlePresentation else opacity * 0.8
			_check(absf(pixel.a - expected_alpha) < 0.08, "Shader respects animated opacity %s: %s" % [opacity, scene_path])
		scene.free()
	viewport.queue_free()
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


func _review_presentation() -> void:
	GameSettings.show_tutorial = false
	var menu: Control = load("res://scenes/menus/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().create_timer(1.1).timeout
	await _capture("menu")
	menu.queue_free()
	await get_tree().process_frame
	var run_scene: Run = load("res://scenes/run/run.tscn").instantiate()
	run_scene.run_bootstrap = RunBootstrap.new()
	run_scene.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
	run_scene.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
	get_tree().root.add_child(run_scene)
	await get_tree().create_timer(1.2).timeout
	await _capture("map")
	for entry: MapNodeUI in run_scene.map.map_nodes.get_children():
		if entry.available:
			var focus_button := entry.get_node("KeyboardFocus") as Button
			focus_button.grab_focus()
			_check(focus_button.has_focus() and entry.get_node("RouteLabel").visible, "Available route choices expose keyboard focus and encounter text")
			focus_button.release_focus()
			break
	await _press_escape()
	_check(get_tree().paused and run_scene.pause_menu.visible, "Pause opens from the route")
	_check(run_scene.pause_menu.back_to_game_button.has_focus(), "Pause puts keyboard focus on Resume")
	await get_tree().create_timer(0.2, true).timeout
	await _capture("pause")
	await _click_control(run_scene.pause_menu.back_to_game_button)
	_check(not get_tree().paused, "Resume returns to gameplay")
	var encounter := MapNode.new()
	encounter.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
	await _test_reward_and_shop(run_scene, encounter)
	run_scene._on_game_world_entered(encounter)
	await get_tree().create_timer(1.4).timeout
	var world := run_scene.current_view.get_child(0) as GameWorld
	await _capture("combat-fog")
	world.tilemap.hide_fog()
	world.world_camera.frame_battle()
	await get_tree().create_timer(0.5).timeout
	await _capture("combat")
	var help_button := world.game_world_ui.get_node("CameraHint") as Button
	await _click_control(help_button)
	_check(world.game_world_ui.get_node("CameraHelp").visible, "Camera guidance opens on demand")
	await _click_control(help_button)
	_check(not world.game_world_ui.get_node("CameraHelp").visible, "Camera guidance closes without intercepting gameplay")
	run_scene.queue_free()
	await get_tree().process_frame

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
	frame.save_png("user://overhaul-%s.png" % screen)


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
			_check(enemy.queue_button.visible and enemy.queue_button.disabled and enemy.queue_button.get_node("%EnemyName").text == "Unknown enemy", "Queue shows anonymous, noninteractive placeholders through fog")
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
		_check(card.global_position.y >= get_viewport().get_visible_rect().size.y - card.size.y - card.aim_bottom_inset - 1.0, "Aiming card stays in hand zone")
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
	_check(enemy.stats_ui.get_parent() == world.game_world_ui.enemy_inspection_container, "Enemy inspection belongs to the authored HUD slot")
	Events.enemy_info_hide_requested.emit()
