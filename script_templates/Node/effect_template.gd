# meta-name: Effect
# meta-description: Create an effect which can be applied to a target
extends Effect
class_name SomeAwesomeEffect

var member_var := 0

func execute(targets: Array[Node]) -> void:
	print("Effect logic not implemented")
