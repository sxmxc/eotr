extends Node
class_name TilemapTarget

var tile_position: Vector2i
var tilemap: ProcGenTilemap

func _init(position: Vector2i, map: ProcGenTilemap):
	tile_position = position
	tilemap = map
