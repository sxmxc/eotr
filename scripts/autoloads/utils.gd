extends Node

func _ready() -> void:
	await get_tree().root.ready
	print("Utils creating SignalPrinter and attaching to Eventbus")
	var signal_printer = SignalPrinter.new()
	add_child(signal_printer)
	print("Utils ready")

func get_node_global_center(node: Node) -> Vector2:
	return node.global_position + node.size * 0.5
	
func get_control_global_center(control: Control) -> Vector2:
	var rect := control.get_global_rect()
	return rect.position + rect.size * 0.5	
	
func shake(thing: Node2D, strength: float, duration: float = 0.2) -> void:
	if not thing:
		return

	var orig_pos := thing.global_position
	var shake_count := 10
	var tween := create_tween()

	for i in shake_count:
		var shake_offset := Vector2(
			RNG.instance.randf_range(-1.0, 1.0), RNG.instance.randf_range(-1.0, 1.0)
		)
		var target := orig_pos + strength * shake_offset
		if i % 2 == 0:
			target = orig_pos
		tween.tween_property(thing, "position", target, duration / float(shake_count))
		strength *= 0.75
	
	#bug fix for when player dies	
	var lambda = func():
			if is_instance_valid(thing):
				thing.global_position = orig_pos
	
	thing.tree_exiting.connect(
		func():
			tween.finished.disconnect(lambda)
	)

	tween.finished.connect(lambda)
