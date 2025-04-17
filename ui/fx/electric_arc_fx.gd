class_name ElectricArcFX
extends Line2D

signal complete

func strike():
	var player : Player = get_tree().get_first_node_in_group("player") as Player
	var fx_layer : CanvasLayer = get_tree().get_first_node_in_group("fx_layer")
	var start = player.get_global_transform_with_canvas().origin + fx_layer.get_final_transform().origin
	var end = get_tree().get_first_node_in_group("projectile_start").get_global_mouse_position()
	print("bolt striking: start %s end %s" % [start, end])
	points = _get_points(start,end)
	get_tree().create_timer(.3).timeout.connect(_on_strike_end)

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
