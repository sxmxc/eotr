extends Card

@export var node_fx_scene : PackedScene
var base_block := 10


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = base_block
	block_effect.sound_fx = sound_fx
	block_effect.visual_fx = node_fx_scene
	block_effect.execute(targets)


func get_default_description() -> String:
	return description % base_block


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description % base_block
