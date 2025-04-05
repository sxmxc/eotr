extends Panel
class_name TileInfoUI

@onready var type_label = %TypeLabel
@onready var loc_label = %LocLabel
@onready var resource_label = %ResourceLabel

func _ready():
	Events.tile_selected.connect(_on_tile_selected)
	Events.tile_updated.connect(_on_tile_updated)
	
func _on_tile_selected(tile_info: HexTileData) -> void:
	update_info(tile_info)

func _on_tile_updated(tile_info: HexTileData) -> void:
	if str(tile_info.tile_id) != loc_label.text:
		return
	update_info(tile_info)

func update_info(tile_info: HexTileData) -> void:
	if not self.is_node_ready():
		await ready
	type_label.text = str(Enums.TileType.keys()[tile_info.type]).capitalize()
	loc_label.text = str(tile_info.tile_id)
	resource_label.text = str(tile_info.resource_count)
