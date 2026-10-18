extends Card

func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var move_effect := MoveEffect.new()
	var tilemap_target = targets[0] as TilemapTarget
	move_effect.tilemap_target = tilemap_target
	move_effect.sound_fx = sound_fx
	var player_array: Array[Node] = []
	if tilemap_target and tilemap_target.tilemap:
		player_array = tilemap_target.tilemap.get_tree().get_nodes_in_group("player")
	move_effect.execute(player_array)


func is_valid_target(targets: Array[Node], _modifiers: ModifierHandler) -> bool:
	var tilemap_target = targets[0] as TilemapTarget
	if tilemap_target == null or not tilemap_target.tilemap:
		return false
	if not tilemap_target.tilemap.is_tile_valid(tilemap_target.tile_position):
		return false

	var target_tile_data: HexTileData = tilemap_target.tilemap.tile_map_data[tilemap_target.tile_position]
	var target_tile_type: Enums.TileType = target_tile_data.type

	if (
		!target_tile_type == Enums.TileType.CORRUPTED
		and tilemap_target.tilemap.fog_state.has(tilemap_target.tile_position)
	):
		return true
	return false


func get_default_description() -> String:
	return description


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return (
		description
	)
