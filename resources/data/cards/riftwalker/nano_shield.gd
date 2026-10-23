extends Card

@export var energy_sound_fx: AudioStream
@export var energy_visual_fx: PackedScene

var base_block := 6
var energy_gain := 3


func _init() -> void:
	var block_effect := CardEffectConfig.for_block(base_block)
	CardEffectConfigHelper.apply_card_defaults(self, block_effect, true)
	block_effect.target = CardEffectConfig.Targeting.PLAYER

	var energy_effect := CardEffectConfig.for_energy(energy_gain)
	energy_effect.sound_fx = energy_sound_fx
	energy_effect.visual_fx = energy_visual_fx
	energy_effect.target = CardEffectConfig.Targeting.PLAYER

	effect_configs = [block_effect, energy_effect]


func get_default_description() -> String:
	return description % base_block


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description % base_block
