extends Node

const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _ready() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	run.call_deferred()

func run() -> void:
	for encounter: String in ["tier_0_blobs", "tier_1_channelers_bulwark", "tier_2_void_spectre"]:
		RNG.instance.seed = 42
		var relics := RELICS.instantiate() as RelicHandler
		add_child(relics)
		var world := WORLD.instantiate() as GameWorld
		add_child(world)
		world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
		world.run_stats = RunStats.new()
		world.battle_stats = load("res://resources/data/battles/%s.tres" % encounter)
		world.relics = relics
		world.start_world()
		await get_tree().create_timer(0.2).timeout
		var cells := world.tilemap.base_layer.get_used_cells()
		var started := Time.get_ticks_usec()
		for repeat in 100:
			for cell in cells:
				world.tilemap.is_tile_free(cell)
		var occupancy_us := float(Time.get_ticks_usec() - started) / (100 * cells.size())
		started = Time.get_ticks_usec()
		var movers := 0
		for repeat in 20:
			for enemy in world.enemy_handler.get_children():
				if enemy is MovingEnemy:
					enemy.calculate_next_tile_move(1)
					movers += 1
		var movement_us := float(Time.get_ticks_usec() - started) / maxi(1, movers)
		print("Board query profile: %s cells=%d enemies=%d occupancy_us=%.2f movement_us=%.2f" % [encounter, cells.size(), world.enemy_handler.get_child_count(), occupancy_us, movement_us])
		await _test_lifecycle(world)
		world.queue_free()
		relics.queue_free()
		await get_tree().process_frame
	print("Board query tests: %d failures" % failures)
	await Utils.stop_audio_for_shutdown()
	get_tree().quit(1 if failures else 0)

func _test_lifecycle(world: GameWorld) -> void:
	var board := world.tilemap
	_test_hex_geometry(board)
	_test_sight(board)
	var occupied: Dictionary = {board.player_position: true}
	var mover: MovingEnemy
	for enemy: Enemy in world.enemy_handler.get_children():
		occupied[enemy.current_tile_position] = true
		if enemy is MovingEnemy:
			mover = enemy
	for cell in board.base_layer.get_used_cells():
		check(board.is_tile_free(cell) == not occupied.has(cell), "Cached spawn occupancy matches logical actors at %s" % cell)
		check(board.is_within_bounds(cell), "Existing terrain remains in bounds")
	check(mover != null, "Encounter supplies a moving enemy")
	if mover == null:
		return
	var origin := mover.current_tile_position
	var destination := MovingEnemy.INVALID_TILE
	for cell in board.base_layer.get_used_cells():
		if mover.can_move_to_tile(cell):
			destination = cell
			break
	check(destination != MovingEnemy.INVALID_TILE, "Encounter supplies a legal movement destination")
	if destination == MovingEnemy.INVALID_TILE:
		return
	check(mover.set_movement_target(destination), "Movement starts")
	check(not board.is_tile_free(origin) and not board.is_tile_free(destination), "Movement reserves origin and destination before animation")
	check(not mover.can_move_to_tile(board.player_position), "Movement rejects the occupied player cell")
	check(mover._find_path(origin, origin) == [origin], "No-op path remains stable")
	mover.cancel_movement()
	await get_tree().process_frame
	check(mover.current_tile_position == origin, "Cancelled deferred completion cannot commit")
	check(not board.is_tile_free(origin) and board.is_tile_free(destination), "Cancellation releases destination only")
	check(mover.set_movement_target(destination), "Movement restarts")
	await get_tree().create_timer(0.65).timeout
	check(mover.current_tile_position == destination, "Completed movement commits destination")
	check(board.is_tile_free(origin) and not board.is_tile_free(destination), "Completion releases origin only")
	mover._notify_move_finished(origin)
	# Player movement/teleport use logical cells even while their visuals are pending.
	var player_origin := board.player_position
	board.move_player(destination, false)
	check(board.is_tile_free(player_origin) and not board.is_tile_free(destination), "Player movement commits logical occupancy immediately")
	board.teleport_player(player_origin)
	check(board.is_tile_free(destination) and not board.is_tile_free(player_origin), "Teleport releases departure cell immediately")
	# Two actors in one cell must not erase one another on cleanup.
	var other := Node2D.new()
	add_child(other)
	board.register_occupant(other, origin)
	board.remove_occupant(other)
	check(not board.is_tile_free(origin), "Removing an overlapping actor preserves the enemy")
	board.register_occupant(other, destination)
	remove_child(other)
	check(board.is_tile_free(destination), "Tree exit releases occupancy synchronously")
	other.free()
	check(mover.set_movement_target(destination), "Movement reserves before death")
	mover.do_death()
	check(board.is_tile_free(origin) and board.is_tile_free(destination), "Logical death releases origin and reservation before fade")
	mover.cancel_movement()
	check(board.is_tile_free(origin), "Cancellation after death cannot re-register an actor")
	await get_tree().process_frame
	# Shrink a real board with an enemy on the first collapsing cell.
	var edge := board.get_battlemap_edge_clockwise()
	var remaining: Enemy
	for enemy: Enemy in world.enemy_handler.get_children():
		if not enemy is Obelisk and not enemy.is_dying:
			remaining = enemy
			break
	if remaining and not edge.is_empty():
		_move_player_inside(board, edge)
		remaining.current_tile_position = edge[0]
		check(not board.is_tile_free(edge[0]), "Relocation updates cache")
		await board.shrink_map(1)
		check(not board.is_within_bounds(edge[0]) and board.is_tile_free(edge[0]), "Collapse removes terrain and occupancy")
	# The spawn path must register before another summon queries the same cell.
	var summon := load("res://scenes/enemy/moving_enemy.tscn").instantiate() as MovingEnemy
	summon.stats = load("res://scenes/enemy/blob/blob_enemy.tres")
	var spawn := board.get_random_valid_tile()
	world.enemy_handler.add_enemy(summon, spawn, true)
	check(not board.is_tile_free(spawn), "Summoned actor occupies its cell immediately")
	edge = board.get_battlemap_edge_clockwise()
	if not edge.is_empty() and board.is_tile_free(edge[0]):
		_move_player_inside(board, edge)
		var safe_origin := board.get_random_valid_tile(edge)
		check(board.is_within_bounds(safe_origin) and not edge.has(safe_origin), "Reservation collapse fixture has an interior origin")
		summon._notify_move_finished(safe_origin)
		summon.flying = true
		check(summon.set_movement_target(edge[0]), "Movement reserves a collapsing destination")
		await board.shrink_map(1)
		check(not summon.is_moving and summon.current_tile_position == safe_origin, "Collapse cancels arrival on removed terrain")
		check(not board.is_tile_free(safe_origin) and board.is_tile_free(edge[0]), "Collapse preserves origin occupancy and releases destination")
		spawn = safe_origin
	world.enemy_handler.remove_child(summon)
	check(board.is_tile_free(spawn), "Removing a summoned actor releases its cell")
	summon.queue_free()
	board.generate_tilemap(world.battle_stats)
	for cell in board.base_layer.get_used_cells():
		check(board.is_tile_free(cell), "Board regeneration clears previous occupants")

func _move_player_inside(board: ProcGenTilemap, edge: Array[Vector2i]) -> void:
	for cell in board.base_layer.get_used_cells():
		if not edge.has(cell) and board.is_tile_valid(cell):
			board.move_player(cell, false)
			return
	check(false, "Collapse fixture requires a safe interior player cell")

func _test_hex_geometry(board: ProcGenTilemap) -> void:
	for center: Vector2i in [Vector2i.ZERO, Vector2i(1, 2), Vector2i(-3, -4), Vector2i(-2, 3)]:
		check(board.cube_to_offset(board.offset_to_cube(center)) == center, "Offset round trip at %s" % center)
		for neighbor: Vector2i in board.base_layer.get_surrounding_cells(center):
			check(board.cell_distance(center, neighbor) == 1, "Engine neighbors match shared hex distance")
		for radius in range(4):
			var disk := board.get_tiles_in_range(center, radius)
			var ring := board.get_tiles_in_ring(center, radius)
			check(disk.size() == 1 + 3 * radius * (radius + 1), "Hex disk cardinality")
			check(ring.size() == (1 if radius == 0 else 6 * radius), "Hex ring cardinality")
			var unique: Dictionary = {}
			for cell: Vector2i in disk:
				unique[cell] = true
				var distance := board.cell_distance(center, cell)
				check(distance <= radius and distance == board.cell_distance(cell, center), "Disk distance and symmetry")
				check(ring.has(cell) == (distance == radius), "Ring contains exactly the disk boundary")
			check(unique.size() == disk.size(), "Geometric disk contains no duplicates")
		check(board.get_tiles_in_ring(center, -1).is_empty(), "Negative radius has no ring")

func _test_sight(board: ProcGenTilemap) -> void:
	var cells := board.base_layer.get_used_cells()
	var source := board.player_position
	var target := cells[0]
	var saved_fog := board.fog_state.duplicate()
	board.fog_state.erase(target)
	check(not board.has_line_of_sight(source, target), "Hidden destination rejects sight")
	board.fog_state.clear()
	board.fog_state[target] = false
	check(board.has_line_of_sight(source, target), "Revealed destination grants sight even with other cells hidden")
	check(not board.has_line_of_sight(source, Vector2i(999, 999)), "Sight rejects absent target terrain")
	check(not board.has_line_of_sight(Vector2i(999, 999), target), "Sight rejects absent source terrain")
	board.fog_state.assign(saved_fog)
