extends Node2D
# Presentation only. Board state, generation and targeting validity stay on ProcGenTilemap.
const TARGET_HIGHLIGHT_SHADER := preload("res://scripts/shaders/tile_target_highlight.gdshader")
const TARGET_HIGHLIGHT_ATLAS := preload("res://assets/spritesheets/32x32-hex-tiles.png")
# Match the main tile sprite mask (hex) so highlights keep the correct silhouette.
const TARGET_HIGHLIGHT_REGION := Rect2i(32, 32, 32, 32)


var target_highlight_texture: Texture2D
var target_highlight_material: ShaderMaterial
var target_highlight_pool: Array[Sprite2D] = []
var active_target_highlights: Array[Sprite2D] = []
var last_target_highlight_cells: Array[Vector2i] = []


@onready var board: ProcGenTilemap = get_parent()
var rounds_until_collapse := 99
var edge: Array[Vector2i] = []

func _ready() -> void:
	Events.rounds_until_shrink_updated.connect(_collapse_changed)
	board.presentation_changed.connect(_refresh)
	board.map_generated.connect(_refresh)

func _collapse_changed(value: int) -> void:
	rounds_until_collapse = value
	_refresh()

func _refresh() -> void:
	if not board.base_layer:
		return
	edge.clear()
	if rounds_until_collapse <= 1 and not board.tile_map_data.is_empty():
		edge.assign(board.get_battlemap_edge_clockwise())
	# Visibility changes must invalidate the pooled overlay's cell cache.
	var cells := last_target_highlight_cells.duplicate()
	last_target_highlight_cells.clear()
	show_target_highlights(cells)
	queue_redraw()

func _draw() -> void:
	# 32px hex art, horizontal offset axis (tile_layout 5); no coordinate substitution.
	for cell in edge:
		if board.is_tile_behind_fog(cell) or not board.tile_map_data.has(cell):
			continue
		var center := board.base_layer.map_to_local(cell)
		var points := PackedVector2Array()
		for offset in [Vector2(0,-15), Vector2(15,-8), Vector2(15,8), Vector2(0,15), Vector2(-15,8), Vector2(-15,-8), Vector2(0,-15)]:
			points.append(center + offset)
		draw_polyline(points, Color("ef887a"), 1.5, true)

func show_target_highlights(cells: Array[Vector2i]) -> void:
	if not board.base_layer:
		return
	if not target_highlight_material or not target_highlight_texture:
		_build_target_highlight_assets()
	if cells.is_empty():
		clear_target_highlights()
		return
	if last_target_highlight_cells == cells:
		return
	_clear_target_highlight_nodes()
	last_target_highlight_cells = cells.duplicate()
	for cell in cells:
		# The card supplies legal cells, including occupied enemy hexes. Movement's
		# free-cell predicate would incorrectly suppress attack targets here.
		if not board.tile_map_data.has(cell) or board.is_tile_behind_fog(cell):
			continue
		var sprite := _get_target_highlight_sprite()
		sprite.position = board.base_layer.map_to_local(cell)
		sprite.visible = true
		active_target_highlights.append(sprite)

func clear_target_highlights() -> void:
	if not is_inside_tree():
		return
	_clear_target_highlight_nodes()
	last_target_highlight_cells.clear()

func _clear_target_highlight_nodes() -> void:
	for sprite in active_target_highlights:
		sprite.visible = false
		target_highlight_pool.append(sprite)
	active_target_highlights.clear()

func _get_target_highlight_sprite() -> Sprite2D:
	if not target_highlight_material or not target_highlight_texture:
		_build_target_highlight_assets()
	if target_highlight_pool.is_empty():
		var hl_sprite := Sprite2D.new()
		hl_sprite.texture = target_highlight_texture
		hl_sprite.material = target_highlight_material
		hl_sprite.centered = true
		hl_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hl_sprite.z_index = 2
		add_child(hl_sprite)
		return hl_sprite
	var sprite: Sprite2D = target_highlight_pool.pop_back()
	sprite.texture = target_highlight_texture
	sprite.material = target_highlight_material
	sprite.z_index = 2
	return sprite

func _build_target_highlight_assets() -> void:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = TARGET_HIGHLIGHT_ATLAS
	atlas_texture.region = TARGET_HIGHLIGHT_REGION
	target_highlight_texture = atlas_texture

	target_highlight_material = ShaderMaterial.new()
	target_highlight_material.shader = TARGET_HIGHLIGHT_SHADER
	target_highlight_material.set_shader_parameter("PulseSpeed", 1.35)
	target_highlight_material.set_shader_parameter("MinAlpha", 0.1)
	target_highlight_material.set_shader_parameter("MaxAlpha", 0.95)
	target_highlight_material.set_shader_parameter("OutlineWidth", 0.065)
	# Lost Century-friendly teal that stands off resource yellows.
	target_highlight_material.set_shader_parameter("HighlightColor", Color(0.29, 0.75, 0.67, 1.0))
	
