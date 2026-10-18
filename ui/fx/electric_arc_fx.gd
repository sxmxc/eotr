class_name ElectricArcFX
extends Line2D

signal complete
signal line_drawn
@export_enum("Arcane", "Overload", "Sever") var strike_style := 0

func strike(target: Node2D = null, source: Node2D = null) -> bool:
	var start := global_position
	var end := start

	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if source:
		start = source.get_node("SpellOrigin").global_position if source.has_node("SpellOrigin") else source.global_position
	elif player:
		start = player.global_position
	else:
		var start_anchor := get_tree().get_first_node_in_group("projectile_start")
		if start_anchor is Node2D:
			start = (start_anchor as Node2D).global_position
		elif start_anchor is Control:
			start = (start_anchor as Control).global_position

	# Prefer the actual target; fall back to a projectile_start anchor.
	if target and target is Node2D:
		end = target.get_node("ImpactAnchor").global_position if target.has_node("ImpactAnchor") else (target as Node2D).global_position
	else:
		var projectile_start := get_tree().get_first_node_in_group("projectile_start")
		if projectile_start and projectile_start.has_method("get_global_mouse_position"):
			end = projectile_start.get_global_mouse_position()
		else:
			return false

	print("bolt striking: start %s end %s" % [start, end])
	# Each overlapping bolt owns its fade; line points are local to this node.
	if material:
		material = material.duplicate()
		material.set_shader_parameter("strike_style", strike_style)
	points = _get_points(to_local(start), to_local(end))
	var tween = create_tween()
	# Ensure the arc draws visibly then clears.
	tween.tween_method(set_shader_value, 1.0, 0.0, 0.08)
	tween.tween_interval(0.08)
	tween.tween_method(set_shader_value, 0.0, 1.0, 0.22)
	tween.tween_callback(_on_strike_end)
	line_drawn.emit()
	return true
	
func set_shader_value(value: float) -> void:
	if not material:
		return
	if material.has_method("set_shader_parameter"):
		material.set_shader_parameter("transparency", value)

func _get_points(start: Vector2, end: Vector2) -> Array:
	var arc_points := []
	var begin := start
	var distance := end - start

	for i in range(20):
		var t := (1.0 / 20) * i
		if strike_style > 0:
			var sideways := distance.normalized().orthogonal()
			var displacement := sin(t * PI * 17.0) * 5.0 * sin(t * PI) if strike_style == 1 else 0.0
			arc_points.append(start + distance * t + sideways * displacement)
			continue
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
