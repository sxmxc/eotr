extends Status
class_name StatusNamePlaceHolderClassName

var member_var := 0

func initialize_status(target: Node) -> void:
	print("Initialize status for targets %s" % target)
	
func apply_status(target: Node) -> void:
	print("Status not implemented")
	print("This is a template")
	
	status_applied.emit(self)
