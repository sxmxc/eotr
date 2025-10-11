extends Card

func get_default_description() -> String:
	return description

func get_modified_description(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return description

func apply_effects(_targets: Array[Node], modifiers: ModifierHandler) -> void:
	var tree := modifiers.get_tree()
	if not tree:
		return
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler
	if not player_handler:
		return
	var player_hand := player_handler.player_hand
	if not player_hand:
		return
	var player_stats := player_handler.player_stats
	if not player_stats:
		return
	var discard_pile := player_stats.discard
	if not discard_pile:
		return
	var cards := discard_pile.cards
	if cards.size() <= 1:
		return
	# The card that triggered this effect (Echo) has already been added to discard, so use the previous entry.
	var previous_card := cards[cards.size() - 2]
	if not previous_card:
		return
	var echoed_card := previous_card.duplicate() as Card
	if not echoed_card:
		return
	echoed_card.energy_cost = 0
	echoed_card.exhaust = true
	player_hand.add_card(echoed_card)
