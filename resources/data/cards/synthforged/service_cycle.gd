extends Card

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return not targets.is_empty() and targets[0] is Construct and targets[0].stats.health < targets[0].stats.max_health
