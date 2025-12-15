extends Card

var base_block := 10


func _init() -> void:
	effect_configs = [CardEffectConfig.for_block(base_block)]


func get_default_description() -> String:
	return description % base_block


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	if effect_configs.is_empty():
		return description % base_block
	return description % effect_configs[0].get_effect_amount(_player_modifiers)
