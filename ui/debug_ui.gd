extends Control

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

func _process(_delta):
	if not base_layer or not map_camera:
		return

	# Convert mouse position to world position considering the camera transform
	var world_pos = map_camera.get_global_mouse_position()
	var tile_pos = base_layer.local_to_map(base_layer.to_local(world_pos))

	# Check if there's a tile under the cursor
	if base_layer.get_cell_source_id(tile_pos) != -1:
		var tile_data = base_layer.get_cell_tile_data(tile_pos)
		if tile_data:
			var tile_type = tile_data.get_custom_data("tile_type")
			set_debug_value("Hovered Position", str(tile_pos))
			set_debug_value("Hovered Tile Type", str(tile_type))
		else:
			set_debug_value("Hovered Position", "None")
			set_debug_value("Hovered Tile Type", "None")
	else:
		set_debug_value("Hovered Position", "None")
		set_debug_value("Hovered Tile Type", "None")
