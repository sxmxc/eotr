extends Card

var base_amount := 1


func _init() -> void:
	var energy_effect := CardEffectConfig.for_energy(base_amount)
	energy_effect.sound_fx = sound_fx
	energy_effect.target = CardEffectConfig.Targeting.PLAYER
	effect_configs = [energy_effect]


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_default_description() -> String:
	return description % base_amount


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description % base_amount
