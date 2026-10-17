extends Card

const WEAKENED = preload("res://resources/data/statuses/weakened.tres")

@export var base_damage := 6
@export var weakened_duration := 3

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
	var damage_effect := CardEffectConfig.for_multi_damage(base_damage, 2, 0.3)
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	damage_effect.sound_fx = sound_fx
	damage_effect.visual_fx = visual_fx

	var weakened := WEAKENED.duplicate()
	weakened.duration = weakened_duration
	var status_effect := CardEffectConfig.for_status(weakened)
	status_effect.sound_fx = sound_fx
	status_effect.visual_fx = visual_fx

	effect_configs = [damage_effect, status_effect]
