extends Node2D

const ARC_POINTS := 8

@onready var area_2d: Area2D = $Area2D
@onready var card_arc: Line2D = $CanvasLayer/CardArc
@onready var hex_indicator = $HexIndicator
@onready var circle_indicator = $CircleIndicator

var current_card: CardUI
var targeting := false
var current_tile_target: TilemapTarget = null



func _ready() -> void:
	hex_indicator.hide()
	circle_indicator.hide()
	Events.card_aim_started.connect(_on_card_aim_started)
	Events.card_aim_ended.connect(_on_card_aim_ended)


func _physics_process(_delta: float) -> void:
	if not targeting:
		return

	# Update Area2D position
	area_2d.position = get_local_mouse_position()

	# Update card arc
	card_arc.points = _get_points()
	

	# Manual collision detection against the tilemap
	if targeting and current_card.card.target_type == Enums.TargetType.SINGLE_TILE:
		# Get the tilemap and necessary layers
		var tilemap: ProcGenTilemap = get_tree().get_first_node_in_group("map_layer")
		var base_layer = tilemap.base_layer

		# Get current mouse position
		var global_mouse_pos = get_global_mouse_position()
		var local_pos = base_layer.to_local(global_mouse_pos)
		var tile_pos = base_layer.local_to_map(local_pos)

		# Check if tile position has changed
		if is_instance_valid(tilemap) and tilemap.is_within_bounds(tile_pos):
			var current_hovered = tile_pos

			# Store the last hovered tile position as a class variable if it's not already defined
			if not has_meta("last_hovered_tile"):
				set_meta("last_hovered_tile", current_hovered)

			var last_hovered = get_meta("last_hovered_tile")

			# If tile changed, handle exit and enter
			if current_hovered != last_hovered:
				# Clean up previous target if it exists
				if (current_tile_target != null and current_card):
					if current_card.targets.has(current_tile_target):
						current_card.targets.erase(current_tile_target)
					current_tile_target.queue_free()
					current_tile_target = null

				# Reset hex indicator
				hex_indicator.hide()
				hex_indicator.self_modulate = Colors.theme_highlight

				# Simulate enter to new tile
				var cell_tile_data = base_layer.get_cell_tile_data(current_hovered)
				if cell_tile_data:
					# Update hex indicator position
					var indicator_pos = base_layer.map_to_local(current_hovered)
					hex_indicator.global_position = base_layer.to_global(indicator_pos)

					# Create and validate new target
					current_tile_target = TilemapTarget.new(current_hovered, tilemap)
					add_child(current_tile_target)

					# Check target validity
					if current_card and (!current_card.targets.has(current_tile_target)):
						if current_tile_target != null:
							if !current_card.card.is_valid_target(
								[current_tile_target], current_card.player_modifiers
							):
								hex_indicator.self_modulate = Colors.theme_critical
							else:
								current_card.targets.append(current_tile_target)
								hex_indicator.self_modulate = Colors.theme_success

							# Always show the hex indicator
							hex_indicator.show()

				# Debug info
				if cell_tile_data and cell_tile_data.has_custom_data("tile_type"):
					var tile_type = cell_tile_data.get_custom_data("tile_type")
					print("Tile: %s, Type: %s" % [str(current_hovered), str(tile_type)])

				# Update last hovered tile
				set_meta("last_hovered_tile", current_hovered)


func _get_points() -> Array:
	var points := []
	var start := current_card.global_position
	start.x += (current_card.size.x / 2)
	var target := card_arc.get_local_mouse_position()
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


func _on_card_aim_started(card: CardUI) -> void:
	if not card.card.is_single_targeted():
		return

	targeting = true
	area_2d.monitoring = true
	area_2d.monitorable = true
	current_card = card


func _on_card_aim_ended(_card: CardUI) -> void:
	targeting = false
	card_arc.clear_points()
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false
	current_card = null
	if current_tile_target:
		current_tile_target.queue_free()
		current_tile_target = null
	if circle_indicator.visible:
		circle_indicator.hide()
		circle_indicator.position = Vector2.ZERO
	if hex_indicator.visible:
		hex_indicator.hide()
		hex_indicator.position = Vector2.ZERO
		hex_indicator.self_modulate = Colors.theme_highlight


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not current_card or not targeting:
		return

	match current_card.card.target_type:
		Enums.TargetType.SELF:
			if get_tree().get_nodes_in_group("player").has(area.get_parent()):
				if not current_card.targets.has(area.get_parent()):
					current_card.targets.append(area.get_parent())
					circle_indicator.global_position = area.global_position
					circle_indicator.show()

		Enums.TargetType.SINGLE_ENEMY:
			if get_tree().get_nodes_in_group("enemy").has(area.get_parent()):
				if not current_card.targets.has(area.get_parent()):
					current_card.targets.append(area.get_parent())
					circle_indicator.global_position = area.global_position
					circle_indicator.show()
					current_card.request_description()
					Events.enemy_selected.emit(area.get_parent())


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not current_card or not targeting:
		return
	current_card.targets.erase(area.get_parent())
	print("%s removed from targets. New targets: %s" % [area, current_card.targets])
	circle_indicator.hide()
	circle_indicator.position = Vector2.ZERO
	current_card.request_description()
	Events.enemy_info_hide_requested.emit()
