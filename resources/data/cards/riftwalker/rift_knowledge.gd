extends Card

const ATTUNED_STATUS = preload("res://resources/data/statuses/attuned.tres")

func _init() -> void:
	var attuned := ATTUNED_STATUS.duplicate()
	var status_effect := CardEffectConfig.for_status(attuned)
	CardEffectConfigHelper.apply_card_defaults(self, status_effect, true)
	status_effect.target = CardEffectConfig.Targeting.PLAYER
	effect_configs = [status_effect]

func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass
