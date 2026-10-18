extends Card

var base_damage := 4
var energy_gain := 4

@export var energy_sound_fx : AudioStream
@export var energy_visual_fx : PackedScene

func _init() -> void:
	var damage_effect := CardEffectConfig.for_damage(base_damage)
	damage_effect.receiver_modifier_type = Enums.ModifierType.DMG_TAKEN
	damage_effect.sound_fx = sound_fx
	damage_effect.visual_fx = visual_fx

	var energy_effect := CardEffectConfig.for_energy(energy_gain)
	energy_effect.sound_fx = energy_sound_fx
	energy_effect.visual_fx = energy_visual_fx
	energy_effect.target = CardEffectConfig.Targeting.PLAYER

	effect_configs = [damage_effect, energy_effect]

func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	pass



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
