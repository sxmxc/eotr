extends Card

const ATTUNEMENT = preload("res://resources/data/statuses/attunement.tres")

@export var base_amount := 1


func get_default_description() -> String:
	return description % base_amount


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var status_effect := StatusEffect.new() as StatusEffect
	var flash_effect := visual_fx.instantiate() as VisualFX
	targets[0].add_child(flash_effect)
	var attunement := ATTUNEMENT.duplicate()
	attunement.stacks = base_amount
	status_effect.status = attunement
	status_effect.sound_fx = sound_fx
	flash_effect.execute()
	status_effect.execute(targets)
