extends Node

var _hitstop_scales: Array[float] = []
var _hitstop_baseline: float = 1.0

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
	
func apply_hitstop(target_scale: float, duration: float) -> void:
	if duration <= 0.0:
		return

	target_scale = clamp(target_scale, 0.05, 1.0)
	if _hitstop_scales.is_empty():
		_hitstop_baseline = Engine.time_scale

	_hitstop_scales.append(target_scale)
	_set_time_scale_to_active_min()

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = duration
	timer.ignore_time_scale = true
	add_child(timer)
	timer.timeout.connect(
		func():
			_hitstop_scales.erase(target_scale)
			if _hitstop_scales.is_empty():
				Engine.time_scale = _hitstop_baseline
			else:
				_set_time_scale_to_active_min()
			timer.queue_free()
	)
	timer.start()
	
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


func _set_time_scale_to_active_min() -> void:
	var min_scale := _hitstop_baseline
	for scale in _hitstop_scales:
		min_scale = minf(min_scale, scale)
	Engine.time_scale = min_scale
