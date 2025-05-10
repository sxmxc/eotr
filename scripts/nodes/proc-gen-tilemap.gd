extends Node2D
class_name ProcGenTilemap

const HIGHLIGHT_CELL_ID = Vector2i(3,1)
const CORRUPT_CELL_ID = Vector2i(1,0)
enum MapShape {
	RECTANGLE,
	DIAMOND,
	HEX_CIRCLE
}

signal tile_selected(HexTileData)
signal player_position_updated(Vector2)
signal map_generated

@export_group("Map Settings")
@export var map_width: int = 10
@export var map_height: int = 10
@export var fog_clear_radius: int = 1
@export var map_shape: MapShape = MapShape.RECTANGLE

@export_group("Tile Weights")
@export var resource_weight: int = 50
@export var corrupted_weight: int = 20
@export var ruin_weight: int = 15
@export var mana_weight: int = 10
@export var warp_weight: int = 5

@export_group("Events")

@onready var center_marker: Marker2D = $CenterMarker

var base_layer: TileMapLayer
var fog_layer: TileMapLayer
var highlight_layer : TileMapLayer
var player_position: Vector2i
var obelisk_position: Vector2i
var fog_state = {}  # Stores which tiles are cleared
var tile_map_data: Dictionary[Vector2i, HexTileData] = {}  # Stores generated tile types
var tile_dict: Dictionary[Enums.TileType, Vector2i] = {
	Enums.TileType.RESOURCE: Vector2i(0, 0),
	Enums.TileType.CORRUPTED: Vector2i(1, 0),
	Enums.TileType.ANCIENT_RUIN: Vector2i(2, 0),
	Enums.TileType.MANA_WELL: Vector2i(3, 0),
	Enums.TileType.RIFT_GATE: Vector2i(0, 1)
}
var has_generated := false
var tile_weights = {}

var player: Player
var obelisk: Enemy

func _ready():
	has_generated = false
	base_layer = $BaseLayer
	fog_layer = $FogLayer
	highlight_layer = $HightlightLayer
	player = get_tree().get_first_node_in_group("player")
	obelisk = get_tree().get_first_node_in_group("obelisk")
	if not LimboConsole.has_command("hide_fog"):
		LimboConsole.register_command(hide_fog, "hide_fog", "Hide fog layer")
	if not LimboConsole.has_command("show_fog"):
		LimboConsole.register_command(show_fog, "show_fog", "Show fog layer")

	tile_weights = {
		"RESOURCE": resource_weight,
		"CORRUPTED": corrupted_weight,
		"ANCIENT_RUIN": ruin_weight,
		"MANA_WELL": mana_weight,
		"RIFT_GATE": warp_weight
	}


func weighted_random_tile() -> Enums.TileType:
	var weight_sum := 0.0
	var tile_entries := []

	for tile_type in Enums.TileType.keys():
		weight_sum += tile_weights[tile_type]
		tile_entries.append({"tile": tile_type, "weight": weight_sum})

	var random_value := RNG.instance.randf() * weight_sum

	for entry in tile_entries:
		if random_value < entry["weight"]:
			return Enums.TileType[entry["tile"]]

	return Enums.TileType.RESOURCE  # Fallback (should never happen)


func generate_tilemap(battle_stats: BattleStats):
	base_layer.clear()
	fog_layer.clear()
	tile_map_data.clear()
	fog_state.clear()
	map_height = battle_stats.battle_field_height
	map_width = battle_stats.battle_field_width
	var rando_shape : MapShape = MapShape[RNG.array_pick_random(MapShape.keys())]
	map_shape = rando_shape

	for x in range(map_width):
		for y in range(map_height):
			var tile_position = Vector2i(x, y)
			if !is_tile_in_shape(tile_position):
				continue
			var tile_type: Enums.TileType = weighted_random_tile()
			base_layer.set_cell(tile_position, 0, tile_dict[tile_type])
			fog_layer.set_cell(tile_position, 1, Vector2i(1, 1))  # Cover with fog
			var resources := 0
			if tile_type == Enums.TileType.RESOURCE:
				resources = RNG.instance.randi_range(0, 3)
			var tile_data = HexTileData.new(tile_position, tile_type, resources)
			tile_map_data[tile_position] = tile_data
	map_generated.emit()
	has_generated = true
	center_marker.global_position = get_center_tile_global_position()


func hide_fog() -> void:
	fog_layer.hide()


func show_fog() -> void:
	fog_layer.show()


func clear_fog_around(center: Vector2i, radius: int):
	# Start with the center cell
	var current_cells = {center: true}
	var all_cells_to_clear = {center: true}

	# For each level of the radius
	for r in range(radius):
		var next_level_cells = {}

		# Get all neighbors of the current level cells
		for cell in current_cells:
			var neighbors = base_layer.get_surrounding_cells(cell)
			for neighbor in neighbors:
				if is_within_bounds(neighbor) and not all_cells_to_clear.has(neighbor):
					next_level_cells[neighbor] = true
					all_cells_to_clear[neighbor] = true

		# Move to the next level
		current_cells = next_level_cells

	#Clear fog for all collected cells with a fade effect
	for cell in all_cells_to_clear:
		if not fog_state.get(cell, false):
			# Create a tween for fading out the fog tile
			var fog_tile_data = fog_layer.get_cell_tile_data(cell)
			if fog_tile_data:
				fog_layer.erase_cell(cell)
				fog_state[cell] = true

			await get_tree().create_timer(.1).timeout




func get_tile_data(tile_pos: Vector2i) -> HexTileData:
	var tile_data = tile_map_data.get(tile_pos, null)
	if tile_data:
		return tile_data
	else:
		return null


func set_tile_data(tile_pos: Vector2i, data: HexTileData) -> void:
	tile_map_data[tile_pos] = data
	Events.tile_updated_event.emit(tile_map_data[tile_pos])


func set_resource_count(tile_pos: Vector2i, amount: int) -> void:
	var tile_data: HexTileData = tile_map_data.get(tile_pos, null)
	if !tile_data:
		return
	tile_data.resource_count = amount
	Events.tile_updated.emit(tile_data)


func get_resource_count(tile_pos: Vector2i) -> int:
	var tile_data: HexTileData = tile_map_data.get(tile_pos, null)
	if !tile_data:
		return 0
	return tile_data.resource_count


func move_player(tile_pos) -> void:
	if is_within_bounds(tile_pos):
		clear_fog_around(tile_pos, fog_clear_radius)
		player_position = tile_pos
		var tile_data = tile_map_data.get(tile_pos, null)
		tile_selected.emit(tile_data)
		Events.tile_selected.emit(tile_data)
		player_position_updated.emit(base_layer.map_to_local(player_position))


func place_obelisk(obelisk_to_place: Obelisk) -> void:
	obelisk = obelisk_to_place
	var center_tile = get_center_tile_coord()
	obelisk_position = base_layer.map_to_local(center_tile)
	obelisk.position = obelisk_position
	obelisk.current_tile_position = center_tile
	clear_fog_around(center_tile, 1)
	
func is_tile_free(tile_pos: Vector2i) -> bool:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_tile = base_layer.local_to_map(enemy.global_position)
		if enemy_tile == tile_pos:
			return false

	if obelisk != null:
		var obelisk_tile = base_layer.local_to_map(obelisk.global_position)
		if obelisk_tile == tile_pos:
			return false

	if player != null:
		var player_tile = base_layer.local_to_map(player.global_position)
		if player_tile == tile_pos:
			return false

	return true
	
func is_tile_corrupt(tile: Vector2i) -> bool:
	if !is_within_bounds(tile):
		return true
	var data : HexTileData = get_tile_data(tile)
	return data.type == Enums.TileType.CORRUPTED
	
func is_tile_in_shape(pos: Vector2i) -> bool:
	var center := Vector2i(map_width / 2, map_height / 2)

	match map_shape:
		MapShape.RECTANGLE:
			return true

		MapShape.DIAMOND:
			# Simple Manhattan distance, works for diamond-shaped patterns
			var dx = abs(pos.x - center.x)
			var dy = abs(pos.y - center.y)
			return dx + dy <= min(map_width, map_height) / 2

		MapShape.HEX_CIRCLE:
			# Convert to cube coordinates for proper hex distance
			var q = pos.x - center.x
			var r = pos.y - center.y
			var s = -q - r
			var hex_radius = min(map_width, map_height) / 2
			return max(abs(q), abs(r), abs(s)) <= int(hex_radius)

		_:
			return true

func is_within_bounds(pos: Vector2i) -> bool:
	return (
		base_layer.get_used_cells().has(pos) and
		is_tile_in_shape(pos)
	)
	
func is_tile_valid(pos: Vector2i) -> bool:
	return is_within_bounds(pos) and is_tile_free(pos) and !is_tile_corrupt(pos)

func get_surrounding_tiles_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var current_cells: Array[Vector2i] = [center]

	for r in range(radius):
			var next_level_cells : Array[Vector2i]= []

			# Get all neighbors of the current level cells
			for cell in current_cells:
				var neighbors = base_layer.get_surrounding_cells(cell)
				for neighbor in neighbors:
					if is_within_bounds(neighbor) and not tiles.has(neighbor):
						next_level_cells.append(neighbor)
						tiles.append(neighbor)

			# Move to the next level
			current_cells = next_level_cells

	return tiles
	
	
func get_battlemap_edge_clockwise() -> Array[Vector2i]:
	var valid_tiles := base_layer.get_used_cells()
	var edge_tiles: Array[Vector2i] = []
	var visited := {}
	var directions_clockwise = [
		Vector2i(1, 0),   # Right
		Vector2i(1, 1),   # Down-Right
		Vector2i(0, 1),   # Down
		Vector2i(-1, 1),  # Down-Left
		Vector2i(-1, 0),  # Left
		Vector2i(-1, -1), # Up-Left
		Vector2i(0, -1),  # Up
		Vector2i(1, -1),  # Up-Right
	]
	

	var start_tile: Vector2i
	var found := false
	for pos in valid_tiles:
		for dir in directions_clockwise:
			if not valid_tiles.has(pos + dir):
				start_tile = pos
				found = true
				break
		if found:
			break

	var current = start_tile
	var last_direction_index = 0

	while true:
		edge_tiles.append(current)
		visited[current] = true
		var next_found := false

		for i in range(8):
			var dir_index = (last_direction_index + i) % 8
			var neighbor = current + directions_clockwise[dir_index]
			if valid_tiles.has(neighbor) and not visited.has(neighbor):
				for check_dir in directions_clockwise:
					if not valid_tiles.has(neighbor + check_dir):
						current = neighbor
						last_direction_index = (dir_index + 6) % 8
						next_found = true
						break
				if next_found:
					break

		if not next_found or current == start_tile:
			break

	return edge_tiles
	
func get_center_tile_coord() -> Vector2i:
	return Vector2i(int(map_width / 2.0), int(map_height / 2.0))
	
func get_center_tile_position() -> Vector2:
	var center_tile = get_center_tile_coord()
	return base_layer.map_to_local(center_tile)

func get_center_tile_global_position() -> Vector2:
	return to_global(get_center_tile_position())
	
func get_random_valid_tile() -> Vector2i:
	var random_tile := Vector2i.ZERO
	var max_attempts := 1000

	for attempt in max_attempts:
		random_tile = Vector2i(
			RNG.instance.randi_range(0, map_width - 1),
			RNG.instance.randi_range(0, map_height - 1)
		)

		if is_within_bounds(random_tile) and is_tile_free(random_tile) and not is_tile_corrupt(random_tile):
			return random_tile

	push_error("No valid tile found after %d attempts." % max_attempts)
	return Vector2i.ZERO
	
# Convert from offset coordinates to cube coordinates
func offset_to_cube(offset: Vector2i) -> Vector3i:
	var q = offset.x
	var r = offset.y - (offset.x - (offset.x & 1)) / 2
	var s = -q - r
	return Vector3i(q, r, s)

# Convert from cube coordinates to offset coordinates
func cube_to_offset(cube: Vector3i) -> Vector2i:
	var x = cube.x
	var y = cube.y + (cube.x - (cube.x & 1)) / 2
	return Vector2i(x, y)

# Get hex distance between two positions in cube coordinates
func hex_distance(a: Vector3i, b: Vector3i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y), abs(a.z - b.z))

# Get all tiles within a certain hex distance
func get_tiles_in_range(center: Vector2i, radius: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	var center_cube = offset_to_cube(center)
	
	for q in range(-radius, radius + 1):
		for r in range(max(-radius, -q-radius), min(radius, -q+radius) + 1):
			var s = -q - r
			var cube = Vector3i(center_cube.x + q, center_cube.y + r, center_cube.z + s)
			results.append(cube_to_offset(cube))
			
	return results
	
func highlight_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		highlight_cell(cell)
		
func highlight_cell(cell: Vector2i) -> void:
	if is_within_bounds(cell):
		highlight_layer.set_cell(cell, 0, HIGHLIGHT_CELL_ID)
		
func clear_highlight() -> void:
	highlight_layer.clear()
	
	
