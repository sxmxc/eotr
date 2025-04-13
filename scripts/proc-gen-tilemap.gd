extends Node2D
class_name ProcGenTilemap

signal tile_selected(HexTileData)
signal player_position_updated(Vector2)
signal map_generated

@export_group("Map Settings")
@export var map_width: int = 10
@export var map_height: int = 10
@export var fog_clear_radius: int = 1

@export_group("Tile Weights")
@export var resource_weight: int = 50
@export var corrupted_weight: int = 20
@export var ruin_weight: int = 15
@export var mana_weight: int = 10
@export var warp_weight: int = 5

@export_group("Events")

var base_layer: TileMapLayer
var fog_layer: TileMapLayer
var player_position: Vector2i
var obilisk_position: Vector2i
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


func _ready():
	has_generated = false
	base_layer = $BaseLayer
	fog_layer = $FogLayer

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


func generate_tilemap():
	base_layer.clear()
	fog_layer.clear()
	tile_map_data.clear()
	fog_state.clear()

	for x in range(map_width):
		for y in range(map_height):
			var tile_position = Vector2i(x, y)
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


func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < map_width and pos.y < map_height


func get_tile_data(tile_pos: Vector2i) -> Dictionary:
	var tile_data = tile_map_data.get(tile_pos, null)
	if tile_data:
		return tile_data
	else:
		return {}


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


func place_obilisk() -> void:
	var obilisk: Enemy = get_tree().get_first_node_in_group("obilisk")
	var random_tile = Vector2i(
		RNG.instance.randi_range(0, map_width - 1), RNG.instance.randi_range(0, map_height - 1)
	)
	obilisk_position = base_layer.map_to_local(random_tile)
	obilisk.position = obilisk_position
	obilisk.current_tile_position = random_tile
	clear_fog_around(random_tile, fog_clear_radius)
