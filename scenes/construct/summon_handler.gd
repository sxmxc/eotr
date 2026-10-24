class_name SummonHandler
extends Node2D

const ACTOR := preload("res://scenes/construct/construct.tscn")
const CAP := 3
var world: GameWorld
var generation := 0

static func distance(board: ProcGenTilemap, source: Vector2i, destination: Vector2i) -> int:
	return board.cell_distance(source, destination)

func living() -> Array[Construct]:
	var result: Array[Construct] = []
	for node: Node in get_children():
		if node is Construct and not node.is_dying and not node.is_queued_for_deletion():
			result.append(node)
	return result

func legal_cell(cell: Vector2i) -> bool:
	var board := world.tilemap
	return board.is_tile_valid(cell) and board.is_tile_free(cell) \
		and not board.is_tile_behind_fog(cell) and board.get_tile_data(cell).type == Enums.TileType.RESOURCE

func can_deploy(cell: Vector2i) -> bool:
	return living().size() < CAP and legal_cell(cell) \
		and distance(world.tilemap, world.tilemap.player_position, cell) <= 2

func deploy(definition: ConstructDefinition, cell: Vector2i) -> Construct:
	if not definition or not can_deploy(cell):
		return null
	var unit := ACTOR.instantiate() as Construct
	unit.definition = definition
	unit.tilemap = world.tilemap
	unit.current_tile_position = cell
	add_child(unit)
	unit.stats.stats_changed.connect(world.target_selector._reset_cache)
	unit.global_position = world.tilemap.cell_to_world(cell)
	world.tilemap.register_occupant(unit, cell)
	changed()
	return unit

func relocate(unit: Construct, cell: Vector2i) -> void:
	if not living().has(unit) or not legal_cell(cell) or distance(world.tilemap, unit.current_tile_position, cell) != 1:
		return
	unit.current_tile_position = cell
	unit.global_position = world.tilemap.cell_to_world(cell)
	world.tilemap.update_occupant(unit, cell)
	changed()

func changed() -> void:
	if not is_instance_valid(world) or not world.is_inside_tree():
		return
	world.target_selector._reset_cache()
	world.enemy_handler.reset_enemy_actions.call_deferred()

func start_turn() -> void:
	for unit in living():
		unit.stats.block = 0

func cancel() -> void:
	generation += 1

func reset() -> void:
	cancel()
	for unit in living():
		unit.destroy()

func activate_all() -> void:
	var expected := generation
	for unit in living():
		if expected != generation or not world.battle_state.battle_active:
			return
		if is_instance_valid(unit) and not unit.is_dying:
			await unit.activate()
		if not is_inside_tree() or expected != generation:
			return
		world.check_victory()

