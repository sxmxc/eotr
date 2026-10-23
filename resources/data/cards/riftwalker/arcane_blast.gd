extends Card

var base_damage = 10


func get_default_description() -> String:
	return description % base_damage


func get_modified_description(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> String:
	if effect_configs.is_empty():
		return description % base_damage
	var effect := effect_configs[0]
	var modified_dmg := effect.get_preview_amount(player_modifiers, enemy_modifiers)
	return description % modified_dmg

func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	if effect_configs.is_empty():
		return false
	var effect := effect_configs[0]
	var modified_dmg := effect.get_effect_amount(player_modifiers)
	return modified_dmg != base_damage


func _sync_effect_configs() -> void:
	var damage_effect: CardEffectConfig
	if effect_configs.is_empty():
		damage_effect = CardEffectConfig.for_damage(base_damage)
		effect_configs = [damage_effect]
	else:
		damage_effect = effect_configs[0]

	damage_effect.amount = base_damage
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, false)
	damage_effect.projectile_mode = CardEffectConfig.ProjectileMode.FIRST_TARGET_ONLY
	damage_effect.camera_shake_strength = 16.0
	damage_effect.camera_shake_duration = 0.15
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
