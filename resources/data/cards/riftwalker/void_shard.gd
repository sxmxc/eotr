extends Card

var base_damage := 6

func _init() -> void:
	_sync_effect_configs()


func get_default_description() -> String:
	return description % base_damage


func get_modified_description(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> String:
	var modified_dmg := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)

	if enemy_modifiers:
		modified_dmg = enemy_modifiers.get_modified_value(
			modified_dmg, Enums.ModifierType.DMG_TAKEN
		)

	return description % modified_dmg
	
func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	var modified_dmg := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)
	if modified_dmg != base_damage:
		return true
	return false


func _sync_effect_configs() -> void:
	if effect_configs.is_empty():
		var damage_effect := CardEffectConfig.for_damage(base_damage)
		damage_effect.camera_shake_strength = 16.0
		damage_effect.camera_shake_duration = 0.15
		damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
		effect_configs = [damage_effect]
	var damage_effect := effect_configs[0]
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, false)
	damage_effect.amount = base_damage
