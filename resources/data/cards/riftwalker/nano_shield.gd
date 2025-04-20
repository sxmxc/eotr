extends Card

@export var energy_sound_fx: AudioStream
@export var energy_visual_fx: PackedScene

var base_block := 6
var energy_gain := 3


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	var energy_effect := EnergyEffect.new()
	energy_effect.amount = energy_gain
	energy_effect.sound_fx = energy_sound_fx
	#energy_effect.visual_fx = energy_visual_fx
	block_effect.amount = base_block
	block_effect.sound_fx = sound_fx
	block_effect.visual_fx = visual_fx
	block_effect.execute(targets)
	energy_effect.execute(targets)


func get_default_description() -> String:
	return description % base_block


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description % base_block
