class_name BuffedStatus
extends Status

const STRENGTH_STATUS = preload("res://resources/data/statuses/strength.tres")

var stacks_per_turn := 1


func apply_status(target: Node) -> void:
	var status_effect := StatusEffect.new()
	var strength := STRENGTH_STATUS.duplicate()
	strength.stacks = stacks_per_turn
	status_effect.status = strength
	status_effect.execute([target])

	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip
