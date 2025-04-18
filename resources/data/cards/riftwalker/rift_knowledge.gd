extends Card

const ATTUNED_STATUS = preload("res://resources/data/statuses/attuned.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var status_effect := StatusEffect.new() as StatusEffect
	var flash_effect := visual_fx.instantiate() as VisualFX
	targets[0].add_child(flash_effect)
	var attuned := ATTUNED_STATUS.duplicate()
	status_effect.status = attuned
	status_effect.sound_fx = sound_fx
	flash_effect.execute()
	status_effect.execute(targets)
