extends Status
class_name BurnedStatus

var damage_amount = 4
	
func apply_status(target: Node) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage_amount
	damage_effect.execute([target])
	
	status_applied.emit(self)
