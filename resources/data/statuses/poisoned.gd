extends Status
class_name PoisonedStatus

var damage_amount = 3


func apply_status(target: Node) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage_amount
	damage_effect.execute([target])

	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip % duration
