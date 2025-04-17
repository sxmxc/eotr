class_name MovingEnemy
extends Enemy

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

var movement_speed: float = 50.0
var is_moving := false


func _ready():
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	navigation_agent_2d.navigation_finished.connect(_on_navigation_finished)
	super._ready()


func _physics_process(delta):
	if navigation_agent_2d.is_navigation_finished() or !is_moving:
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent_2d.get_next_path_position()

	# Calculate direction to next path position
	var direction: Vector2 = current_agent_position.direction_to(next_path_position)

	# Move towards the next path position
	var velocity: Vector2 = direction * movement_speed
	navigation_agent_2d.velocity = velocity
	# Explicitly move the enemy
	global_position += navigation_agent_2d.velocity * delta
	current_tile_position = tilemap.base_layer.local_to_map(position)
	if tilemap.base_layer.get_surrounding_cells(current_tile_position).has(
		get_player_tile_position()
	):
		stats_ui.show()
	else:
		stats_ui.hide()

	super._physics_process(delta)


func set_movement_target(movement_target: Vector2i):
	# Use base_layer to convert tile coordinates to world coordinates
	if tilemap and tilemap.base_layer:
		var world_target: Vector2 = tilemap.base_layer.map_to_local(movement_target)
		navigation_agent_2d.target_position = world_target
		is_moving = true


func calculate_next_tile_move(_tiles_moved_per_turn) -> Vector2i:
	if not tilemap or not tilemap.base_layer:
		return Vector2i(-1, -1)  # Return an invalid tile position

	var player_tile_pos: Vector2i = get_player_tile_position()
	var surrounding_cells: Array[Vector2i] = tilemap.base_layer.get_surrounding_cells(player_tile_pos)

	# Filter to only free tiles
	var free_tiles: Array[Vector2i] = surrounding_cells.filter(func(tile):
		return tilemap.is_tile_free(tile)
	)

	if free_tiles.is_empty():
		return Vector2i(-1, -1)  # No valid tiles, return early

	# Pick a random free tile
	var rand_tile: Vector2i = RNG.array_pick_random(free_tiles)
	var world_target_pos: Vector2 = tilemap.base_layer.map_to_local(rand_tile)

	navigation_agent_2d.target_position = world_target_pos

	# Wait for path calculation
	await get_tree().process_frame
	var path: PackedVector2Array = navigation_agent_2d.get_current_navigation_path()

	if path.is_empty() or path.size() < 2:
		return Vector2i(-1, -1)

	# Calculate next tile from path
	var offset = 8
	var next_offset_pos = path[1] + (position.direction_to(world_target_pos) * offset)
	var next_tile_pos: Vector2i = tilemap.base_layer.local_to_map(next_offset_pos)
	if not tilemap.is_tile_free(next_tile_pos):
		var surrounding_tiles: Array[Vector2i] = tilemap.base_layer.get_surrounding_cells(current_tile_position)

		# Filter to only free tiles
		var next_free_tiles: Array[Vector2i] = surrounding_tiles.filter(func(tile):
			return tilemap.is_tile_free(tile)
		)

		if next_free_tiles.is_empty():
			return Vector2i(-1, -1)
		
		var rand_next_tile: Vector2i = RNG.array_pick_random(next_free_tiles)
		return rand_next_tile

	return next_tile_pos


func get_player_tile_position() -> Vector2i:
	var player = get_tree().get_first_node_in_group("player")
	if player and tilemap and tilemap.base_layer:
		var player_tile = tilemap.base_layer.local_to_map(
			tilemap.base_layer.to_local(player.global_position)
		)
		return player_tile

	return Vector2i.ZERO


func perform_turn_based_move(tiles_per_turn: int = 1):
	# Calculate next move
	var next_tile = await calculate_next_tile_move(tiles_per_turn)

	# Set movement target and move
	set_movement_target(next_tile)
	#is_moving = true


func _on_navigation_finished():
	is_moving = false
	var current_tile = tilemap.base_layer.local_to_map(tilemap.base_layer.to_local(position))
	position = tilemap.base_layer.map_to_local(current_tile)
	position.y += 1
