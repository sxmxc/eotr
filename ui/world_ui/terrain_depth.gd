extends Node2D
## Cached render geometry only. TileMapLayer remains the sole terrain authority.

const CORNERS := [Vector2(0, -32), Vector2(32, -16), Vector2(32, 16), Vector2(0, 32), Vector2(-32, 16), Vector2(-32, -16)]
var faces: Array[PackedVector2Array] = []
var rims: Array[PackedVector2Array] = []
var colors: Array[Color] = []
var pending := false
@onready var layer: TileMapLayer = get_parent().get_node("BaseLayer")

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	layer.changed.connect(_schedule_rebuild)
	# Cell erasure does not reliably emit TileMapLayer.changed in the running
	# editor build. Consume the authoritative map's terrain/presentation events too.
	var board := get_parent() as ProcGenTilemap
	board.presentation_changed.connect(_schedule_rebuild)
	board.map_generated.connect(_schedule_rebuild)
	_schedule_rebuild()

func _schedule_rebuild() -> void:
	if pending:
		return
	pending = true
	_rebuild.call_deferred()

func _rebuild() -> void:
	pending = false
	faces.clear()
	rims.clear()
	colors.clear()
	for cell: Vector2i in layer.get_used_cells():
		var center := layer.map_to_local(cell)
		for i in 6:
			var a: Vector2 = center + CORNERS[i]
			var b: Vector2 = center + CORNERS[(i + 1) % 6]
			var normal := ((a + b) * 0.5 - center).normalized()
			# Query the actual layer across this edge; never infer gameplay adjacency.
			var adjacent := layer.local_to_map((a + b) * 0.5 + normal * 4.0)
			if layer.get_cell_source_id(adjacent) != -1:
				continue
			var thickness := 7.0 + float(posmod(cell.x * 17 + cell.y * 11 + i, 6))
			var drop := Vector2(0, thickness)
			var chip := a.lerp(b, 0.57) + drop * 0.9 + normal * 1.6
			faces.append(PackedVector2Array([a, b, b + drop * 0.72, chip, a + drop]))
			colors.append(Color("20272f") if normal.y > 0.0 else Color("121a23"))
			rims.append(PackedVector2Array([a, b]))
	queue_redraw()

func _draw() -> void:
	for i in faces.size():
		var face := faces[i]
		var shadow := PackedVector2Array()
		for point in face:
			shadow.append(point + Vector2(0, 4))
		draw_colored_polygon(shadow, Color(0.002, 0.004, 0.009, 0.65))
		draw_colored_polygon(face, colors[i])
		var rim := rims[i]
		draw_line(rim[0], rim[1], Color(0.42, 0.45, 0.47, 0.55), 0.7, true)
		var seam := rim[0].lerp(rim[1], 0.57)
		draw_line(seam + Vector2(0, 1), seam + Vector2(2, 6), Color(0.045, 0.055, 0.075, 0.8), 0.8, true)
