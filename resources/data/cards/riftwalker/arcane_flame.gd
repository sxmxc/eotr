extends Card

const BURNED_STATUS = preload("res://resources/data/statuses/burned.tres")

var base_damage := 4
var burn_duration := 2

func _init() -> void:
	var damage_effect := CardEffectConfig.for_damage(base_damage)
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	CardEffectConfigHelper.apply_card_defaults(self, damage_effect, true)

	var burned := BURNED_STATUS.duplicate()
	burned.duration = burn_duration
	var status_effect := CardEffectConfig.for_status(burned)
	CardEffectConfigHelper.apply_card_defaults(self, status_effect, true)

	effect_configs = [damage_effect, status_effect]


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
