# meta-name: Status Logic
# meta-description: Create a Status which effects stats and card effects.
class_name StatusTemplate
extends Status

var member_var := 0

func initialize_status(target: Node) -> void:
	print("Initialize status for targets %s" % target)
	
func apply_status(_target: Node) -> void:
	print("Status not implemented")
	print("This is a template")
	
	status_applied.emit(self)
