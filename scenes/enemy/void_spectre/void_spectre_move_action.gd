extends EnemyAction

@export var max_search_radius: int = 5  # How far out allowed to look

func is_performable() -> bool:
	if target == null:
		return false
	var enemy_tile = enemy.tilemap.base_layer.local_to_map(enemy.position)
	var player_tile = enemy.tilemap.base_layer.local_to_map(target.position)
	var surrounding_tiles = enemy.tilemap.base_layer.get_surrounding_cells(enemy_tile)
	if surrounding_tiles.has(player_tile):
		return false

	return true

func perform_action():
	var generation := action_generation
	var void_spectre = enemy as MovingEnemy
	if not void_spectre or not void_spectre.tilemap:
		return

	var player_tile = void_spectre.get_player_tile_position()
	var found_tile: Vector2i = Vector2i(-1, -1)

	# Start searching outward, increasing the radius each loop
	for radius in range(1, max_search_radius + 1):
		var surrounding_tiles = void_spectre.tilemap.get_surrounding_tiles_in_radius(player_tile, radius)
		var available_tiles: Array[Vector2i] = []

		# Collect free tiles in current radius
		for tile in surrounding_tiles:
			if void_spectre.can_move_to_tile(tile) and void_spectre.can_reach_tile(tile):
				available_tiles.append(tile)

		# If we found any available tiles at this radius, pick one and break
		if not available_tiles.is_empty():
			found_tile = RNG.array_pick_random(available_tiles)
			break

	# If no tiles were found even after searching max radius, give up
	if found_tile == Vector2i(-1, -1):
		complete_movement_action(generation, .6)
		return

	# Move to the selected tile
	if not void_spectre.set_movement_target(found_tile):
		complete_movement_action(generation, .3)
		return
	await void_spectre.movement_finished
	if generation != action_generation:
		return
	SoundManager.play_sound_random_pitch(sound)
	complete_movement_action(generation, .3)
	
