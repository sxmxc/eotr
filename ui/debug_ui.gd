extends Control

const DEBUG_COORDS_LABEL = preload("res://resources/debug_coords_label.tres")

@onready var debug_container: VBoxContainer = %DebugContainer
@export var base_layer: TileMapLayer
@export var map_camera: Camera2D  # Ensure to set this in the editor

var value_map : Dictionary = {}

func set_debug_value(which: String, value: String) -> void:
	if value_map.has(which):
		value_map[which].node.text = which + ": " + value
		return
	var label = Label.new()
	value_map[which] = { "node": label }
	value_map[which].node.text = which + ": " + value
	debug_container.add_child(label)

func _on_tile_selected(data: HexTileData):
	set_debug_value("Selected Position", str(data.tile_id))
	set_debug_value("Selected Tile Type", str(data.type))

func draw_tile_coords() -> void:
	for cell in base_layer.get_used_cells():
		var label = Label.new()
		label.text = str(cell)
		label.z_index = 5
		label.label_settings = DEBUG_COORDS_LABEL.duplicate()
		base_layer.add_child(label)
		var pos_offset = Vector2(base_layer.map_to_local(cell).x - (label.size.x/2), base_layer.map_to_local(cell).y - (label.size.y/2))
		label.position = pos_offset

func _process(_delta):
	if not base_layer or not map_camera:
		return

	var screen_mouse_pos = get_viewport().get_mouse_position()
	var world_mouse_pos = map_camera.get_screen_transform().affine_inverse().basis_xform(screen_mouse_pos)
	var tile_pos = base_layer.local_to_map(base_layer.to_local(world_mouse_pos))

	# Step 5: Query tile data
	if base_layer.get_cell_source_id(tile_pos) != -1:
		var tile_data = base_layer.get_cell_tile_data(tile_pos)
		if tile_data:
			var tile_type = tile_data.get_custom_data("tile_type")
			set_debug_value("Hovered Position", str(tile_pos))
			set_debug_value("Hovered Tile Type", str(tile_type))
		else:
			set_debug_value("Hovered Position", str(tile_pos))
			set_debug_value("Hovered Tile Type", "No tile_data")
	else:
		set_debug_value("Hovered Position", "None")
		set_debug_value("Hovered Tile Type", "None")
