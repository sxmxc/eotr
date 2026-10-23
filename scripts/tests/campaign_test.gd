extends Node

const RUN = preload("res://scenes/run/run.tscn")
const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
const Progression = preload("res://scripts/autowalker/core/progression_interface.gd")
var failures := 0
var captures := ""

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _ready() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	Utils.presentation_speed = 4.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="): captures = arg.trim_prefix("--captures=")
	run_tests.call_deferred()

func wait_until(predicate: Callable, context: String, seconds: float = 10.0) -> bool:
	var limit := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call() and Time.get_ticks_msec() < limit:
		await get_tree().process_frame
	var ok: bool = predicate.call()
	check(ok, context)
	return ok

func new_run(continued: bool = false) -> Run:
	var run := RUN.instantiate() as Run
	run.run_bootstrap = RunBootstrap.new()
	run.run_bootstrap.type = RunBootstrap.Type.CONTINUED_RUN if continued else RunBootstrap.Type.NEW_RUN
	run.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
	add_child(run)
	return run

func current_view(run: Run) -> Node:
	return run.current_view.get_child(0) if run.current_view.get_child_count() else null

func run_tests() -> void:
	RNG.instance.seed = 31
	if OS.get_cmdline_user_args().has("--event-defeat-only"):
		await _test_event_defeat()
		await Utils.stop_audio_for_shutdown()
		print("Campaign tests: %d failures" % failures)
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--obelisk-encounters-only"):
		_test_content()
		await _test_obelisk_resume()
		await Utils.stop_audio_for_shutdown()
		print("Campaign tests: %d failures" % failures)
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--save-validation-only"):
		await _test_saved_deck_validation()
		await Utils.stop_audio_for_shutdown()
		print("Campaign tests: %d failures" % failures)
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--save-quit-only"):
		await _test_failed_save_quit()
		await Utils.stop_audio_for_shutdown()
		print("Campaign tests: %d failures" % failures)
		get_tree().quit(1 if failures else 0)
		return
	_test_telemetry_attribution()
	_test_content()
	await _test_bosses()
	await _test_new_enemy_rules()
	if OS.get_cmdline_user_args().has("--bosses-only"):
		await Utils.stop_audio_for_shutdown()
		print("Campaign tests: %d failures" % failures)
		get_tree().quit(1 if failures else 0)
		return
	var run := new_run()
	await get_tree().process_frame
	run.run_stats.gold = 123
	run.run_stats.resources = 9
	var initial_deck := run.player_stats.deck.cards.size()
	for act_index in 3:
		check(run.run_stats.act_index == act_index, "Act identity advances exactly once")
		var act := run.active_act
		check(run.map.map_data.size() == 15, "Every act has 15 floors")
		var boss_count := 0
		for floor_nodes: Array in run.map.map_data:
			for node: MapNode in floor_nodes:
				if node.type == Enums.MapNodeType.BOSS: boss_count += 1
				if node.battle_stats and (not node.next_nodes.is_empty() or node.type == Enums.MapNodeType.BOSS):
					check(act.encounters.find(node.battle_stats.encounter_id) != null, "Map only selects its act's authored pool")
		check(boss_count == 1, "Exactly one mandatory boss per act")
		for floor_index in 15:
			var candidates: Array[Resource] = []
			if run.map.last_map_node:
				candidates = run.map.last_map_node.next_nodes
			else:
				for node: MapNode in run.map.map_data[0]:
					if not node.next_nodes.is_empty(): candidates.append(node)
			check(not candidates.is_empty(), "Every selected route reaches the next floor")
			if candidates.is_empty(): break
			var chosen := candidates[0] as MapNode
			run.map._on_map_node_ui_selected(chosen)
			await get_tree().process_frame
			var view := current_view(run)
			if view is GameWorld:
				await wait_until(func(): return view.player_handler.hand_ready, "Combat initializes during structural traversal")
				if act_index == 0 and floor_index == 0:
					var checkpoint_health := run.player_stats.health
					run.player_stats.take_direct_damage(3)
					run.queue_free()
					await get_tree().process_frame
					run = new_run(true)
					await get_tree().process_frame
					view = current_view(run)
					check(view is GameWorld and run.player_stats.health == checkpoint_health, "Mid-combat resume restarts the pre-encounter checkpoint")
					await wait_until(func(): return view.player_handler.hand_ready, "Resumed combat initializes")
				# Accelerated lifecycle fixture, NOT an autonomous balance run.
				for enemy: Enemy in view.enemy_handler.get_children():
					enemy.take_damage(enemy.stats.health + enemy.stats.block, Enums.ModifierType.NO_MODIFIER, true)
				await wait_until(func(): return view.battle_over_handled, "All-hostile victory commits")
				await wait_until(func(): return get_tree().paused, "Victory panel completes its presentation")
				view.game_world_ui.get_node("BattleOverLayer/BattleOverPanel").continue_button.pressed.emit()
				await get_tree().process_frame
				view = current_view(run)
			if view is BattleRewards:
				view._on_back_button_pressed()
			elif view is Rest:
				view._on_skip_button_pressed()
				await wait_until(func(): return run.map.visible, "Rest returns to the route")
			elif view is Shop:
				view._on_leave_button_pressed()
			elif view is Treasure:
				view._on_treasure_opened()
				await get_tree().process_frame
				var rewards := current_view(run) as BattleRewards
				if rewards: rewards._on_back_button_pressed()
			elif view is EventRoom:
				view._leave_event()
			await get_tree().process_frame
			check(run.map.floors_climbed == floor_index + 1, "Act floor count includes all room categories")
		if act_index < 2:
			check(current_view(run) is ActTransition, "Boss opens act rewards instead of run victory")
			check(run.run_stats.pending_act_transition, "Pending transition is persisted")
			var gold := run.run_stats.gold
			var id := run.run_stats.run_id
			run.queue_free()
			await get_tree().process_frame
			run = new_run(true)
			await get_tree().process_frame
			check(current_view(run) is ActTransition, "Resume restores pending transition")
			check(run.run_stats.gold == gold and run.run_stats.run_id == id, "Currency and run identity survive resume")
			run.advance_act()
			await get_tree().process_frame
			check(run.run_stats.gold == gold + 35, "Boss reward granted exactly once")
			check(run.player_stats.deck.cards.size() == initial_deck, "Deck survives transition without forced bloat")
			check(run.run_stats.resources == 9, "Resources persist across acts")
			check(run.relic_handler.get_all_relics().size() >= 2, "Relics persist across acts")
			run._save_run(true)
			run.queue_free()
			await get_tree().process_frame
			run = new_run(true)
			await get_tree().process_frame
			check(run.map.floors_climbed == 0 and run.map.visible, "Resume after transition retains the new map")
		else:
			check(current_view(run) is WinScreen, "Only Act III produces final victory")
			check(not FileAccess.file_exists(SaveGame.SAVE_PATH), "Final victory removes disposable save")
	check(run.run_stats.completed_floors + run.map.floors_climbed == 45, "Full run traverses 45 floors")
	run.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	await _test_legacy_and_failure()
	await _test_event_defeat()
	await _test_saved_deck_validation()
	await _test_failed_save_quit()
	await _test_shop_and_refinement()
	await Utils.stop_audio_for_shutdown()
	print("Campaign tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)

func _test_obelisk_resume() -> void:
	var run := new_run()
	await get_tree().process_frame
	var chosen: MapNode
	for candidate: MapNode in run.map.map_data[0]:
		if not candidate.next_nodes.is_empty():
			chosen = candidate
			break
	check(chosen != null, "Resume fixture has a connected opening room")
	if not chosen:
		return
	chosen.battle_stats = load("res://resources/data/battles/measured_advance.tres")
	run.map._on_map_node_ui_selected(chosen)
	await get_tree().process_frame
	var world := current_view(run) as GameWorld
	await wait_until(func(): return world.player_handler.hand_ready, "Measured Advance initializes before saving")
	# Reproduce an older checkpoint embedding the incomplete composition.
	var checkpoint := SaveGame.load_data()
	checkpoint.last_map_node.battle_stats.enemies = load("res://scripts/tests/fixtures/measured_advance_without_obelisk.tscn")
	checkpoint.last_map_node.battle_stats.gold_reward_min = 123
	check(checkpoint.save_data(), "Serialize old embedded encounter checkpoint")
	var checkpoint_hash := FileAccess.get_sha256(SaveGame.SAVE_PATH)
	check(SaveGame.load_data() != null and FileAccess.get_sha256(SaveGame.SAVE_PATH) == checkpoint_hash, "Composition recovery leaves checkpoint bytes unchanged")
	run.queue_free()
	await get_tree().process_frame
	run = new_run(true)
	await get_tree().process_frame
	world = current_view(run) as GameWorld
	check(world != null, "Continued checkpoint restores Measured Advance combat")
	if world:
		await wait_until(func(): return world.player_handler.hand_ready, "Continued combat reaches the first hand")
		await get_tree().physics_frame
		check(world.battle_stats.encounter_id == "measured_advance", "Resume retains selected encounter")
		check(world.battle_stats.gold_reward_min == 123, "Composition recovery retains saved encounter rewards")
		var obelisk := world.tilemap.obelisk as Obelisk
		check(is_instance_valid(obelisk), "Continued non-boss encounter contains an Obelisk")
		if is_instance_valid(obelisk):
			check(obelisk.current_tile_position == world.tilemap.get_center_tile_coord(), "Resumed Obelisk occupies board center")
			check(not world.tilemap.is_tile_behind_fog(obelisk.current_tile_position) and obelisk.is_visible_in_tree(), "Resumed Obelisk is revealed without clearing all fog")
			check(obelisk.spawn_pool.size() == 2 and obelisk.has_viable_spawn_tile(), "Restored Obelisk has its encounter roster and viable summon tiles")
		if not captures.is_empty() and DisplayServer.get_name() != "headless":
			await get_tree().create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(captures.path_join("measured-advance-resumed.png"))
	run.queue_free()
	await get_tree().process_frame


func _test_saved_deck_validation() -> void:
	var run := new_run()
	await get_tree().process_frame
	var saved := SaveGame.load_data()
	check(saved != null, "Valid checkpoint loads before deck corruption")
	if saved == null:
		run.queue_free()
		await get_tree().process_frame
		return
	for missing_deck: bool in [true, false]:
		var invalid := saved.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SaveGame
		if missing_deck:
			invalid.current_deck = null
		else:
			invalid.current_deck.cards.append(null)
		check(ResourceSaver.save(invalid, SaveGame.SAVE_PATH) == OK, "Write isolated invalid deck fixture")
		var previous := FileAccess.get_sha256(SaveGame.SAVE_PATH)
		check(SaveGame.load_data() == null, "Reject missing deck or null card before run startup")
		check(FileAccess.get_sha256(SaveGame.SAVE_PATH) == previous, "Rejected deck checkpoint retains original bytes")
		var dialog := Utils.get_node_or_null("SaveError") as AcceptDialog
		check(dialog != null and dialog.visible, "Invalid deck presents recovery instructions")
		if dialog:
			dialog.hide()
	for corruption: String in ["short row", "null node", "wrong coordinates", "null edge", "foreign edge", "foreign last node"]:
		var invalid := saved.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SaveGame
		match corruption:
			"short row": invalid.map_data[0].pop_back()
			"null node": invalid.map_data[0][0] = null
			"wrong coordinates": invalid.map_data[0][0].row = 9
			"null edge": invalid.map_data[0][0].next_nodes.append(null)
			"foreign edge": invalid.map_data[0][0].next_nodes.append(MapNode.new())
			"foreign last node":
				invalid.floors_climbed = 1
				invalid.last_map_node = MapNode.new()
		check(ResourceSaver.save(invalid, SaveGame.SAVE_PATH) == OK, "Write invalid map fixture: " + corruption)
		var previous := FileAccess.get_sha256(SaveGame.SAVE_PATH)
		check(SaveGame.load_data() == null, "Reject invalid map: " + corruption)
		check(FileAccess.get_sha256(SaveGame.SAVE_PATH) == previous, "Rejected map retains checkpoint bytes")
		var dialog := Utils.get_node_or_null("SaveError") as AcceptDialog
		check(dialog != null and dialog.visible, "Invalid map presents recovery instructions")
		if dialog:
			dialog.hide()
	for kind: int in [Enums.MapNodeType.MONSTER, Enums.MapNodeType.ELITE, Enums.MapNodeType.BOSS]:
		var invalid := saved.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SaveGame
		var node := invalid.map_data[-1][floori(MapGenerator.MAP_WIDTH * 0.5)] as MapNode
		if kind != Enums.MapNodeType.BOSS:
			for candidate: MapNode in invalid.map_data[0]:
				if not candidate.next_nodes.is_empty():
					node = candidate
					break
		node.type = kind
		node.battle_stats = null
		check(ResourceSaver.save(invalid, SaveGame.SAVE_PATH) == OK, "Write missing encounter fixture")
		var previous := FileAccess.get_sha256(SaveGame.SAVE_PATH)
		check(SaveGame.load_data() == null, "Reject missing encounter for combat room %d" % kind)
		check(FileAccess.get_sha256(SaveGame.SAVE_PATH) == previous, "Missing encounter retains checkpoint bytes")
		var dialog := Utils.get_node_or_null("SaveError") as AcceptDialog
		check(dialog != null and dialog.visible, "Missing encounter presents recovery instructions")
		if dialog:
			dialog.hide()
	for version: int in [0, 1, SaveGame.CURRENT_VERSION]:
		saved.progression_version = version
		check(ResourceSaver.save(saved, SaveGame.SAVE_PATH) == OK, "Write supported map version")
		check(SaveGame.load_data() != null, "Current and legacy generated maps remain loadable")
	saved.current_deck.cards.clear()
	check(saved.save_data(), "Save valid empty deck fixture")
	var empty := SaveGame.load_data()
	check(empty != null and empty.current_deck.cards.is_empty(), "Empty decks remain loadable")
	run.queue_free()
	await get_tree().process_frame

func _test_failed_save_quit() -> void:
	var run := new_run()
	await get_tree().process_frame
	var previous := FileAccess.get_sha256(SaveGame.SAVE_PATH)
	const PENDING := "user://savegame.pending.res"
	check(DirAccess.make_dir_absolute(PENDING) == OK, "Create isolated save failure fixture")
	run.pause_menu._pause()
	run.pause_menu.save_and_quit_button.pressed.emit()
	check(get_tree().paused, "Failed Save and Quit keeps gameplay paused")
	check(run.pause_menu.visible, "Failed Save and Quit retains the pause menu")
	check(FileAccess.get_sha256(SaveGame.SAVE_PATH) == previous, "Failed Save and Quit preserves checkpoint bytes")
	var dialog := Utils.get_node_or_null("SaveError") as AcceptDialog
	check(dialog != null and dialog.visible, "Failed Save and Quit presents recovery instructions")
	if dialog:
		dialog.hide()
	DirAccess.remove_absolute(PENDING)
	check(run.save_data.save_data(), "Checkpoint can be saved after the I/O obstruction is removed")
	run.pause_menu.back_to_game_button.pressed.emit()
	check(not get_tree().paused and not run.pause_menu.visible, "Player can explicitly resume after failed Save and Quit")
	# Let the production success path replace a real current scene while this
	# test coordinator survives as a separate root child.
	var coordinator := get_tree().current_scene
	run.reparent(get_tree().root)
	get_tree().current_scene = run
	run.pause_menu._pause()
	run.pause_menu.save_and_quit_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var menu := get_tree().current_scene
	check(menu != null and menu.scene_file_path == Run.MAIN_MENU_PATH, "Successful Save and Quit opens the main menu")
	check(not get_tree().paused, "Successful Save and Quit releases pause")
	check(SaveGame.load_data() != null, "Successful Save and Quit leaves a resumable checkpoint")
	get_tree().current_scene = coordinator
	if menu != null and menu != coordinator:
		menu.queue_free()
	await get_tree().process_frame

func _test_content() -> void:
	for act in ActDefinition.campaign():
		check(act.background != null and act.background.get_width() == 1536, "Act backdrop retains its authored width")
		var ids: Array[String] = []
		var categories: Dictionary = {}
		for definition in act.encounters.encounters:
			check(not ids.has(definition.encounter_id), "Act encounter IDs are unique")
			ids.append(definition.encounter_id)
			categories[definition.category] = true
			var composition := definition.enemies.instantiate()
			var obelisk_count := 0
			for enemy: Enemy in composition.get_children():
				if enemy is Obelisk:
					obelisk_count += 1
			if definition.category != EncounterDefinition.Category.BOSS:
				check(obelisk_count == 1, "Non-boss encounter contains exactly one Obelisk: " + definition.encounter_id)
			for enemy: Enemy in composition.get_children():
				check(enemy.stats != null and enemy.stats.board_icon is Texture2D, "Every campaign combatant has a real illustration")
				check(enemy.stats.ai != null or enemy is RiftBoss, "Every combatant has an executable AI")
			composition.free()
		check(categories.has(EncounterDefinition.Category.NORMAL) and categories.has(EncounterDefinition.Category.ELITE) and categories.has(EncounterDefinition.Category.BOSS), "Every act has all three combat categories")
		var generator := MapGenerator.new()
		generator.act = act
		generator.encounter_registry = act.encounters
		for simulation_seed in [1, 7, 31]:
			RNG.instance.seed = simulation_seed
			for row: Array in generator.generate_map():
				for node: MapNode in row:
					if node.next_nodes.is_empty(): continue
					var safe := false
					for next: MapNode in node.next_nodes:
						if next.type != Enums.MapNodeType.ELITE: safe = true
					check(safe, "Elite risk always has a connected alternative")
		generator.free()

func _test_telemetry_attribution() -> void:
	var client = TelemetryManager.client
	var original_config = client.config
	var original_context: Dictionary = client.context.duplicate(true)
	client.config = original_config.duplicate(true)
	client.config.enabled = true
	client.config.consent_required = false
	client.config.profile = "qa"
	client.set_process(false)
	client.queue.clear()
	TelemetryManager.suspended = false
	TelemetryManager.set_context({"run_id": "campaign-attribution", "source_type": "bot"})
	TelemetryManager.progression_context = {"act": 2, "act_id": "corruption", "act_floor": 3, "run_floor": 18}
	for marker in ["act_started", "act_completed", "run_failed", "card_removed"]:
		TelemetryManager.track_event(marker, {"source": "campaign_test"})
	check(client.queue.size() == 4, "Lifecycle events pass strict deployed schema validation")
	for envelope: Dictionary in client.queue:
		check(envelope.event_name == "stat_changed" and envelope.metadata.has("lifecycle_event"), "Lifecycle markers use the deployed event contract")
		check(envelope.run_id == "campaign-attribution" and envelope.source_type == "bot" and envelope.metadata.run_floor == 18, "Telemetry retains run/source/act/floor attribution")
	client.queue.clear()
	client.config = original_config
	client.context = original_context
	client.set_process(true)
	TelemetryManager.suspended = true
	TelemetryManager.progression_context.clear()

func _test_shop_and_refinement() -> void:
	var run := new_run()
	await get_tree().process_frame

	run.run_stats.gold = 999
	run.run_stats.resources = 99
	run._on_shop_entered()
	await get_tree().process_frame
	var interface := Progression.new()
	interface.run_node = run
	var bought := false
	for action: Dictionary in interface.legal_actions():
		if action.kind == "buy_relic":
			var before := run.run_stats.resources
			check(interface.execute(action), "Shop purchase executes through the real button path")
			check(run.relic_handler.has_relic(action.relic) and run.run_stats.resources == before - int(action.cost), "Shop relic purchase preserves authoritative inventory and cost")
			bought = true
			break
	check(bought, "Campaign policy can acquire affordable shop relics")
	var shop := current_view(run) as Shop
	var refine := shop.get_node("UILayer/Layout/Footer/RefineDeck")
	var size := run.player_stats.deck.cards.size()
	var gold := run.run_stats.gold
	refine._choose()
	var selection := refine.get_node("SelectionLayer/Selection") as CardCostSelection
	Events.card_cost_selection_completed.emit([run.player_stats.deck.cards[0]] as Array[Card], selection._request)
	check(run.player_stats.deck.cards.size() == size - 1 and run.run_stats.gold == gold - 60, "Refinement removes exactly one card and charges once")
	Events.card_cost_selection_completed.emit([run.player_stats.deck.cards[0]] as Array[Card], selection._request)
	check(run.player_stats.deck.cards.size() == size - 1 and run.run_stats.gold == gold - 60, "Repeated refinement callbacks cannot charge twice")
	run.queue_free()
	await get_tree().process_frame

func _test_new_enemy_rules() -> void:
	var relics := RELICS.instantiate() as RelicHandler
	add_child(relics)
	var world := WORLD.instantiate() as GameWorld
	add_child(world)
	world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
	world.run_stats = RunStats.new()
	world.run_stats.act_index = 2
	world.battle_stats = load("res://resources/data/battles/unwoven_path.tres")
	world.relics = relics
	world.start_world()
	await wait_until(func(): return world.player_handler.hand_ready, "New enemy rules initialize in real combat")
	var board := world.tilemap
	var weaver := world.enemy_handler.get_node("Unit0") as Enemy
	var action := weaver.current_action
	var candidate := Vector2i(-1, -1)
	for cell in board.base_layer.get_surrounding_cells(board.player_position):
		if board.is_within_bounds(cell) and board.is_tile_free(cell):
			board.change_terrain(cell, Enums.TileType.RESOURCE)
			candidate = cell
			break
	check(candidate != Vector2i(-1, -1), "Weaver fixture has a contestable route")
	for cell in board.base_layer.get_surrounding_cells(board.player_position):
		if cell != candidate and board.is_within_bounds(cell): board.change_terrain(cell, Enums.TileType.CORRUPTED)
	action.warning_cell = candidate
	action.perform_action()
	await get_tree().create_timer(0.25).timeout
	check(not board.is_tile_corrupt(candidate), "Weaver cannot corrupt the player's final safe exit")
	# Restore room for an actual movement and a live energy-sensitive intention.
	for cell in board.base_layer.get_surrounding_cells(board.player_position):
		if board.is_within_bounds(cell): board.change_terrain(cell, Enums.TileType.RESOURCE)
	var debt := world.enemy_handler.get_node("Unit1") as MovingEnemy
	if debt.set_movement_target(candidate): await debt.movement_finished
	world.player_stats.energy = 3
	debt.update_intent()
	var before := debt.current_action.intent.current_text
	world.player_stats.energy = 0
	check(debt.current_action.intent.current_text != before, "Debt Eater's announced damage updates when energy is spent")
	world.queue_free()
	relics.queue_free()
	await get_tree().process_frame

func _test_event_defeat() -> void:
	for health: int in [2, 4, 5, 10]:
		var run := new_run()
		await get_tree().process_frame
		run.player_stats.health = health
		var room: MapNode
		for candidate: MapNode in run.map.map_data[0]:
			if not candidate.next_nodes.is_empty():
				room = candidate
				break
		room.type = Enums.MapNodeType.EVENT
		run.map._on_map_node_ui_selected(room)
		var event := current_view(run) as EventRoom
		event._current_event = EventRoom.EVENTS[0]
		event._populate_event()
		if health == 10:
			var gold := run.run_stats.gold
			var resources := run.run_stats.resources
			event.leave_button.pressed.emit()
			var checkpoint := FileAccess.get_file_as_bytes(SaveGame.SAVE_PATH)
			event.option_a_button.pressed.emit()
			event.option_b_button.pressed.emit()
			event.leave_button.pressed.emit()
			check(run.player_stats.health == health and run.run_stats.gold == gold and run.run_stats.resources == resources, "Leaving without a choice prevents detached costs and rewards")
			check(FileAccess.get_file_as_bytes(SaveGame.SAVE_PATH) == checkpoint, "Detached callbacks leave the map checkpoint unchanged")
			run.queue_free()
			await get_tree().process_frame
			continue
		event.option_a_button.pressed.emit()
		check(run.player_stats.health == maxi(0, health - 4), "Event button pays its HP cost at %d HP" % health)
		if health <= 4:
			check(current_view(run) is BattleOverPanel, "Lethal event button opens defeat")
			check(not event.is_inside_tree(), "Defeat detaches the resolved event")
			# A second queued activation must not replace defeat or recreate a save.
			event.leave_button.pressed.emit()
			check(current_view(run) is BattleOverPanel, "Detached event cannot return a defeated run to the map")
			check(not FileAccess.file_exists(SaveGame.SAVE_PATH), "Defeated event cannot recreate its checkpoint")
		else:
			check(current_view(run) == event and run.player_stats.is_running, "Surviving HP cost keeps the event active")
			event.leave_button.pressed.emit()
			check(run.map.visible and SaveGame.load_data().current_health == 1, "Surviving event returns to a resumable map")
		run.queue_free()
		await get_tree().process_frame
		get_tree().paused = false

func _test_legacy_and_failure() -> void:
	var run := new_run()
	await get_tree().process_frame
	var saved := SaveGame.load_data()
	var gold := saved.run_stats.gold
	saved.progression_version = 0
	ResourceSaver.save(saved, SaveGame.SAVE_PATH)
	var migrated := SaveGame.load_data()
	check(migrated != null and migrated.run_stats.act_index == 0 and migrated.run_stats.gold == gold, "Legacy saves preserve the existing Act I map and economy")
	run._on_event_entered()
	run.player_stats.health = 2
	var event := current_view(run) as EventRoom
	event._option_rift_risk()
	await wait_until(func(): return get_tree().paused, "Lethal event presents defeat")
	check(not FileAccess.file_exists(SaveGame.SAVE_PATH) and not run.player_stats.is_running, "Noncombat death terminates the run and clears its save")
	run.queue_free()
	await get_tree().process_frame
	get_tree().paused = false

func _test_bosses() -> void:
	for index in 3:
		var act := ActDefinition.campaign()[index]
		var boss := act.encounters.select(act.boss_tier, [EncounterDefinition.Category.BOSS])
		var relics := RELICS.instantiate() as RelicHandler
		add_child(relics)
		var world := WORLD.instantiate() as GameWorld
		add_child(world)
		world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
		world.run_stats = RunStats.new()
		world.run_stats.act_index = index
		world.battle_stats = boss
		world.relics = relics
		world.start_world()
		await wait_until(func(): return world.player_handler.hand_ready, "Boss hand initializes")
		var primary := world.enemy_handler.get_child(0) as RiftBoss
		check(primary != null, "Each boss has an encounter-defining entity")
		var hud := world.game_world_ui.get_node("BossHealth")
		check(hud.visible and hud.get_node("Layout/Health").value > 0, "Boss health binds authoritative hostiles")
		for enemy: Enemy in world.enemy_handler.get_children():
			check(world.tilemap.is_within_bounds(enemy.current_tile_position), "Boss spawns on surviving terrain")
			check(not world.tilemap.is_tile_free(enemy.current_tile_position), "Boss spawn reserves occupancy")
		if index == 0:
			var route: Array = primary.ram_cells.duplicate()
			for cell in world.tilemap.base_layer.get_surrounding_cells(world.tilemap.player_position):
				if world.tilemap.is_tile_valid(cell):
					world.tilemap.move_player(cell, false)
					break
			check(primary.ram_cells == route, "Movement cannot retarget a committed ram")
			primary._set_recovering(true)
			check(primary.modifier_handler.get_modified_value(6, Enums.ModifierType.DMG_TAKEN) == 9, "Open plating uses the shared modifier used by card previews")
			primary._set_recovering(false)
			check(primary.modifier_handler.get_modified_value(6, Enums.ModifierType.DMG_TAKEN) == 6, "Recovery cleanup removes its exact modifier")
			if not route.is_empty(): world.tilemap.move_player(route[0], false)
			var health := world.player.stats.health
			var origin := primary.current_tile_position
			var action := primary.current_action
			action.perform_action()
			action.cancel_action()
			await get_tree().create_timer(0.35).timeout
			check(world.player.stats.health == health and primary.current_tile_position == origin, "Cancelled ram cannot deal delayed damage or commit movement")
		elif index == 1:
			var attack := load("res://resources/data/cards/riftwalker/arcane_bolt.tres") as Card
			var skill := load("res://resources/data/cards/riftwalker/phase_step.tres") as Card
			for n in 5: primary._hear_card(attack)
			check(primary.chorus == 3, "Chorus is capped")
			primary._hear_card(skill)
			check(primary.chorus == 2, "Nonattack cards quiet the chorus")
		else:
			var relay := primary.active_relay as Enemy
			var before := primary.stats.health
			relay.take_damage(999, Enums.ModifierType.NO_MODIFIER, true)
			await get_tree().create_timer(0.3).timeout
			check(primary.stats.health == before - relay.stats.max_health if is_instance_valid(relay) else primary.stats.health == before - 12, "Relay transfer excludes excess overkill")
			check(primary.current_action.intent.current_text == "Interrupted", "Relay death interrupts the announced discharge")
		if not captures.is_empty() and DisplayServer.get_name() != "headless":
			await get_tree().create_timer(1.4).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(captures.path_join("act-%d.png" % (index + 1)))
		if index == 2:
			primary.take_damage(999, Enums.ModifierType.NO_MODIFIER, true)
			await get_tree().create_timer(0.4).timeout
			check(not world.victory_committed and hud.get_node("Layout/Health").value > 0, "Core-first death cannot imply victory while relays remain")
		var cells := world.tilemap.base_layer.get_used_cells().size()
		await world.tilemap.shrink_map(1)
		check(world.tilemap.base_layer.get_used_cells().size() < cells, "Boss stage uses authoritative tile collapse")
		world.queue_free()
		relics.queue_free()
		await get_tree().process_frame
