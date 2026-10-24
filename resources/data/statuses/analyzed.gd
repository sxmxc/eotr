class_name AnalyzedStatus
extends Status

func _init() -> void:
	id = "analyzed"
	type = Enums.StatusType.EVENT_BASED
	stack_type = Enums.StatusStackType.INTENSITY
	stacks = 1
	icon = preload("res://assets/rift/ui/analyzed.svg")
	tooltip = "Analyze: +1 damage per stack from direct player and construct hits (maximum 3). Persists until consumed or combat ends."

static func count(target: Node) -> int:
	if not is_instance_valid(target) or not target is Enemy:
		return 0
	var status: Status = target.status_handler._get_status("analyzed")
	return mini(status.stacks, 3) if status else 0

static func consume(target: Node) -> int:
	var amount := count(target)
	if amount > 0:
		target.status_handler.remove_status("analyzed")
	return amount

