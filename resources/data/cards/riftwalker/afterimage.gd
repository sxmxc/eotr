extends Card

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var handler := modifiers.get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	effect_configs[0].amount = 11 if handler.card_types_played.has(Enums.CardType.MOVEMENT) else 5
	await super.resolve_effects(targets, stats, modifiers)
