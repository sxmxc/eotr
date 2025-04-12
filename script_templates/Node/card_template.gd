# meta-name: Card Logic
# meta-description: What happens when a card is played
extends Card

@export var optional_sound_fx: AudioStream


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	print("Card logic not implemented")
	print("Targets: %s" % targets)
