extends Node2D

func _draw() -> void:
	# Root silhouettes reserve the tile edge, leaving the floor and unit readable.
	for side in [-1, 1]:
		var points := PackedVector2Array([Vector2(side * 25, 10), Vector2(side * 21, -5), Vector2(side * 13, -12), Vector2(side * 11, -22)])
		draw_polyline(points, Color(0.65, 0.76, 0.4, 0.9), 3.0, true)
		draw_line(Vector2(side * 21, -5), Vector2(side * 29, -15), Color(0.65, 0.76, 0.4, 0.9), 2.0, true)
