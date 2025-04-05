extends Status
class_name WeakenedStatus

const MODIFIER := 0.5
	
func apply_status(target: Node) -> void:
	print("%s should take %s%% more damage!" % [target, MODIFIER * 100])
	
	var damage_effect := DamageEffect.new()
	damage_effect.amount = 3
	damage_effect.execute([target])
	
	status_applied.emit(self)
