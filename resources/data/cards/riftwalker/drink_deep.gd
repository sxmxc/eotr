extends Card

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var board := modifiers.get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	return board.is_tile_mana_well(board.player_position)
