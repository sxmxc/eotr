extends Node
class_name MapGenerator

const X_DIST := 110
const Y_DIST := 75
const PLACEMENT_RANDOMNESS := 5
const FLOORS := 15
const MAP_WIDTH := 7
const PATHS := 6
const MONSTER_NODE_WEIGHT := 10.0
const SHOP_NODE_WEIGHT := 2.5
const REST_NODE_WEIGHT := 4.0

@export var battle_stats_pool: BattleStatsPool

var random_map_node_type_weights = {
	Enums.MapNodeType.MONSTER: 0.0, Enums.MapNodeType.REST: 0.0, Enums.MapNodeType.SHOP: 0.0
}
var random_node_type_total_weight := 0
var map_data: Array[Array]


func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()

	for j in starting_points:
		var current_j := j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)

	battle_stats_pool.setup()

	_setup_boss_room()
	_setup_random_node_weights()
	_setup_map_node_types()

	return map_data


func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []

	for i in FLOORS:
		var adjacent_map_nodes: Array[MapNode] = []

		for j in MAP_WIDTH:
			var current_map_node := MapNode.new()
			var offset := Vector2(RNG.instance.randf(), RNG.instance.randf()) * PLACEMENT_RANDOMNESS
			current_map_node.position = Vector2(j * X_DIST, i * -Y_DIST) + offset
			current_map_node.row = i
			current_map_node.column = j
			current_map_node.next_nodes = []

			# Boss map_node has a non-random Y
			if i == FLOORS - 1:
				current_map_node.position.y = i * -Y_DIST

			adjacent_map_nodes.append(current_map_node)

		result.append(adjacent_map_nodes)

	return result


func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int]
	var unique_points: int = 0

	while unique_points < 2:
		unique_points = 0
		y_coordinates = []

		for i in PATHS:
			var starting_point := RNG.instance.randi_range(0, MAP_WIDTH - 1)
			if not y_coordinates.has(starting_point):
				unique_points += 1

			y_coordinates.append(starting_point)

	return y_coordinates


func _setup_connection(i: int, j: int) -> int:
	var next_map_node: MapNode = null
	var current_map_node = map_data[i][j] as MapNode

	while not next_map_node or _would_cross_existing_path(i, j, next_map_node):
		var random_j := clampi(RNG.instance.randi_range(j - 1, j + 1), 0, MAP_WIDTH - 1)
		next_map_node = map_data[i + 1][random_j]

	current_map_node.next_nodes.append(next_map_node)

	return next_map_node.column


func _would_cross_existing_path(i: int, j: int, map_node: MapNode) -> bool:
	var left_neighbour: MapNode
	var right_neighbour: MapNode

	if j > 0:  # no left neighbour at the left edge
		left_neighbour = map_data[i][j - 1]
	if j < MAP_WIDTH - 1:  # no right neighbour at the right edge
		right_neighbour = map_data[i][j + 1]

	if right_neighbour and map_node.column > j:  # can only cross in right dir if candidate is to the right
		for next_map_node: MapNode in right_neighbour.next_nodes:
			if next_map_node.column < map_node.column:
				return true

	if left_neighbour and map_node.column < j:  # can only cross if left dir if candidate is going to the left
		for next_map_node: MapNode in left_neighbour.next_nodes:
			if next_map_node.column > map_node.column:
				return true

	return false


func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH * 0.5)
	var boss_room := map_data[FLOORS - 1][middle] as MapNode

	for j in MAP_WIDTH:
		var current_map_node = map_data[FLOORS - 2][j] as MapNode
		if current_map_node.next_nodes:
			current_map_node.next_nodes = [] as Array[MapNode]
			current_map_node.next_nodes.append(boss_room)

	boss_room.type = Enums.MapNodeType.BOSS
	boss_room.battle_stats = battle_stats_pool.get_random_battle_for_tier(2)


func _setup_random_node_weights() -> void:
	random_map_node_type_weights[Enums.MapNodeType.MONSTER] = MONSTER_NODE_WEIGHT
	random_map_node_type_weights[Enums.MapNodeType.REST] = MONSTER_NODE_WEIGHT + REST_NODE_WEIGHT
	random_map_node_type_weights[Enums.MapNodeType.SHOP] = (
		MONSTER_NODE_WEIGHT + REST_NODE_WEIGHT + SHOP_NODE_WEIGHT
	)

	random_node_type_total_weight = random_map_node_type_weights[Enums.MapNodeType.SHOP]


func _setup_map_node_types() -> void:
	# first floor is always a battle
	for map_node: MapNode in map_data[0]:
		if map_node.next_nodes.size() > 0:
			map_node.type = Enums.MapNodeType.MONSTER
			map_node.battle_stats = battle_stats_pool.get_random_battle_for_tier(0)

	# 9th floor is always a treasure
	for map_node: MapNode in map_data[8]:
		if map_node.next_nodes.size() > 0:
			map_node.type = Enums.MapNodeType.TREASURE

	# last floor is always a campfire
	for map_node: MapNode in map_data[13]:
		if map_node.next_nodes.size() > 0:
			map_node.type = Enums.MapNodeType.REST

	# rest of rooms
	for current_floor in map_data:
		for map_node: MapNode in current_floor:
			for next_node: MapNode in map_node.next_nodes:
				if next_node.type == Enums.MapNodeType.NOT_ASSIGNED:
					_set_map_node_randomly(next_node)


func _set_map_node_randomly(nodes_to_set: MapNode) -> void:
	var rest_below_4 := true
	var consecutive_rest := true
	var consecutive_shop := true
	var rest_on_13 := true

	var type_candidate: Enums.MapNodeType

	while rest_below_4 or consecutive_rest or consecutive_shop or rest_on_13:
		type_candidate = _get_random_map_node_type_by_weight()

		rest_below_4 = type_candidate == Enums.MapNodeType.REST and nodes_to_set.row < 3
		consecutive_rest = (
			type_candidate == Enums.MapNodeType.REST
			and _map_node_has_parent_of_type(nodes_to_set, Enums.MapNodeType.REST)
		)
		consecutive_shop = (
			type_candidate == Enums.MapNodeType.SHOP
			and _map_node_has_parent_of_type(nodes_to_set, Enums.MapNodeType.SHOP)
		)
		rest_on_13 = type_candidate == Enums.MapNodeType.REST and nodes_to_set.row == 12

	nodes_to_set.type = type_candidate
	if type_candidate == Enums.MapNodeType.MONSTER:
		var tier_for_monster_nodes := 0 if nodes_to_set.row <= 2 else 1
		nodes_to_set.battle_stats = battle_stats_pool.get_random_battle_for_tier(
			tier_for_monster_nodes
		)


func _map_node_has_parent_of_type(map_node: MapNode, type: Enums.MapNodeType) -> bool:
	var parents: Array[MapNode] = []
	# left parent
	if map_node.column > 0 and map_node.row > 0:
		var parent_candidate := map_data[map_node.row - 1][map_node.column - 1] as MapNode
		if parent_candidate.next_nodes.has(map_node):
			parents.append(parent_candidate)
	# parent below
	if map_node.row > 0:
		var parent_candidate := map_data[map_node.row - 1][map_node.column] as MapNode
		if parent_candidate.next_nodes.has(map_node):
			parents.append(parent_candidate)
	# right parent
	if map_node.column < MAP_WIDTH - 1 and map_node.row > 0:
		var parent_candidate := map_data[map_node.row - 1][map_node.column + 1] as MapNode
		if parent_candidate.next_nodes.has(map_node):
			parents.append(parent_candidate)

	for parent: MapNode in parents:
		if parent.type == type:
			return true

	return false


func _get_random_map_node_type_by_weight() -> Enums.MapNodeType:
	var roll := RNG.instance.randf_range(0.0, random_node_type_total_weight)

	for type: Enums.MapNodeType in random_map_node_type_weights:
		if random_map_node_type_weights[type] > roll:
			return type

	return Enums.MapNodeType.MONSTER
