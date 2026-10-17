class_name ElectricArcFX
extends Line2D

signal complete
signal line_drawn

func strike(target: Node2D = null) -> bool:
	var start := global_position
	var end := start

	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player:
		start = player.global_position
	else:
		var start_anchor := get_tree().get_first_node_in_group("projectile_start")
		if start_anchor is Node2D:
			start = (start_anchor as Node2D).global_position
		elif start_anchor is Control:
			start = (start_anchor as Control).global_position

	# Prefer the actual target; fall back to a projectile_start anchor.
	if target and target is Node2D:
		end = (target as Node2D).global_position
	else:
		var projectile_start := get_tree().get_first_node_in_group("projectile_start")
		if projectile_start and projectile_start.has_method("get_global_mouse_position"):
			end = projectile_start.get_global_mouse_position()
		else:
			return false

	print("bolt striking: start %s end %s" % [start, end])
	var cam = get_tree().get_first_node_in_group("map_camera")
	if cam:
		Utils.shake(cam, 20)
	points = _get_points(start, end)
	var tween = create_tween()
	# Ensure the arc draws visibly then clears.
	tween.tween_method(set_shader_value, 1, 0, .15)
	tween.tween_method(set_shader_value, 0, 1, .15)
	tween.tween_callback(_on_strike_end)
	line_drawn.emit()
	return true
	
func set_shader_value(value: float) -> void:
	if not material:
		return
	if material.has_method("set_shader_parameter"):
		material.set_shader_parameter("Transparency", value)

func _get_points(start: Vector2, end: Vector2) -> Array:
	var arc_points := []
	var begin := start
	var distance := end - start

	for i in range(20):
		var t := (1.0 / 20) * i
		var x := begin.x + (distance.x / 20) * i
		var y := begin.y + ease_out_cubic(t) * distance.y
		arc_points.append(Vector2(x, y))
	arc_points.append(end)

	return arc_points
	
func ease_out_cubic(number: float) -> float:
	return 1.0 - pow(1.0 - number, 3.0)

func _on_strike_end() -> void:
	complete.emit()
	queue_free()
