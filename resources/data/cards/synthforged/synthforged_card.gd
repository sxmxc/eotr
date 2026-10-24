class_name SynthforgedCard
extends Card

@export var construct: ConstructDefinition

func get_energy_cost(stats: PlayerStats) -> int:
	return maxi(0, energy_cost - (1 if stats and stats.fabrication_discount and card_type == Enums.CardType.SUMMON else 0))

func play(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	await super.play(targets, stats, modifiers)
	if card_type == Enums.CardType.SUMMON:
		stats.fabrication_discount = false

func _config(kind: CardEffectConfig.EffectType, amount := 0, recipient := CardEffectConfig.Targeting.CARD_TARGETS) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = kind
	config.amount = amount
	config.target = recipient
	return config

func _sync_effect_configs() -> void:
	var player := CardEffectConfig.Targeting.PLAYER
	var allies := CardEffectConfig.Targeting.CONSTRUCTS
	var enemies := CardEffectConfig.Targeting.VISIBLE_ENEMIES
	var adjacent := CardEffectConfig.Targeting.ADJACENT_ENEMIES
	match id:
		"pulse_rifle": effect_configs = [CardEffectConfig.for_damage(6)]
		"servo_strike": effect_configs = [CardEffectConfig.for_damage(8)]
		"reactive_plating": effect_configs = [CardEffectConfig.for_block(10)]
		"vector_boost": effect_configs = [CardEffectConfig.for_move()]
		"salvage_probe": effect_configs = [CardEffectConfig.for_gather()]
		"target_scan": effect_configs = [_analyze(1), CardEffectConfig.for_draw(1)]
		"deploy_sentry", "deploy_pike", "deploy_bastion", "deploy_siege_platform":
			var summon := _config(CardEffectConfig.EffectType.SUMMON)
			summon.construct = construct
			effect_configs = [summon]
		"precision_shot":
			var damage := CardEffectConfig.for_damage(8)
			damage.analyzed_bonus = 4
			effect_configs = [damage]
		"tactical_cache": effect_configs = [CardEffectConfig.for_draw(2)]
		"reserve_capacitor": effect_configs = [CardEffectConfig.for_energy(2)]
		"threat_assessment": effect_configs = [_config(CardEffectConfig.EffectType.BLOCK, 6, player), _analyze(1, adjacent)]
		"rail_lance", "execution_algorithm":
			var damage := CardEffectConfig.for_damage(12 if id == "rail_lance" else 18)
			damage.consume_analyze = 4 if id == "rail_lance" else 6
			effect_configs = [damage]
		"burst_protocol", "saturation_fire":
			var damage := CardEffectConfig.for_multi_damage(4, 3, 0.12)
			if id == "saturation_fire": damage.target = enemies
			effect_configs = [damage]
		"ablative_array", "fortress_protocol":
			var heavy := id == "fortress_protocol"
			effect_configs = [_config(CardEffectConfig.EffectType.BLOCK, 16 if heavy else 8, player), _config(CardEffectConfig.EffectType.BLOCK, 8 if heavy else 4, allies)]
		"wideband_scan": effect_configs = [_analyze(1, enemies)]
		"field_repairs": effect_configs = [_config(CardEffectConfig.EffectType.REPAIR, 8), CardEffectConfig.for_draw(1)]
		"fire_command": effect_configs = [_config(CardEffectConfig.EffectType.COMMAND)]
		"thruster_assault": effect_configs = [CardEffectConfig.for_move(), _config(CardEffectConfig.EffectType.BLOCK, 6, player)]
		"redeployment": effect_configs = [_config(CardEffectConfig.EffectType.RELOCATE)]
		"efficient_fabrication": effect_configs = [CardEffectConfig.for_draw(1), _config(CardEffectConfig.EffectType.FABRICATE)]
		"reactor_release": effect_configs = [CardEffectConfig.for_energy(4)]
		"combat_network": effect_configs = [_analyze(3, enemies), CardEffectConfig.for_draw(2)]
	if id == "reactive_plating": effect_configs[0].target = player
	if id == "threat_assessment": effect_configs[0].visual_fx = preload("res://ui/fx/synthforged/reactive_plating.tscn")
	for config in effect_configs:
		CardEffectConfigHelper.apply_card_defaults(self, config, true)

func _analyze(amount: int, recipient := CardEffectConfig.Targeting.CARD_TARGETS) -> CardEffectConfig:
	var status := AnalyzedStatus.new()
	status.stacks = amount
	var config := CardEffectConfig.for_status(status)
	config.target = recipient
	return config

func get_valid_targets(ui: CardUI, modifiers: ModifierHandler) -> Array[Vector2i]:
	var board := ui.get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	var world := board.get_parent() as GameWorld
	var cells: Array[Vector2i] = []
	if card_type == Enums.CardType.SUMMON:
		for cell in board.get_surrounding_tiles_in_radius(board.player_position, 2):
			if world.summons.can_deploy(cell): cells.append(cell)
		return cells
	if target_type == Enums.TargetType.ALLY:
		var selected: Construct = ui.interaction_controller.relocation_unit if ui.interaction_controller else null
		if id == "redeployment" and is_instance_valid(selected) and ui.interaction_controller.active_card == ui:
			for cell in board.base_layer.get_surrounding_cells(selected.current_tile_position):
				if world.summons.legal_cell(cell): cells.append(cell)
		else:
			for unit in world.summons.living(): cells.append(unit.current_tile_position)
		return cells
	if id in ["vector_boost", "thruster_assault"]:
		var movement := preload("res://resources/data/cards/riftwalker/phase_step.gd").new()
		movement.movement_distance = 2
		for cell in movement.get_valid_targets(ui, modifiers):
			if board.is_tile_free(cell): cells.append(cell)
		return cells
	if id == "salvage_probe":
		if board.get_resource_count(board.player_position) > 0: cells.append(board.player_position)
		return cells
	return super.get_valid_targets(ui, modifiers)

func is_valid_target(targets: Array[Node], modifiers: ModifierHandler) -> bool:
	if targets.is_empty(): return false
	if target_type == Enums.TargetType.ALLY:
		if not targets[0] is Construct or targets[0].is_dying: return false
		if id == "redeployment":
			if targets.size() == 1: return true
			if not targets[1] is TilemapTarget: return false
			var unit := targets[0] as Construct
			var destination := targets[1] as TilemapTarget
			var handler := unit.get_parent() as SummonHandler
			return destination.tilemap == unit.tilemap and handler.legal_cell(destination.tile_position) \
				and SummonHandler.distance(unit.tilemap, unit.current_tile_position, destination.tile_position) == 1
		return true
	if target_type == Enums.TargetType.SINGLE_TILE:
		if not targets[0] is TilemapTarget: return false
		var tile := targets[0] as TilemapTarget
		var world := tile.tilemap.get_parent() as GameWorld
		if card_type == Enums.CardType.SUMMON: return world.summons.can_deploy(tile.tile_position)
		if id == "salvage_probe": return tile.tile_position == tile.tilemap.player_position and tile.tilemap.get_resource_count(tile.tile_position) > 0
		var max_distance := modifiers.get_modified_value(2, Enums.ModifierType.MOVEMENT) if modifiers else 2
		return tile.tilemap.is_tile_free(tile.tile_position) and not tile.tilemap.is_tile_corrupt(tile.tile_position) \
			and SummonHandler.distance(tile.tilemap, tile.tilemap.player_position, tile.tile_position) <= max_distance
	return true

func get_modified_description(player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	_sync_effect_configs()
	var text := description
	if id in ["vector_boost", "thruster_assault"] and player_modifiers:
		return text.replace("2 hexes", "%d hexes" % player_modifiers.get_modified_value(2, Enums.ModifierType.MOVEMENT))
	for config in effect_configs:
		if config.effect_type in [CardEffectConfig.EffectType.DAMAGE, CardEffectConfig.EffectType.MULTI_DAMAGE]:
			return text.replace("Deal %d" % config.amount, "Deal %d" % config.get_preview_amount(player_modifiers, enemy_modifiers))
	return text

func is_card_modified(modifiers: ModifierHandler) -> bool:
	if not modifiers: return false
	if id in ["vector_boost", "thruster_assault"]:
		return modifiers.get_modified_value(2, Enums.ModifierType.MOVEMENT) != 2
	_sync_effect_configs()
	for config in effect_configs:
		if config.effect_type in [CardEffectConfig.EffectType.DAMAGE, CardEffectConfig.EffectType.MULTI_DAMAGE] and config.get_effect_amount(modifiers) != config.amount:
			return true
	return false

