extends Card

@export var cards_drawn := 2
@export var energy_gained := 1


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var energy_effect := EnergyEffect.new()
	var draw_effect := DrawEffect.new()
	draw_effect.amount = cards_drawn
	energy_effect.amount = energy_gained
	energy_effect.sound_fx = sound_fx
	energy_effect.visual_fx = visual_fx
	energy_effect.execute(targets)
	draw_effect.execute(targets)
