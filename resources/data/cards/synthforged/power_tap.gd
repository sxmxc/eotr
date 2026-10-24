extends Card

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return not targets.is_empty() and targets[0] is Construct and targets[0].stats.block >= 4

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var block: int = targets[0].stats.block
	targets[0].stats.block = 0
	effect_configs = [CardEffectConfig.for_energy(mini(2, block / 4))]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)
