class_name TargetSelector
extends Node2D

const ARC_POINTS := 8
signal cache_invalidated

@export var enable_electric_arc_fx := false
@export var invalid_indicator_color := Colors.theme_critical
@export var valid_indicator_color := Colors.theme_success
@export var neutral_indicator_color := Colors.theme_highlight

@onready var area_2d: Area2D = get_node_or_null("Area2D")
@onready var card_arc: Line2D = get_node_or_null("CanvasLayer/CardArc")
@onready var electric_arc_fx: Line2D = _find_electric_arc()
@onready var hex_indicator: Sprite2D = $HexIndicator

var current_card: CardUI
var targeting := false
var current_tile_target: TilemapTarget = null
var last_hovered_tile := Vector2i(-9999, -9999)
var cached_targets := {}
var tilemap: ProcGenTilemap
var base_layer: TileMapLayer
var interaction: CardInteractionController


func bind_interaction(controller: CardInteractionController, board: ProcGenTilemap) -> void:
	interaction = controller
	tilemap = board
	base_layer = board.base_layer

func _find_electric_arc() -> Line2D:
	var candidate := get_node_or_null("CanvasLayer/ElectricArcFX")
	if candidate is Line2D:
		return candidate
	return candidate.get_node_or_null("ElectricArcFX") as Line2D if candidate else null


func _ready() -> void:
	add_to_group("target_selector")
	hex_indicator.hide()
	Events.player_moved.connect(_reset_cache)
	Events.enemy_updated.connect(_reset_cache)
	Events.enemy_died.connect(_reset_cache)
	Events.tile_updated.connect(_reset_cache)


func _physics_process(_delta: float) -> void:
	if not targeting or not is_instance_valid(current_card):
		return

	if area_2d:
		area_2d.position = get_local_mouse_position()

	var points := _get_points()
	if card_arc:
		card_arc.points = points
	if electric_arc_fx and enable_electric_arc_fx:
		electric_arc_fx.points = points

	_update_overlap_targets()
	if (current_card.card.target_type == Enums.TargetType.SINGLE_TILE or interaction.is_relocating(current_card)):
		_update_tile_hover()


func get_cached_targets(card_ui: CardUI) -> Array[Vector2i]:
	if not card_ui or not card_ui.card:
		return []
	var key := card_ui.get_instance_id()
	if cached_targets.has(key):
		return cached_targets[key]
	var targets := card_ui.card.get_valid_targets(card_ui, card_ui.player_modifiers)
	cached_targets[key] = targets
	return targets


func _update_overlap_targets() -> void:
	if not area_2d or not current_card:
		return
	if (current_card.card.target_type == Enums.TargetType.SINGLE_TILE or interaction.is_relocating(current_card)):
		return
	var best_target: Node = null
	var best_distance := INF
	var mouse_pos := area_2d.global_position

	for overlap in area_2d.get_overlapping_areas():
		var target_node := overlap.get_parent()
		if not is_instance_valid(target_node):
			continue
		if not interaction.is_preview_target(current_card, target_node):
			continue
		if not (target_node is Node2D):
			continue
		var target_pos: Vector2 = (target_node as Node2D).global_position
		var dist := mouse_pos.distance_to(target_pos)
		if dist < best_distance:
			best_distance = dist
			best_target = target_node

	if best_target:
		_set_current_target(best_target)


func _set_current_target(target_node: Node) -> void:
	if not current_card:
		return
	interaction.select_target(current_card, target_node)


func _update_tile_hover() -> void:
	if not tilemap or not base_layer:
		return
	var global_mouse_pos = get_global_mouse_position()
	var tile_pos = tilemap.world_to_cell(global_mouse_pos)

	if not tilemap.is_within_bounds(tile_pos) or tile_pos == last_hovered_tile:
		return

	_clear_tile_target()
	last_hovered_tile = tile_pos
	var cell_tile_data = base_layer.get_cell_tile_data(tile_pos)
	if not cell_tile_data:
		hex_indicator.hide()
		return

	hex_indicator.global_position = tilemap.cell_to_world(tile_pos)

	var candidate := TilemapTarget.new(tile_pos, tilemap)
	add_child(candidate)
	var is_valid := interaction.is_preview_target(current_card, candidate)

	if is_valid:
		current_tile_target = candidate
		_set_current_target(current_tile_target)
		hex_indicator.material.set_shader_parameter("HighlightColor", valid_indicator_color)
	else:
		candidate.queue_free()
		hex_indicator.material.set_shader_parameter("HighlightColor", invalid_indicator_color)

	hex_indicator.show()


func _clear_tile_target() -> void:
	if current_tile_target and is_instance_valid(current_tile_target):
		if is_instance_valid(current_card) and current_card.targets.has(current_tile_target):
			current_card.targets.erase(current_tile_target)
		current_tile_target.queue_free()
	current_tile_target = null


func _get_points() -> Array:
	var points := []
	if not current_card:
		return points
	var start := current_card.global_position
	start.x += (current_card.size.x / 2)
	var target := card_arc.get_local_mouse_position() if card_arc else get_local_mouse_position()
	var distance := target - start

	for i in range(ARC_POINTS):
		var t := (1.0 / ARC_POINTS) * i
		var x := start.x + (distance.x / ARC_POINTS) * i
		var y := start.y + ease_out_cubic(t) * distance.y
		points.append(Vector2(x, y))
	points.append(target)

	return points


func ease_out_cubic(number: float) -> float:
	return 1.0 - pow(1.0 - number, 3.0)


func begin_aim(card_ui: CardUI) -> void:
	if not card_ui or not card_ui.card or not card_ui.card.is_single_targeted():
		return
	_clear_tile_target()
	targeting = true
	current_card = card_ui
	last_hovered_tile = Vector2i(-9999, -9999)
	_get_points() # warm cache to avoid nulls
	get_cached_targets(card_ui)
	if area_2d:
		area_2d.monitoring = true
		area_2d.monitorable = true
	if card_arc:
		card_arc.visible = true
	if electric_arc_fx:
		electric_arc_fx.visible = enable_electric_arc_fx


func end_aim(keep_target := false) -> void:
	targeting = false
	if card_arc:
		card_arc.clear_points()
	if electric_arc_fx:
		electric_arc_fx.clear_points()
	if area_2d:
		area_2d.position = Vector2.ZERO
		area_2d.monitoring = false
		area_2d.monitorable = false
	if not keep_target:
		_clear_tile_target()
	cached_targets.clear()
	current_card = null
	hex_indicator.hide()
	hex_indicator.position = Vector2.ZERO
	hex_indicator.material.set_shader_parameter("HighlightColor", neutral_indicator_color)
	last_hovered_tile = Vector2i(-9999, -9999)


func release_tile_target() -> void:
	_clear_tile_target()


func _reset_cache(_arg: Variant = null) -> void:
	cached_targets.clear()
	last_hovered_tile = Vector2i(-9999, -9999)
	if not targeting and (not is_instance_valid(interaction) or not is_instance_valid(interaction.resolving_card)):
		_clear_tile_target()
	cache_invalidated.emit()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	# Collision handling is driven from _update_overlap_targets to use the controller context.
	pass


func _on_area_2d_area_exited(_area: Area2D) -> void:
	# Keep current targets intact; selection is explicit through the controller to avoid losing targets when the cursor leaves.
	pass
