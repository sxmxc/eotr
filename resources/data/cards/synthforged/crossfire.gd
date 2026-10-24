extends Card

func coverage(enemy: Enemy) -> int:
	var world := enemy.tilemap.get_parent() as GameWorld
	var count := 0
	for unit in world.summons.living():
		if enemy.distance_to_tile(unit.current_tile_position, true) <= unit.definition.attack_range: count += 1
	return count

func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	return not targets.is_empty() and targets[0] is Enemy and coverage(targets[0]) > 0

func resolve_effects(targets: Array[Node], stats: PlayerStats, modifiers: ModifierHandler) -> void:
	effect_configs = [CardEffectConfig.for_multi_damage(3, coverage(targets[0]), 0.12)]
	_sync_effect_configs()
	await super.resolve_effects(targets, stats, modifiers)

func get_modified_description(modifiers: ModifierHandler, enemy_modifiers: ModifierHandler) -> String:
	return description.replace("Deal 3", "Deal %d" % CardEffectConfig.for_damage(3).get_preview_amount(modifiers, enemy_modifiers))

func is_card_modified(modifiers: ModifierHandler) -> bool:
	return modifiers != null and modifiers.get_modified_value(3, Enums.ModifierType.DMG_DEALT) != 3
