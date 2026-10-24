extends Card

func previous_skill(stats: PlayerStats) -> Card:
	for index in range(stats.discard.cards.size() - 1, -1, -1):
		var previous := stats.discard.cards[index]
		if previous.id != id and previous.card_type == Enums.CardType.SKILL: return previous
	return null

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	return previous_skill(player.stats) != null

func resolve_effects(_targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var previous := previous_skill(stats)
	var handler := modifiers.get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if previous and stats.discard.remove_card(previous): handler.player_hand.add_card(previous)
