extends Card

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	var board := (player.get_parent() as GameWorld).tilemap
	for enemy: Enemy in modifiers.get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_dying and enemy.distance_to_tile(board.player_position, true) <= 1: return false
	return true
