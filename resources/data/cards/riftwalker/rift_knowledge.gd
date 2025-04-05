extends Card

const ATTUNED_STATUS = preload("res://resources/data/statuses/attuned.tres")

func apply_effects(targets: Array[Node]) -> void:
	var status_effect = StatusEffect.new()
	var attuned := ATTUNED_STATUS.duplicate()
	status_effect.status = attuned
	status_effect.execute(targets)
