extends Card

var base_amount := 1


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var energy_effect := EnergyEffect.new()
	energy_effect.amount = base_amount
	energy_effect.sound_fx = sound_fx
	energy_effect.execute(targets)


func get_default_description() -> String:
	return description % base_amount


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description % base_amount
