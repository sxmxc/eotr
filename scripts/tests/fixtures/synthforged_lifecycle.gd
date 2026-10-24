class_name SynthforgedLifecycleFixture
extends RefCounted
## Controlled setup, real actor attacks, turn sequencing and authoritative collapse.
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run(world: GameWorld, capture: Callable = Callable()) -> Array[String]:
	var board := world.tilemap
	board.hide_fog()
	world.player_stats.block = 999
	var primary := world.enemy_handler.get_child(0) as Enemy
	primary.stats.max_health = 1000
	primary.stats.health = 1000
	var deployment := Vector2i(-999, -999)
	var enemy_cell := deployment
	world.summons.reset()
	await world.get_tree().process_frame
	for cell in board.get_surrounding_tiles_in_radius(board.player_position, 2):
		if not world.summons.can_deploy(cell): continue
		for neighbor in board.base_layer.get_surrounding_cells(cell):
			if board.is_tile_valid(neighbor) and board.is_tile_free(neighbor) and SummonHandler.distance(board, neighbor, board.player_position) > 1:
				deployment = cell
				enemy_cell = neighbor
				break
		if deployment != Vector2i(-999, -999): break
	check(deployment != Vector2i(-999, -999), "Lifecycle fixture supplies deployment and hostile cells")
	if deployment == Vector2i(-999, -999): return failures
	var hostile := preload("res://scenes/enemy/moving_enemy.tscn").instantiate() as MovingEnemy
	hostile.stats = load("res://scenes/enemy/blob/blob_enemy.tres")
	world.enemy_handler.add_enemy(hostile, enemy_cell)
	hostile.stats.max_health = 1000
	hostile.stats.health = 1000
	var last: Construct
	for id: String in ["sentry", "pike", "bastion", "siege_platform"]:
		world.summons.reset()
		await world.get_tree().process_frame
		last = world.summons.deploy(load("res://resources/data/constructs/%s.tres" % id), deployment)
		check(last != null, "Deploy construct identity: " + id)
		if not last: continue
		check(last.definition.texture != null and last.sprite_2d.texture == last.definition.texture, "Imported construct artwork is bound: " + id)
		var target := last.attack_target()
		check(target != null, "Construct has legal attack target: " + id)
		if not target: continue
		var before := target.stats.health
		if capture.is_valid(): capture.call("construct-" + id, "attack", 0.06)
		await last.activate()
		check(target.stats.health < before, "Actual construct attack: " + id)
		if capture.is_valid(): await world.get_tree().create_timer(0.3).timeout
	if not last: return failures
	await world.get_tree().process_frame
	hostile.enemy_action_picker.refresh_target()
	check(hostile.enemy_action_picker.target == last, "Ordinary hostile targets nearer construct")
	for action: EnemyAction in hostile.enemy_action_picker.get_children():
		if action.get_script().resource_path.ends_with("blob_attack_action.gd"):
			hostile.current_action = action
	var before := last.stats.health
	if capture.is_valid():
		last.damage_taken.connect(func(_amount: int): capture.call("enemy-construct", "contact", 0.02))
	world.player_handler.hand_ready = true
	var starting_round := world.current_round
	var phases: Array[int] = []
	var allied_target := last.attack_target()
	var allied_health := allied_target.stats.health if allied_target else 0
	var phase_callback := func(phase: int):
		phases.append(phase)
		if phase == BattleStateController.Phase.ENEMY_TURN and is_instance_valid(allied_target):
			check(allied_target.stats.health < allied_health, "Previously activated construct still attacks before enemies")
	world.battle_state.phase_changed.connect(phase_callback)
	Events.player_turn_ended.emit()
	var deadline := Time.get_ticks_msec() + 10000
	while world.current_round == starting_round and world.battle_state.battle_active and Time.get_ticks_msec() < deadline:
		await world.get_tree().process_frame
	world.battle_state.phase_changed.disconnect(phase_callback)
	check(phases.has(BattleStateController.Phase.ALLY_TURN) and phases.has(BattleStateController.Phase.ENEMY_TURN), "Turn cleanup includes allied phase before enemies")
	if phases.has(BattleStateController.Phase.ALLY_TURN) and phases.has(BattleStateController.Phase.ENEMY_TURN):
		check(phases.find(BattleStateController.Phase.ALLY_TURN) < phases.find(BattleStateController.Phase.ENEMY_TURN), "Allied actions precede enemy actions")
	check(not is_instance_valid(last) or last.stats.health < before, "Real enemy phase damages construct")
	world.enemy_handler.cancel_turn()
	world.player_handler.cancel_turn()
	world.player_handler.player_turn_count = 3
	world.player_handler.start_turn()
	check(world.player_stats.energy == 5, "Real turn-start Overclock grants +2 after reset")
	if capture.is_valid():
		capture.call("overclock", "contact", 0.08)
		await world.get_tree().create_timer(0.4).timeout
	world.player_handler.cancel_turn()
	world.summons.reset()
	await world.get_tree().process_frame
	var edge := board.get_battlemap_edge_clockwise()
	edge.sort_custom(func(a: Vector2i, b: Vector2i): return SummonHandler.distance(board, a, board.player_position) < SummonHandler.distance(board, b, board.player_position))
	var falling: Construct
	for cell in edge:
		if not board.is_tile_free(cell): continue
		for inner in board.base_layer.get_surrounding_cells(cell):
			if board.is_tile_valid(inner) and not edge.has(inner) and board.is_tile_free(inner):
				board.tile_map_data[cell].type = Enums.TileType.RESOURCE
				board.move_player(inner, false)
				board.hide_fog()
				falling = world.summons.deploy(load("res://resources/data/constructs/pike.tres"), cell)
				break
		if falling: break
	check(falling != null, "Collapse fixture deploys on an endangered tile")
	if falling:
		var cell := falling.current_tile_position
		falling.stats.block = 999
		var movement_deadline := Time.get_ticks_msec() + 3000
		while world.player.pending_effects > 0 and Time.get_ticks_msec() < movement_deadline:
			await world.get_tree().process_frame
		if capture.is_valid():
			world.world_camera.frame_battle(true)
			await world.get_tree().create_timer(0.4).timeout
		if capture.is_valid(): capture.call("collapse-construct", "before", 0.0)
		await board.shrink_map(1)
		check(not is_instance_valid(falling) or falling.is_dying, "Collapse destroys construct regardless of block")
		check(board.is_tile_free(cell) and not board.is_tile_valid(cell), "Collapse releases occupancy and erases terrain")
		if capture.is_valid():
			capture.call("collapse-construct", "after", 0.0)
			await world.get_tree().create_timer(0.3).timeout
	return failures
