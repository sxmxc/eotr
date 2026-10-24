extends Card

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	return player.stats.block >= 6

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	stats.block = 0
	await super.resolve_effects(targets, stats, modifiers)
