class_name MovingEnemy
extends Enemy

signal movement_finished(moved_to: Vector2i)

const INVALID_TILE: Vector2i = Vector2i(-1, -1)

@export_group("Movement")
@export var flying: bool = false
@export var move_duration: float = 0.22

@export_group("Facing")
@export var faces_right_by_default: bool = true
@export var face_player_when_idle: bool = true
@export var facing_deadzone: float = 2.0

@onready var shadow: Sprite2D = $Shadow
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_moving: bool = false
var move_tween: Tween
var previous_tile: Vector2i = INVALID_TILE
var movement_generation := 0
var movement_resting_scale := Vector2.ONE

# 1 = facing right, -1 = facing left.
var facing_direction: int = 1


func _ready() -> void:
	super._ready()
	_apply_facing()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if face_player_when_idle and not is_moving:
		face_player()


func update_enemy() -> void:
	if not stats is EnemyStats:
		return

	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.board_icon
	Utils.ground_sprite(sprite_2d)

	flying = stats.flying
	setup_ai()

	if stats_ui:
		update_stats()

	if flying:
		shadow.show()
		animation_player.play("fly_idle")

	_apply_facing()


# ---------------------------------------------------------------------------
# Facing
# ---------------------------------------------------------------------------

func set_facing_direction(direction: int) -> void:
	if direction == 0:
		return

	facing_direction = 1 if direction > 0 else -1
	_apply_facing()


func _apply_facing() -> void:
	if not sprite_2d:
		return

	sprite_2d.flip_h = (
		facing_direction < 0
		if faces_right_by_default
		else facing_direction > 0
	)


func face_world_position(target_position: Vector2) -> void:
	var difference: float = target_position.x - global_position.x

	if absf(difference) <= facing_deadzone:
		return

	set_facing_direction(1 if difference > 0.0 else -1)


func face_tile(tile: Vector2i) -> void:
	if not tilemap or not tilemap.base_layer:
		return

	if tile == INVALID_TILE:
		return

	var target_position: Vector2 = tilemap.base_layer.to_global(
		tilemap.base_layer.map_to_local(tile)
	)

	face_world_position(target_position)


func face_player() -> void:
	if not tilemap or not tilemap.base_layer:
		return

	face_tile(get_player_tile_position())


func face_attack_target(target_tile: Vector2i) -> void:
	face_tile(target_tile)


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

func set_movement_target(movement_target: Vector2i) -> bool:
	if not tilemap or not tilemap.base_layer:
		return false

	if movement_target == INVALID_TILE:
		return false

	if not _can_move_to_tile(movement_target):
		return false

	if movement_target == current_tile_position:
		return false

	var world_target: Vector2 = tilemap.base_layer.map_to_local(
		movement_target
	)

	# Face the direction of movement before starting the tween.
	face_tile(movement_target)

	cancel_movement()
	is_moving = true
	movement_resting_scale = sprite_2d.scale
	var generation := movement_generation

	if DisplayServer.get_name() == "headless":
		_finish_movement.call_deferred(movement_target, generation)
		return true

	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_SINE)
	move_tween.set_ease(Tween.EASE_OUT)
	var resting_scale := sprite_2d.scale

	move_tween.tween_property(
		sprite_2d,
		"scale",
		resting_scale * 1.04,
		Utils.presentation_duration(move_duration * 0.5)
	)

	move_tween.tween_property(
		self,
		"position",
		world_target + Vector2(0, 1),
		Utils.presentation_duration(move_duration)
	)

	move_tween.tween_property(
		sprite_2d,
		"scale",
		resting_scale,
		Utils.presentation_duration(move_duration * 0.25)
	)

	move_tween.tween_callback(
		func() -> void:
			_finish_movement(movement_target, generation)
	)

	return true


func cancel_movement() -> void:
	movement_generation += 1
	if move_tween:
		move_tween.kill()
		move_tween = null
	if not is_moving:
		return
	is_moving = false
	sprite_2d.scale = movement_resting_scale
	position = tilemap.base_layer.map_to_local(current_tile_position) + Vector2(0, 1)
	# Release waiters; their action generation rejects this cancelled move.
	movement_finished.emit(current_tile_position)


func _finish_movement(tile: Vector2i, generation: int) -> void:
	if generation == movement_generation:
		_notify_move_finished(tile)


func calculate_next_tile_move(tiles_moved_per_turn: int) -> Vector2i:
	if not tilemap or not tilemap.base_layer:
		return INVALID_TILE

	# Reverse BFS from valid engagement positions.
	var distance: Dictionary = {}
	var frontier: Array[Vector2i] = []

	var engagement_range: int = (
		stats.tactics.preferred_range
		if stats.tactics
		else 1
	)

	var engagement_cells: Array[Vector2i] = (
		tilemap.get_surrounding_tiles_in_radius(
			get_player_tile_position(),
			engagement_range
		)
	)

	if engagement_range > 1:
		var inner: Array[Vector2i] = (
			tilemap.get_surrounding_tiles_in_radius(
				get_player_tile_position(),
				engagement_range - 1
			)
		)

		engagement_cells = engagement_cells.filter(
			func(cell: Vector2i) -> bool:
				return not inner.has(cell)
		)

	for cell in engagement_cells:
		if cell == current_tile_position or _can_move_to_tile(cell):
			distance[cell] = 0
			frontier.append(cell)

	var index: int = 0

	while index < frontier.size():
		var cell: Vector2i = frontier[index]
		index += 1

		for neighbor in _get_neighbors(cell):
			if not distance.has(neighbor) and (
				neighbor == current_tile_position
				or _can_move_to_tile(neighbor)
			):
				distance[neighbor] = int(distance[cell]) + 1
				frontier.append(neighbor)

	# Avoid imminent battlefield collapse.
	var danger: Array[Vector2i] = []
	var world: GameWorld = tilemap.get_parent() as GameWorld

	if (
		world
		and world.shrink_frequency > 0
		and world.current_round % world.shrink_frequency == 0
	):
		danger = tilemap.get_battlemap_edge_clockwise()

	frontier = [current_tile_position]

	var steps: Dictionary = {
		current_tile_position: 0
	}

	index = 0

	var best: Vector2i = current_tile_position
	var best_score: float = _movement_score(
		best,
		distance,
		danger
	)

	while index < frontier.size():
		var cell: Vector2i = frontier[index]
		index += 1

		if int(steps[cell]) >= maxi(1, tiles_moved_per_turn):
			continue

		for neighbor in _get_neighbors(cell):
			if steps.has(neighbor) or not _can_move_to_tile(neighbor):
				continue

			steps[neighbor] = int(steps[cell]) + 1
			frontier.append(neighbor)

			var score: float = (
				_movement_score(neighbor, distance, danger)
				+ float(steps[neighbor]) * 0.05
			)

			if score < best_score:
				best = neighbor
				best_score = score

	return (
		INVALID_TILE
		if best == current_tile_position
		else best
	)


func _movement_score(
	cell: Vector2i,
	distances: Dictionary,
	danger: Array[Vector2i]
) -> float:
	var score: float = float(distances.get(cell, 1000))

	if cell in danger:
		score += 30.0

	if tilemap.is_tile_corrupt(cell):
		score += 10.0

	if cell == previous_tile:
		score += 1.5

	return score


func get_player_tile_position() -> Vector2i:
	if tilemap:
		return tilemap.player_position

	var player: Node2D = (
		get_tree().get_first_node_in_group("player") as Node2D
	)

	if player and tilemap and tilemap.base_layer:
		return tilemap.base_layer.local_to_map(
			tilemap.base_layer.to_local(player.global_position)
		)

	return Vector2i.ZERO


func perform_turn_based_move(tiles_per_turn: int = 1) -> void:
	var next_tile: Vector2i = calculate_next_tile_move(
		tiles_per_turn
	)

	if not set_movement_target(next_tile):
		is_moving = true
		movement_resting_scale = sprite_2d.scale
		_finish_movement.call_deferred(
			current_tile_position, movement_generation
		)


func can_move_to_tile(tile: Vector2i) -> bool:
	return _can_move_to_tile(tile)


func can_reach_tile(tile: Vector2i) -> bool:
	if tile == INVALID_TILE:
		return false

	var path: Array[Vector2i] = _find_path(
		current_tile_position,
		tile
	)

	return not path.is_empty()


func _can_move_to_tile(tile: Vector2i) -> bool:
	if not tilemap or not tilemap.base_layer:
		return false

	if tile == INVALID_TILE:
		return false

	if flying:
		return (
			tilemap.is_within_bounds(tile)
			and tilemap.is_tile_free(tile)
		)

	return tilemap.is_tile_valid(tile)


func _notify_move_finished(target_tile: Vector2i) -> void:
	is_moving = false

	if (
		tilemap
		and tilemap.base_layer
		and target_tile != INVALID_TILE
	):
		if target_tile != current_tile_position:
			previous_tile = current_tile_position

		current_tile_position = target_tile

		position = tilemap.base_layer.map_to_local(
			current_tile_position
		)
		position.y += 1

	# Turn toward the player after reaching the destination.
	if face_player_when_idle:
		face_player()

	movement_finished.emit(current_tile_position)


# ---------------------------------------------------------------------------
# Pathfinding
# ---------------------------------------------------------------------------

func _get_step_tile_from_path(
	path: Array[Vector2i],
	steps_to_take: int
) -> Vector2i:
	if path.is_empty():
		return INVALID_TILE

	if path.size() < 2:
		return INVALID_TILE

	var max_index: int = path.size() - 1
	var desired_index: int = clampi(
		steps_to_take,
		1,
		max_index
	)

	var desired_tile: Vector2i = path[desired_index]

	if (
		desired_tile != current_tile_position
		and _can_move_to_tile(desired_tile)
	):
		return desired_tile

	for i in range(desired_index - 1, 0, -1):
		var fallback_tile: Vector2i = path[i]

		if (
			fallback_tile != current_tile_position
			and _can_move_to_tile(fallback_tile)
		):
			return fallback_tile

	return INVALID_TILE


func _find_path(
	start: Vector2i,
	goal: Vector2i
) -> Array[Vector2i]:
	if not tilemap or not tilemap.base_layer:
		return []

	if start == goal:
		return [start]

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {
		start: start
	}

	var index: int = 0

	while index < frontier.size():
		var current: Vector2i = frontier[index]
		index += 1

		if current == goal:
			break

		for neighbor in _get_neighbors(current):
			if came_from.has(neighbor):
				continue

			if (
				neighbor != goal
				and not _can_move_to_tile(neighbor)
			):
				continue

			came_from[neighbor] = current
			frontier.append(neighbor)

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


# ---------------------------------------------------------------------------
# Mouse interaction
# ---------------------------------------------------------------------------

func _on_area_2d_mouse_entered() -> void:
	super._on_area_2d_mouse_entered()


func _on_area_2d_mouse_exited() -> void:
	super._on_area_2d_mouse_exited()
