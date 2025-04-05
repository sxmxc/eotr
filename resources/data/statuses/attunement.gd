extends Status
class_name AttunementStatus

func initialize_status(_target: Node) -> void:
	status_changed.connect(_on_status_changed)
	_on_status_changed()	
	

func _on_status_changed() -> void:
	print("Attunement status: +%s damage" % stacks)
