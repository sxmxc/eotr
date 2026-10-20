extends EnemyAction

func is_performable() -> bool:
	var mover := enemy as MovingEnemy
	if not mover or not mover.tilemap:
		return false
	var world := mover.tilemap.get_parent() as GameWorld
	return world != null and world.shrink_frequency > 0 and world.current_round % world.shrink_frequency == 0 and mover.current_tile_position in mover.tilemap.get_battlemap_edge_clockwise() and mover.calculate_next_tile_move(2) != MovingEnemy.INVALID_TILE

func perform_action() -> void:
	var generation := action_generation
	var mover := enemy as MovingEnemy
	mover.perform_turn_based_move(2)
	await mover.movement_finished
	if generation == action_generation:
		Events.enemy_action_completed.emit(mover)
