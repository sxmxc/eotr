extends Node2D
## Cosmetic stone skirts traced from atlas alpha, behind the authoritative tiles.

@export_range(1, 24) var depth_pixels: int = 10
var skirts: Dictionary[Vector3i, Texture2D] = {}
var cells: Array[Vector2i] = []
var pending := false
@onready var board: ProcGenTilemap = get_parent()
@onready var layer: TileMapLayer = board.get_node("BaseLayer")

func _ready() -> void:
	layer.changed.connect(_schedule_rebuild)
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
	cells.clear()
	for cell: Vector2i in layer.get_used_cells():
		if board.is_tile_behind_fog(cell):
			continue
		cells.append(cell)
		var key := _key(cell)
		if not skirts.has(key):
			skirts[key] = _make_skirt(cell)
	queue_redraw()

func _key(cell: Vector2i) -> Vector3i:
	var atlas := layer.get_cell_atlas_coords(cell)
	return Vector3i(atlas.x, atlas.y, layer.get_cell_source_id(cell))

func _make_skirt(cell: Vector2i) -> Texture2D:
	var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
	var region := source.get_tile_texture_region(layer.get_cell_atlas_coords(cell))
	var atlas := source.texture.get_image()
	if atlas.is_compressed():
		atlas.decompress()
	var art := atlas.get_region(region)
	var skirt := Image.create(art.get_width(), art.get_height() + depth_pixels, false, Image.FORMAT_RGBA8)
	# Trace the painted lower contour, including chips. No assumed hex vertices,
	# separate rim lines, random corner offsets or detached shadow polygons.
	for x in art.get_width():
		var bottom := art.get_height() - 1
		while bottom >= 0 and art.get_pixel(x, bottom).a < 0.5:
			bottom -= 1
		if bottom < 0:
			continue
		for drop in range(1, depth_pixels + 1):
			var fraction := float(drop) / depth_pixels
			# Borrow the adjacent painted stone band, rather than stretching its
			# black contour into a solid strip. Darken towards the underside.
			var sample_y := maxi(0, bottom - depth_pixels + drop - 1)
			var pigment := art.get_pixel(x, sample_y)
			if pigment.a < 0.5:
				pigment = art.get_pixel(x, bottom)
			var shade := lerpf(0.72, 0.30, fraction)
			skirt.set_pixel(x, bottom + drop, Color(pigment.r * shade, pigment.g * shade, pigment.b * shade, 1.0))
	return ImageTexture.create_from_image(skirt)

func _draw() -> void:
	for cell: Vector2i in cells:
		# Check again at draw time: erased or newly hidden tiles cannot leave skirts.
		if layer.get_cell_source_id(cell) == -1 or board.is_tile_behind_fog(cell):
			continue
		var source := layer.tile_set.get_source(layer.get_cell_source_id(cell)) as TileSetAtlasSource
		var region := source.get_tile_texture_region(layer.get_cell_atlas_coords(cell))
		var origin := layer.map_to_local(cell) - Vector2(region.size) * 0.5
		origin += Vector2(layer.get_cell_tile_data(cell).texture_origin)
		draw_texture(skirts[_key(cell)], origin)
