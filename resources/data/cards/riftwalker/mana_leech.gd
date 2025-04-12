extends Card

const WEAKENED = preload("res://resources/data/statuses/weakened.tres")


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var status_effect = StatusEffect.new()
	var weakened := WEAKENED.duplicate()
	status_effect.status = weakened
	status_effect.execute(targets)
