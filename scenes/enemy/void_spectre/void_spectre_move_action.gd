extends EnemyAction


@export var max_search_radius: int = 5  # How far out void_spectres are allowed to look

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
			if not void_spectre.tilemap.is_tile_free(tile):
				continue

			var world_pos = void_spectre.tilemap.base_layer.map_to_local(tile)
			void_spectre.navigation_agent_2d.target_position = world_pos
			await  get_tree().process_frame

			# Important: Check if tile is reachable using the navmesh!
			if void_spectre.navigation_agent_2d.is_target_reachable():
				available_tiles.append(tile)

		# If we found any available tiles at this radius, pick one and break
		if not available_tiles.is_empty():
			found_tile = RNG.array_pick_random(available_tiles)
			break

	# If no tiles were found even after searching max radius, give up
	if found_tile == Vector2i(-1, -1):
		get_tree().create_timer(.6).timeout.connect(func(): Events.enemy_action_completed.emit(void_spectre))
		return

	# Move to the selected tile
	var world_message = WorldMessageData.new("%s flys closer to player" % enemy.name)
	Events.world_message_requested.emit(world_message)
	void_spectre.set_movement_target(found_tile)
	void_spectre.is_moving = true
	await void_spectre.navigation_agent_2d.navigation_finished
	SoundManager.play_sound(sound)
	get_tree().create_timer(.3).timeout.connect(func(): Events.enemy_action_completed.emit(void_spectre))
	
