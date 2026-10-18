extends Card

const ATTUNED_STATUS = preload("res://resources/data/statuses/attuned.tres")

func _init() -> void:
	var attuned := ATTUNED_STATUS.duplicate()
	var status_effect := CardEffectConfig.for_status(attuned)
	status_effect.sound_fx = sound_fx
	status_effect.visual_fx = visual_fx
	status_effect.target = CardEffectConfig.Targeting.PLAYER
	effect_configs = [status_effect]

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass
