extends Card

@export var movement_distance := 1


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var move_effect := MoveEffect.new()
	var tilemap_target = targets[0] as TilemapTarget
	move_effect.tilemap_target = tilemap_target
	move_effect.sound_fx = sound_fx
	var player_array = targets[0].get_tree().get_nodes_in_group("player")
	move_effect.execute(player_array)


func is_valid_target(targets: Array[Node], modifiers: ModifierHandler) -> bool:
	var tilemap_target = targets[0] as TilemapTarget
	if tilemap_target == null:
		return false
	var player: Player = targets[0].get_tree().get_first_node_in_group("player")
	var player_tile: Vector2i = tilemap_target.tilemap.base_layer.local_to_map(player.position)
	# Start with the center cell
	var current_cells = {player_tile: true}
	var all_cells_in_range = {player_tile: true}

	# For each level of the radius
	for r in range(modifiers.get_modified_value(movement_distance, Enums.ModifierType.MOVEMENT)):
		var next_level_cells = {}

		# Get all neighbors of the current level cells
		for cell in current_cells:
			var neighbors = tilemap_target.tilemap.base_layer.get_surrounding_cells(cell)
			for neighbor in neighbors:
				if (
					tilemap_target.tilemap.is_within_bounds(neighbor)
					and not all_cells_in_range.has(neighbor)
				):
					next_level_cells[neighbor] = true
					all_cells_in_range[neighbor] = true

		# Move to the next level
		current_cells = next_level_cells

	var target_tile_data: HexTileData = tilemap_target.tilemap.tile_map_data[
		tilemap_target.tile_position
	]
	var target_tile_type: Enums.TileType = target_tile_data.type

	if (
		!target_tile_type == Enums.TileType.CORRUPTED
		and all_cells_in_range.has(tilemap_target.tile_position)
	):
		return true
	return false


func get_default_description() -> String:
	return description % movement_distance


func get_modified_description(
	player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return (
		description
		% player_modifiers.get_modified_value(movement_distance, Enums.ModifierType.MOVEMENT)
	)
