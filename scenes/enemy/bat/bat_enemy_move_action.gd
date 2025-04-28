extends EnemyAction


@export var max_search_radius: int = 5  # How far out bats are allowed to look

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
	var bat = enemy as MovingEnemy
	if not bat or not bat.tilemap:
		return

	var player_tile = bat.get_player_tile_position()
	var found_tile: Vector2i = Vector2i(-1, -1)

	# Start searching outward, increasing the radius each loop
	for radius in range(1, max_search_radius + 1):
		var surrounding_tiles = bat.tilemap.get_surrounding_tiles_in_radius(player_tile, radius)
		var available_tiles: Array[Vector2i] = []

		# Collect free tiles in current radius
		for tile in surrounding_tiles:
			if not bat.tilemap.is_tile_free(tile):
				continue

			var world_pos = bat.tilemap.base_layer.map_to_local(tile)
			bat.navigation_agent_2d.target_position = world_pos
			await  get_tree().process_frame

			# Important: Check if tile is reachable using the navmesh!
			if bat.navigation_agent_2d.is_target_reachable():
				available_tiles.append(tile)

		# If we found any available tiles at this radius, pick one and break
		if not available_tiles.is_empty():
			found_tile = RNG.array_pick_random(available_tiles)
			break

	# If no tiles were found even after searching max radius, give up
	if found_tile == Vector2i(-1, -1):
		get_tree().create_timer(.6).timeout.connect(func(): Events.enemy_action_completed.emit(bat))
		return

	# Move to the selected tile
	var world_message = WorldMessageData.new("%s flys closer to player" % enemy.name)
	Events.world_message_requested.emit(world_message)
	bat.set_movement_target(found_tile)
	bat.is_moving = true
	await bat.navigation_agent_2d.navigation_finished
	SoundManager.play_sound_random_pitch(sound)
	get_tree().create_timer(.6).timeout.connect(func(): Events.enemy_action_completed.emit(bat))
