extends Card

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var board := modifiers.get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	return board.get_tile_data(board.player_position).type == Enums.TileType.RESOURCE and board.get_resource_count(board.player_position) > 0

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var board := modifiers.get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	board.set_resource_count(board.player_position, 0)
	effect_configs = [CardEffectConfig.for_energy(2)]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)
