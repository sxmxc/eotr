extends Card

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return not targets.is_empty() and targets[0] is Enemy and targets[0].status_handler._has_status("corroded")

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var enemy := targets[0] as Enemy
	var status := enemy.status_handler._get_status("corroded")
	var block := CardEffectConfig.for_block(mini(16, status.stacks * 4) if status else 0)
	block.target = CardEffectConfig.Targeting.PLAYER
	enemy.status_handler.remove_status("corroded")
	effect_configs = [block]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)
