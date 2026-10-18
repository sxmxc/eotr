extends Node2D
# Presentation only. Board state, generation and targeting validity stay on ProcGenTilemap.
const TARGET_HIGHLIGHT := preload("res://ui/world_ui/target_highlight.tscn")
const COLLAPSE_OUTLINE := preload("res://ui/world_ui/collapse_outline.tscn")
var collapse_outlines: Array[Line2D] = []


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
	_refresh_collapse_outlines()

func _refresh_collapse_outlines() -> void:
	for outline in collapse_outlines:
		outline.hide()
	var index := 0
	for cell in edge:
		if board.is_tile_behind_fog(cell) or not board.tile_map_data.has(cell):
			continue
		if index == collapse_outlines.size():
			var outline: Line2D = COLLAPSE_OUTLINE.instantiate()
			add_child(outline)
			collapse_outlines.append(outline)
		var outline := collapse_outlines[index]
		outline.position = board.base_layer.map_to_local(cell)
		outline.show()
		index += 1

func show_target_highlights(cells: Array[Vector2i]) -> void:
	if not board.base_layer:
		return
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
	if target_highlight_pool.is_empty():
		var sprite: Sprite2D = TARGET_HIGHLIGHT.instantiate()
		add_child(sprite)
		return sprite
	return target_highlight_pool.pop_back()
	
