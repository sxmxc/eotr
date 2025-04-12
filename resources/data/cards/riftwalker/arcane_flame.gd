extends Card

const BURNED_STATUS = preload("res://resources/data/statuses/burned.tres")

var base_damage := 4
var burn_duration := 2


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect = DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx
	damage_effect.execute(targets)

	var status_effect = StatusEffect.new()
	var burned := BURNED_STATUS.duplicate()
	burned.duration = burn_duration
	status_effect.status = burned
	status_effect.execute(targets)


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
