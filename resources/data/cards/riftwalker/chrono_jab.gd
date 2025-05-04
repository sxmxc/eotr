extends Card

const WEAKENED = preload("res://resources/data/statuses/weakened.tres")

@export var base_damage := 6
@export var weakened_duration := 3


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


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = base_damage
	damage_effect.sound_fx = sound_fx
	damage_effect.visual_fx = visual_fx
	damage_effect.execute(targets)
	await targets[0].get_tree().create_timer(.3).timeout
	damage_effect.execute(targets)
	
	var status_effect = StatusEffect.new()
	var weakened := WEAKENED.duplicate()
	weakened.duration = weakened_duration
	status_effect.status = weakened
	status_effect.execute(targets)
	
