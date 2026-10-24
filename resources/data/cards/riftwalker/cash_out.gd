extends Card

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	return player.status_handler._has_status("attunement")

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	var status := player.status_handler._get_status("attunement")
	var amount := mini(3, status.stacks) if status else 0
	player.status_handler.remove_status("attunement")
	effect_configs = [CardEffectConfig.for_energy(amount)]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)
