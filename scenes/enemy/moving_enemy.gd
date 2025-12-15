class_name MovingEnemy
extends Enemy

signal movement_finished(moved_to: Vector2i)

const INVALID_TILE: Vector2i = Vector2i(-1, -1)

@export var flying: bool = false
@export var move_duration: float = 0.22

@onready var shadow: Sprite2D = $Shadow
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_moving := false
var move_tween: Tween


func _ready():
	super._ready()


func _physics_process(delta):
	super._physics_process(delta)


func update_enemy() -> void:
	if not stats is EnemyStats:
		return
	if not is_inside_tree():
		await ready
	
	sprite_2d.texture = stats.board_icon
	flying = stats.flying
	setup_ai()
	if stats_ui:
		update_stats()
	if flying:
		shadow.show()
		animation_player.play("fly_idle")

func set_movement_target(movement_target: Vector2i) -> bool:
	if not tilemap or not tilemap.base_layer:
		return false
	if movement_target == INVALID_TILE:
		return false
	if not _can_move_to_tile(movement_target):
		return false
	if movement_target == current_tile_position:
		return false

	var world_target: Vector2 = tilemap.base_layer.map_to_local(movement_target)
	is_moving = true

	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "scale", Vector2(1.08, 1.08), move_duration * 0.5)
	move_tween.tween_property(self, "position", world_target + Vector2(0, 1), move_duration)
	move_tween.tween_property(self, "scale", Vector2.ONE, move_duration * 0.25)
	move_tween.tween_callback(
		func():
			_notify_move_finished(movement_target)
	)

	return true


func calculate_next_tile_move(tiles_moved_per_turn: int) -> Vector2i:
	if not tilemap or not tilemap.base_layer:
		print("No tilemap or base_layer. No valid moves")
		return INVALID_TILE  # Return an invalid tile position

	current_tile_position = tilemap.base_layer.local_to_map(tilemap.base_layer.to_local(position))

	var steps_to_take: int = max(1, tiles_moved_per_turn)
	var player_tile_pos: Vector2i = get_player_tile_position()
	if player_tile_pos == INVALID_TILE or not tilemap.is_within_bounds(player_tile_pos):
		return INVALID_TILE
	var surrounding_cells: Array[Vector2i] = tilemap.base_layer.get_surrounding_cells(player_tile_pos)

	# Filter to only free/valid tiles
	var free_tiles: Array[Vector2i] = surrounding_cells.filter(func(tile): return _can_move_to_tile(tile))

	if free_tiles.is_empty():
		print("No free tiles to move to. No valid moves")
		return INVALID_TILE  # No valid tiles, return early

	free_tiles.shuffle()
	for target_tile in free_tiles:
		var path: Array[Vector2i] = _find_path(current_tile_position, target_tile)
		var next_tile: Vector2i = _get_step_tile_from_path(path, steps_to_take)
		if next_tile != INVALID_TILE:
			return next_tile

	return INVALID_TILE


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
	var next_tile = calculate_next_tile_move(tiles_per_turn)

	# Set movement target and move
	if not set_movement_target(next_tile):
		_notify_move_finished(current_tile_position)

func can_move_to_tile(tile: Vector2i) -> bool:
	return _can_move_to_tile(tile)


func can_reach_tile(tile: Vector2i) -> bool:
	if tile == INVALID_TILE:
		return false
	var path: Array[Vector2i] = _find_path(current_tile_position, tile)
	return not path.is_empty()

func _can_move_to_tile(tile: Vector2i) -> bool:
	if not tilemap or not tilemap.base_layer:
		return false
	if tile == INVALID_TILE:
		return false
	if flying:
		return tilemap.is_within_bounds(tile) and tilemap.is_tile_free(tile)
	return tilemap.is_tile_valid(tile)


func _notify_move_finished(target_tile: Vector2i):
	is_moving = false
	if tilemap and tilemap.base_layer and target_tile != INVALID_TILE:
		current_tile_position = target_tile
		position = tilemap.base_layer.map_to_local(current_tile_position)
		position.y += 1
	movement_finished.emit(current_tile_position)


func _get_step_tile_from_path(path: Array[Vector2i], steps_to_take: int) -> Vector2i:
	if path.is_empty():
		return INVALID_TILE

	# We need at least two tiles to move away from the current tile.
	if path.size() < 2:
		return INVALID_TILE

	var max_index := path.size() - 1
	var desired_index: int = clamp(steps_to_take, 1, max_index)

	var desired_tile := path[desired_index]
	if desired_tile != current_tile_position and _can_move_to_tile(desired_tile):
		return desired_tile

	# Fall back to the nearest valid step along the path.
	for i in range(desired_index - 1, 0, -1):
		var fallback_tile := path[i]
		if fallback_tile != current_tile_position and _can_move_to_tile(fallback_tile):
			return fallback_tile

	return INVALID_TILE


func _find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not tilemap or not tilemap.base_layer:
		return []
	if start == goal:
		return [start, goal]

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	came_from[start] = start
	var index: int = 0

	while index < frontier.size():
		var current: Vector2i = frontier[index]
		index += 1

		if current == goal:
			break

		for neighbor: Vector2i in _get_neighbors(current):
			if came_from.has(neighbor):
				continue
			if neighbor != goal and not _can_move_to_tile(neighbor):
				continue
			came_from[neighbor] = current
			frontier.append(neighbor)

	# Reconstruct path
	if not came_from.has(goal):
		return []

	var path: Array[Vector2i] = [goal]
	var cursor: Vector2i = goal
	while cursor != start:
		cursor = came_from[cursor]
		path.push_front(cursor)

	return path


func _get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	if not tilemap or not tilemap.base_layer:
		return []
	var neighbors: Array[Vector2i] = []
	for neighbor in tilemap.base_layer.get_surrounding_cells(tile):
		if tilemap.is_within_bounds(neighbor):
			neighbors.append(neighbor)
	return neighbors

func _on_area_2d_mouse_entered():
	super._on_area_2d_mouse_entered()
	
func _on_area_2d_mouse_exited():
	super._on_area_2d_mouse_exited()
