extends Card

func damaged_count(modifiers: ModifierHandler) -> int:
	var player := modifiers.get_tree().get_first_node_in_group("player") as Player
	var world := player.get_parent() as GameWorld
	var count := 0
	for unit in world.summons.living():
		if unit.stats.health < unit.stats.max_health: count += 1
	return mini(3, count)

func is_valid_target(_targets: Array[Node], modifiers: ModifierHandler) -> bool:
	return damaged_count(modifiers) > 0

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	effect_configs = [CardEffectConfig.for_draw(damaged_count(modifiers))]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)
