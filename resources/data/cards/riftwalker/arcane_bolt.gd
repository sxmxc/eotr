extends Card

var base_damage := 6

func _init() -> void:
	_sync_effect_configs()


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	_sync_effect_configs()
	if targets.is_empty():
		print("[ArcaneBolt] apply_effects called with no targets; skipping.")
		return

	if effect_configs.is_empty():
		print("[ArcaneBolt] effect_configs empty; using direct damage fallback.")
		var damage_effect := DamageEffect.new()
		damage_effect.amount = (
			modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
			if modifiers
			else base_damage
		)
		damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
		damage_effect.sound_fx = sound_fx
		damage_effect.visual_fx = visual_fx
		damage_effect.execute(targets)
		return

	print("[ArcaneBolt] Delegating to CardResolver (%s configs, %s targets)" % [effect_configs.size(), targets.size()])
	var resolver := CardResolver.new()
	await resolver.resolve(self, targets, null, modifiers, effect_configs)


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
	# Ensure a damage config exists and carries visuals/shake.
	if effect_configs.is_empty():
		effect_configs = [CardEffectConfig.for_damage(base_damage)]
	var damage_effect := effect_configs[0]
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, false)
	damage_effect.camera_shake_strength = 16.0
	damage_effect.camera_shake_duration = 0.15
	damage_effect.amount = base_damage
	for config in effect_configs:
		config.effect_type = CardEffectConfig.EffectType.DAMAGE
		config.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
