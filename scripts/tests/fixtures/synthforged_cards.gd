class_name SynthforgedCardFixture
extends RefCounted
## Development fixture. Supplies authored cards and legal targets to the real UI.
## Never implements card effects. Shared by runtime checks and native captures.
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run(world: GameWorld, capture: Callable = Callable()) -> Array[String]:
	var board := world.tilemap
	var hand := world.player_handler.player_hand
	var origin := board.player_position
	var registry := load("res://resources/data/registries/card_registry_synthforged.tres") as CardRegistry
	var target := world.enemy_handler.get_child(0) as Enemy
	for entry: Dictionary in registry.entries:
		for ui: CardUI in hand.get_cards(): hand.discard_card(ui)
		for unit in world.summons.living(): unit.destroy()
		await world.get_tree().process_frame
		world.player_handler.cancel_turn()
		world.player_handler.hand_ready = true
		board.move_player(origin, false)
		board.hide_fog()
		for cell in board.get_surrounding_tiles_in_radius(origin, 3):
			if board.is_tile_valid(cell): board.tile_map_data[cell].type = Enums.TileType.RESOURCE
		board.set_resource_count(origin, 10)
		for cell in board.base_layer.get_surrounding_cells(origin):
			if board.is_tile_valid(cell) and (board.is_tile_free(cell) or target.current_tile_position == cell):
				target.current_tile_position = cell
				target.global_position = board.cell_to_world(cell)
				break
		target.stats.max_health = 1000
		target.stats.health = 1000
		target.stats.block = 0
		target.status_handler.remove_status("analyzed")
		world.player_stats.block = 0
		world.player_stats.energy = 100
		world.player_stats.fabrication_discount = false
		var card := entry.card.duplicate(true) as SynthforgedCard
		var construct: Construct
		if card.target_type == Enums.TargetType.ALLY or card.id in ["ablative_array", "fortress_protocol"]:
			for cell in board.get_surrounding_tiles_in_radius(origin, 2):
				if world.summons.can_deploy(cell) and SummonHandler.distance(board, cell, target.current_tile_position) == 1:
					construct = world.summons.deploy(load("res://resources/data/constructs/sentry.tres"), cell)
					construct.stats.health = 4
					break
		if card.id in ["precision_shot", "rail_lance", "execution_algorithm"]:
			var analyzed := AnalyzedStatus.new()
			analyzed.stacks = 3
			target.status_handler.add_status(analyzed)
		hand.add_card(card)
		var ui := hand.get_cards().back() as CardUI
		await world.get_tree().process_frame
		# Wait for source movement/old hand tweens, with a bounded fixture budget.
		var movement_deadline := Time.get_ticks_msec() + 3000
		while world.player.pending_effects > 0 and Time.get_ticks_msec() < movement_deadline:
			await world.get_tree().process_frame
		var selected: Array[Node] = []
		var temporary: TilemapTarget
		if card.target_type == Enums.TargetType.ALLY:
			if not construct:
				check(false, "Missing allied target: " + card.id)
				continue
			selected.append(construct)
			if card.id == "redeployment":
				for cell in board.base_layer.get_surrounding_cells(construct.current_tile_position):
					if world.summons.legal_cell(cell):
						temporary = TilemapTarget.new(cell, board)
						world.add_child(temporary)
						selected.append(temporary)
						break
		elif card.target_type == Enums.TargetType.SINGLE_TILE:
			var cells := card.get_valid_targets(ui, world.player.modifier_handler)
			if not cells.is_empty():
				temporary = TilemapTarget.new(cells[0], board)
				world.add_child(temporary)
				selected.append(temporary)
		elif card.is_single_targeted():
			selected.append(target)
		else:
			selected.append(world.player)
		check(ui.can_execute(selected), "Live UI authorization: " + card.id + ("" if ui.can_execute(selected) else " phase=%s ready=%s pending=%d locked=%s resolving=%s selected=%d" % [world.battle_state.phase, world.player_handler.hand_ready, world.player.pending_effects, ui.disabled, is_instance_valid(world.card_interaction.resolving_card), selected.size()] ))
		if not ui.can_execute(selected):
			if temporary: temporary.queue_free()
			continue
		if capture.is_valid(): capture.call(card.id, "before", 0.0)
		world.tilemap.show_target_highlights(card.get_valid_targets(ui, world.player.modifier_handler))
		ui.targets.assign(selected)
		var expected_cost := card.get_energy_cost(world.player_stats)
		if capture.is_valid(): capture.call(card.id, "contact", 0.08)
		await ui.play()
		world.tilemap.clear_target_highlights()
		var draw_deadline := Time.get_ticks_msec() + 3000
		while (not world.player_handler.hand_ready or world.player.pending_effects > 0) and Time.get_ticks_msec() < draw_deadline:
			await world.get_tree().process_frame
		check(world.player_stats.energy == 100 - expected_cost + (2 if card.id == "reserve_capacitor" else 4 if card.id == "reactor_release" else 0), "Exactly one cost: " + card.id)
		check(world.player_stats.exhaust_pile.cards.has(card) if card.exhaust else world.player_stats.discard.cards.has(card), "Correct destination pile: " + card.id)
		match card.id:
			"pulse_rifle": check(target.stats.health == 994, "Pulse Rifle damage")
			"servo_strike": check(target.stats.health == 992, "Servo Strike damage")
			"precision_shot": check(target.stats.health == 985, "Precision Shot condition and Analyze")
			"rail_lance": check(target.stats.health == 976 and AnalyzedStatus.count(target) == 0, "Rail Lance consumed damage")
			"execution_algorithm": check(target.stats.health == 964 and AnalyzedStatus.count(target) == 0, "Execution Algorithm consumed damage")
			"burst_protocol", "saturation_fire": check(target.stats.health == 988, "Three distinct hits: " + card.id)
			"target_scan", "wideband_scan", "threat_assessment": check(AnalyzedStatus.count(target) == 1, "Analyze application: " + card.id)
			"combat_network": check(AnalyzedStatus.count(target) == 3, "Combat Network stacks")
			"field_repairs": check(construct.stats.health == 12, "Field Repairs HP")
			"fire_command": check(target.stats.health == 997, "Fire Command attacks once")
			"reactive_plating": check(world.player_stats.block == 10, "Reactive Plating block")
			"ablative_array": check(world.player_stats.block == 8 and construct.stats.block == 4, "Ablative Array beneficiaries")
			"fortress_protocol": check(world.player_stats.block == 16 and construct.stats.block == 8, "Fortress Protocol beneficiaries")
			"efficient_fabrication": check(world.player_stats.fabrication_discount, "Fabrication arms discount")
			"salvage_probe": check(board.get_resource_count(origin) == 0, "Salvage depletes finite deposit")
		if card.card_type == Enums.CardType.SUMMON:
			check(world.summons.living().size() == 1, "Summon effect: " + card.id)
		if capture.is_valid():
			capture.call(card.id, "recovery", 0.25)
			await world.get_tree().create_timer(0.35).timeout
		if is_instance_valid(temporary): temporary.queue_free()
	return failures
