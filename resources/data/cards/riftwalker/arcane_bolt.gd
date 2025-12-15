extends Card

var base_damage := 6

func _init() -> void:
	var damage_effect := CardEffectConfig.for_damage(base_damage)
	damage_effect.attach_visual_to_effect = false
	damage_effect.projectile_fx = projectile_fx
	damage_effect.projectile_visual_fx = visual_fx
	damage_effect.camera_shake_strength = 16.0
	damage_effect.camera_shake_duration = 0.15
	effect_configs = [damage_effect]


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
