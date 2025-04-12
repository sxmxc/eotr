class_name AttunedStatus
extends Status

const ATTUNEMENT_STATUS = preload("res://resources/data/statuses/attunement.tres")

var stacks_per_turn := 1


func apply_status(target: Node) -> void:
	var status_effect := StatusEffect.new()
	var attunement := ATTUNEMENT_STATUS.duplicate()
	attunement.stacks = stacks_per_turn
	status_effect.status = attunement
	status_effect.execute([target])

	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip
