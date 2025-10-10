extends Card

func get_default_description() -> String:
	return description

func get_modified_description(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return description

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	# Get the player's discard pile
	var player : Player = [targets][0].get_tree().get_first_node_in_group("player")
	if not player:
		return
	var discard_pile = player.discard_pile if player.has("discard_pile") else null
	if discard_pile and discard_pile.cards.size() > 0:
		var last_card = discard_pile.cards.back()
		if last_card:
			last_card.play([], player.stats, player.modifier_handler)
