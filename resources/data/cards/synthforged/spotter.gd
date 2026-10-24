extends Card

func coverage(enemy: Enemy) -> int:
	var world := enemy.tilemap.get_parent() as GameWorld
	var count := 0
	for unit in world.summons.living():
		if enemy.distance_to_tile(unit.current_tile_position, true) <= unit.definition.attack_range: count += 1
	return mini(3, count)

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return not targets.is_empty() and targets[0] is Enemy and coverage(targets[0]) > 0

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	var status := AnalyzedStatus.new()
	status.stacks = coverage(targets[0])
	effect_configs = [CardEffectConfig.for_status(status)]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)
