extends Node2D

const ARC_POINTS := 8


@onready var card_arc: Line2D = $CanvasLayer/CardArc
@onready var hex_indicator = $HexIndicator
@onready var electric_arc_fx: Line2D = $CanvasLayer/ElectricArcFX


var current_card: CardUI
var targeting := false
var current_tile_target : TilemapTarget = null
var current_hovered : Vector2i
var last_hovered : Vector2i
var tilemap: ProcGenTilemap
var base_layer: TileMapLayer


func _ready() -> void:
	hex_indicator.hide()
	tilemap = get_tree().get_first_node_in_group("map_layer")
	base_layer = tilemap.base_layer


func _physics_process(_delta: float) -> void:
	if not targeting:
		return	
	# Update card arc
	card_arc.points = _get_points()
	electric_arc_fx.points = _get_points()
	
	# Manual collision detection against the tilemap
	if targeting:
		if current_card.card.target_type != Enums.TargetType.SINGLE_TILE:
			return		
		
		# Get current mouse position 
		var global_mouse_pos = get_global_mouse_position()
		var local_pos = base_layer.to_local(global_mouse_pos)
		var tile_pos = base_layer.local_to_map(local_pos)
		
		# Check if tile position has changed
		if is_instance_valid(tilemap) and tilemap.is_within_bounds(tile_pos):
			current_hovered = tile_pos
			
			# If tile changed, handle exit and enter
			if current_hovered != last_hovered:
				if current_tile_target != null and current_card and current_card.targets.has(current_tile_target):
					current_card.targets.erase(current_tile_target)
					current_tile_target.queue_free()
					current_tile_target = null
				# Simulate exit from previous tile
				if tilemap.is_within_bounds(last_hovered):
					hex_indicator.hide()
				
				# Simulate enter to new tile
				var cell_tile_data = base_layer.get_cell_tile_data(current_hovered)
				if cell_tile_data:
					# Update hex indicator position
					var indicator_pos = base_layer.map_to_local(current_hovered)
					hex_indicator.global_position = base_layer.to_global(indicator_pos)
					hex_indicator.show()
		
				# Add the current tile to targets
				current_tile_target = TilemapTarget.new(current_hovered, tilemap)
				add_child(current_tile_target)
				
				if current_card and not current_card.targets.has(current_tile_target):
					current_card.targets.append(current_tile_target)
		
				# Debug info
				if cell_tile_data.has_custom_data("tile_type"):
					var tile_type = cell_tile_data.get_custom_data("tile_type")
					print("Tile: %s, Type: %s" % [str(current_hovered), str(tile_type)])
				
				last_hovered = current_hovered

func _get_points() -> Array:
	var points := []
	var start := current_card.global_position
	start.x += (current_card.size.x / 2)
	var target := card_arc.get_local_mouse_position()
	var distance := (target - start)
	
	for i in range(ARC_POINTS):
		var t := (1.0 / ARC_POINTS) * i
		var x := start.x + (distance.x / ARC_POINTS) * i
		var y := start.y + ease_out_cubic(t) * distance.y
		points.append(Vector2(x, y))
	points.append(target)
	
	return points


func ease_out_cubic(number : float) -> float:
	return 1.0 - pow(1.0 - number, 3.0)


func _on_move_selection_started(card: CardUI) -> void:
	if not card.card.is_single_targeted():
		return
	
	targeting = true
	current_card = card


func _on_move_selection_ended(_card: CardUI) -> void:
	targeting = false
	card_arc.clear_points()
	electric_arc_fx.clear_points()
	current_tile_target = null
	current_card = null
	if hex_indicator.visible:
		hex_indicator.hide()
		hex_indicator.position = Vector2.ZERO
