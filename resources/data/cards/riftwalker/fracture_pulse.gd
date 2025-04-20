extends Card

var base_damage := 4
var energy_gain := 4

@export var energy_sound_fx : AudioStream
@export var energy_visual_fx : PackedScene


func apply_effects(targets: Array[Node], modifiers: ModifierHandler) -> void:
	var damage_effect := DamageEffect.new()
	var energy_effect := EnergyEffect.new()
	var player_array := targets[0].get_tree().get_nodes_in_group("player")
	energy_effect.amount = energy_gain
	energy_effect.sound_fx = energy_sound_fx
	#energy_effect.visual_fx = energy_visual_fx
	damage_effect.amount = modifiers.get_modified_value(base_damage, Enums.ModifierType.DMG_DEALT)
	damage_effect.sound_fx = sound_fx
	damage_effect.execute(targets)
	energy_effect.execute(player_array)
	#for enemy: Enemy in targets:
		#var explosion : VisualFX = visual_fx.instantiate() as VisualFX
		#enemy.add_child(explosion)
		#explosion.execute()


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
