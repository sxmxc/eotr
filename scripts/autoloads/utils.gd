extends Node

func _ready() -> void:
	var signal_printer = SignalPrinter.new()
	add_child(signal_printer)

func get_node_global_center(node: Node) -> Vector2:
	return node.global_position + node.size * 0.5
	
func get_control_global_center(control: Control) -> Vector2:
	var rect := control.get_global_rect()
	return rect.position + rect.size * 0.5	
