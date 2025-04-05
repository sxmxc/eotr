extends Card

@export var movement_distance := 1

func apply_effects(targets: Array[Node]) -> void:
	var move_effect := MoveEffect.new()
	var tilemap_target = targets[0] as TilemapTarget
	move_effect.tilemap_target = tilemap_target
	move_effect.sound_fx = sound_fx
	var player_array = targets[0].get_tree().get_nodes_in_group("player")
	move_effect.execute(player_array)

func is_valid_target(targets: Array[Node]) -> bool:
	var tilemap_target = targets[0] as TilemapTarget
	if tilemap_target == null:
		return false
	var player : Player = targets[0].get_tree().get_first_node_in_group("player")
	var player_tile : Vector2i = tilemap_target.tilemap.base_layer.local_to_map(player.position)
	var player_surrounding_cells : Array[Vector2i] = tilemap_target.tilemap.base_layer.get_surrounding_cells(player_tile)
	var target_tile_data : HexTileData = tilemap_target.tilemap.tile_map_data[tilemap_target.tile_position]
	var target_tile_type : Enums.TileType = target_tile_data.type
	if !target_tile_type == Enums.TileType.CORRUPTED and player_surrounding_cells.has(tilemap_target.tile_position):
		return true
	return false
