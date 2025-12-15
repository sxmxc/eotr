extends Card

const CORRODED_STATUS = preload("res://resources/data/statuses/corroded.tres")

var base_damage := 4
var corrode_stacks := 1


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	if targets.is_empty():
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx
	damage_effect.visual_fx = visual_fx
	damage_effect.execute(targets)

	var status_effect := StatusEffect.new()
	var corroded := CORRODED_STATUS.duplicate()
	corroded.stacks = corrode_stacks
	status_effect.status = corroded
	status_effect.execute(targets)


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
