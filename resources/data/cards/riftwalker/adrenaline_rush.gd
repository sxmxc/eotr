extends Card

@export var cards_drawn := 2
@export var energy_gained := 1


func _init() -> void:
	_sync_effect_configs()


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description


func _sync_effect_configs() -> void:
	var energy_effect := CardEffectConfig.for_energy(energy_gained)
	energy_effect.target = CardEffectConfig.Targeting.PLAYER
	var draw_effect := CardEffectConfig.for_draw(cards_drawn)
	draw_effect.target = CardEffectConfig.Targeting.PLAYER
	effect_configs = [energy_effect, draw_effect]
