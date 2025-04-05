extends RefCounted
class_name HexTileData

var tile_id: Vector2i
var type : Enums.TileType
var resource_count: int


func _init(tile_coord: Vector2i, tile_type: Enums.TileType, count: int):
	self.tile_id = tile_coord
	self.type = tile_type
	self.resource_count = count

func get_type_string() -> String:
	return str(Enums.TileType.keys()[type]).capitalize()
