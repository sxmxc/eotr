extends Card

const CORRODED_STATUS = preload("res://resources/data/statuses/corroded.tres")

var base_damage := 6
var corrode_stacks := 2


func _init() -> void:
	var damage_effect := CardEffectConfig.for_damage(base_damage)
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, true)

	var corroded := CORRODED_STATUS.duplicate()
	corroded.stacks = corrode_stacks
	var status_effect := CardEffectConfig.for_status(corroded)
	CardEffectConfigHelper.apply_card_defaults(self, status_effect, true)

	effect_configs = [damage_effect, status_effect]


func get_default_description() -> String:
	return description % [base_damage, corrode_stacks]


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

	return description % [modified_dmg, corrode_stacks]


func is_card_modified(player_modifiers: ModifierHandler) -> bool:
	var modified_dmg := player_modifiers.get_modified_value(
		base_damage, Enums.ModifierType.DMG_DEALT
	)
	return modified_dmg != base_damage
