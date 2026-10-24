class_name ExpansionCardFixture
extends RefCounted
## Controlled setup only; every effect is played through the real CardUI path.
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func settle(world: GameWorld) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline:
		var pending := world.player.pending_effects
		for enemy: Enemy in world.enemy_handler.get_children(): pending += enemy.pending_damage
		if pending == 0 and world.player_handler.hand_ready: return
		await world.get_tree().process_frame
	check(false, "Tactical card effects settle within four seconds")

func run(world: GameWorld, capture: Callable = Callable()) -> Array[String]:
	var board := world.tilemap
	var hand := world.player_handler.player_hand
	var origin := board.player_position
	var target := world.enemy_handler.get_child(0) as Enemy
	for enemy: Enemy in world.enemy_handler.get_children():
		if enemy != target: enemy.queue_free()
	await world.get_tree().process_frame
	for entry: Dictionary in RegistryData.card_registry.entries:
		if not entry.card.tags.has("expansion"): continue
		if not str(entry.class_id).is_empty() and entry.class_id != world.player_stats.player_class_name: continue
		for old: CardUI in hand.get_cards(): hand.discard_card(old)
		world.summons.reset()
		await world.get_tree().process_frame
		world.player_handler.cancel_turn()
		world.player_handler.hand_ready = true
		world.player_handler.free_movement_refund_available = false
		world.player_handler.card_types_played.clear()
		board.move_player(origin, false)
		board.hide_fog()
		for cell in board.get_tiles_in_range(origin, 3):
			if board.is_within_bounds(cell): board.change_terrain(cell, Enums.TileType.RESOURCE)
		board.set_resource_count(origin, 10)
		for cell in board.get_tiles_in_range(origin, 2):
			if SummonHandler.distance(board, origin, cell) == 2 and board.is_tile_valid(cell):
				target.current_tile_position = cell
				target.global_position = board.cell_to_world(cell)
				break
		target.stats.max_health = 1000
		target.stats.health = 1000
		target.stats.block = 0
		for status_id in ["analyzed", "corroded"]: target.status_handler.remove_status(status_id)
		for status_id in ["attunement", "weakened"]: world.player.status_handler.remove_status(status_id)
		world.player_stats.energy = 100
		world.player_stats.block = 0
		world.player_stats.health = world.player_stats.max_health - 8
		world.run_stats.gold = 100
		world.player_stats.draw_pile.clear()
		world.player_stats.discard.clear()
		for index in 12: world.player_stats.draw_pile.add_card(load("res://resources/data/cards/riftwalker/arcane_bolt.tres").duplicate())
		var card := entry.card.duplicate(true) as Card
		var units: Array[Construct] = []
		if entry.class_id == "Synthforged":
			for cell in board.get_tiles_in_range(origin, 2):
				if not world.summons.can_deploy(cell): continue
				if not units.is_empty() and SummonHandler.distance(board, units[0].current_tile_position, cell) != 1: continue
				var unit := world.summons.deploy(load("res://resources/data/constructs/sentry.tres"), cell)
				unit.stats.health = 4
				unit.stats.block = 8
				units.append(unit)
				if units.size() == 2: break
			check(units.size() == 2, "Two coordinated constructs available: " + card.id)
		match card.id:
			"drink_deep": board.change_terrain(origin, Enums.TileType.MANA_WELL)
			"afterimage": world.player_handler.card_types_played.append(Enums.CardType.MOVEMENT)
			"cash_out":
				var status := load("res://resources/data/statuses/attunement.tres").duplicate() as Status
				status.stacks = 3
				world.player.status_handler.add_status(status)
			"backwash":
				var status := load("res://resources/data/statuses/corroded.tres").duplicate() as Status
				status.stacks = 2
				target.status_handler.add_status(status)
			"second_thought": world.player_stats.discard.add_card(load("res://resources/data/cards/riftwalker/focus.tres").duplicate())
			"unbuckle": world.player_stats.block = 6
		hand.add_card(card)
		var ui := hand.get_cards().back() as CardUI
		await world.get_tree().process_frame
		await settle(world)
		var selected: Array[Node] = [world.player]
		var tile: TilemapTarget
		if card.card_type == Enums.CardType.MOVEMENT:
			var cells := card.get_valid_targets(ui, world.player.modifier_handler)
			if not cells.is_empty():
				tile = TilemapTarget.new(cells[0], board)
				world.add_child(tile)
				selected.assign([tile])
		elif card.target_type == Enums.TargetType.ALLY and not units.is_empty(): selected.assign([units[0]])
		elif card.target_type == Enums.TargetType.SINGLE_ENEMY: selected.assign([target])
		check(ui.can_execute(selected), "Live authorization: " + card.id)
		if not ui.can_execute(selected):
			if tile: tile.queue_free()
			continue
		if capture.is_valid(): await capture.call(card.id, "before", 0.0)
		board.show_target_highlights(world.card_interaction.valid_cells(ui))
		ui.targets.assign(selected)
		await ui.play()
		await settle(world)
		var generated_energy := 3 if card.id == "cash_out" else 2 if card.id in ["borrowed_spark", "scrap_order", "power_tap", "strip_supplies"] else 0
		check(world.player_stats.energy == 100 - card.energy_cost + generated_energy, "One payment and bounded energy: " + card.id)
		check(world.player_stats.exhaust_pile.cards.has(card) if card.exhaust else world.player_stats.discard.cards.has(card), "Correct card destination: " + card.id)
		if card.card_type == Enums.CardType.MOVEMENT and tile:
			check(board.player_position == tile.tile_position and not board.is_tile_free(tile.tile_position), "Movement updates real occupancy: " + card.id)
		match card.id:
			"slipstream": check(hand.get_cards().size() == 1, "Slipstream replaces itself")
			"grounding_step": check(status_count(world.player.status_handler, "attunement") == 1, "Grounding grants Attunement")
			"drink_deep": check(status_count(world.player.status_handler, "attunement") == 2 and hand.get_cards().size() == 1, "Mana well payoff")
			"afterimage": check(world.player_stats.block == 11, "Movement-conditioned defense")
			"cash_out": check(status_count(world.player.status_handler, "attunement") == 0, "Cash Out consumes all scaling")
			"borrowed_spark": check(world.player.status_handler._has_status("weakened"), "Borrowed Spark exposes player")
			"second_thought": check(hand.get_cards().size() == 1 and hand.get_cards()[0].card.id == "focus" and hand.get_cards()[0].card.energy_cost == 1, "Recall transfers actual normal-cost skill")
			"backwash": check(world.player_stats.block == 8 and not target.status_handler._has_status("corroded"), "Corrosion traded for block")
			"scrap_order": check((not is_instance_valid(units[0]) or units[0].is_dying) and world.summons.living().size() == 1, "Dismantle frees a deployment slot")
			"service_cycle": check(units[0].stats.health == 8 and target.stats.health == 997, "Repair then one real activation")
			"crossfire": check(target.stats.health == 994, "Two coverage hits, once per covering construct")
			"spotter": check(AnalyzedStatus.count(target) == 2, "Coverage provides two Analyze")
			"relay_orders": check(target.stats.health == 994, "Adjacent cluster attacks once each")
			"power_tap": check(units[0].stats.block == 0, "Power Tap consumes all construct defense")
			"maintenance_window": check(hand.get_cards().size() == 2, "Damaged constructs provide two draws")
			"sure_footing": check(world.player_stats.block == 4, "Sure Footing defense")
			"keep_distance": check(world.player_stats.block == 12, "Space permits defense")
			"travel_light": check(hand.get_cards().size() == 2, "Travel Light draws two")
			"unbuckle": check(world.player_stats.block == 0 and hand.get_cards().size() == 2, "Defense traded for draw")
			"strip_supplies": check(board.get_resource_count(origin) == 0 and world.run_stats.resources >= 0, "Deposit destroyed for energy")
			"reserve_rations": check(world.run_stats.gold == 92 and world.player_stats.health == world.player_stats.max_health - 4, "Gold paid once for real healing")
		if capture.is_valid(): await capture.call(card.id, "recovery", 0.15)
		board.clear_target_highlights()
		if is_instance_valid(tile): tile.queue_free()
	return failures

func status_count(handler: StatusHandler, status_id: String) -> int:
	var status := handler._get_status(status_id)
	return status.stacks if status else 0
