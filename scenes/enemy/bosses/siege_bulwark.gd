extends RiftBoss

const RAM_SOUND = preload("res://assets/audio/Monster Sounds/Behemoth/Behemoth_Attack.ogg")
const OPEN_PLATING := "bulwark_open_plating"
var ram_cells: Array[Vector2i] = []
var recovering := false

func prepare_signature() -> void:
	ram_cells.clear()
	if recovering:
		boss_caption = "OPEN PLATING - takes 50% more damage. Recovery: no attack."
		return
	var cursor := current_tile_position
	var target_cube := tilemap.offset_to_cube(tilemap.player_position)
	for step in 4:
		var next := cursor
		var distance := tilemap.hex_distance(tilemap.offset_to_cube(cursor), target_cube)
		for neighbor in tilemap.base_layer.get_surrounding_cells(cursor):
			if not tilemap.is_within_bounds(neighbor):
				continue
			var d := tilemap.hex_distance(tilemap.offset_to_cube(neighbor), target_cube)
			if d < distance:
				next = neighbor
				distance = d
		if next == cursor:
			break
		ram_cells.append(next)
		cursor = next
		if cursor == tilemap.player_position:
			break
	boss_caption = "RAM - 10 damage on amber tread. Route is fixed; sidestep or block. Open plating next turn."

func describe_boss_intent(plan: Intent) -> void:
	plan.current_text = "Exposed" if recovering else "Ram 10"
	plan.detail_text = boss_caption

func get_boss_summary() -> String:
	return "OPEN PLATING: takes 50% more damage. Recovery: no attack." if recovering else "COMMITTED RAM 10: sidestep the amber tread or block. Open plating follows."

func _set_recovering(value: bool) -> void:
	recovering = value
	var modifier := modifier_handler.get_modifier(Enums.ModifierType.DMG_TAKEN)
	modifier.remove_value(OPEN_PLATING)
	if value:
		var exposed := ModifierValue.create_new_modifier(OPEN_PLATING, Enums.ModifierValueType.PERCENT_BASED)
		exposed.percent_value = 0.5
		modifier.add_new_value(exposed)

func perform_boss_turn(action: EnemyAction, generation: int) -> void:
	if await retreat_from_collapse(action, generation):
		ram_cells.clear()
		_set_recovering(true)
		return
	if not action_is_live(action, generation):
		return
	if recovering:
		_set_recovering(false)
		return
	feedback = 1.0
	await get_tree().create_timer(Utils.presentation_duration(0.25)).timeout
	if not action_is_live(action, generation):
		return
	var hits_player := ram_cells.has(tilemap.player_position) and tilemap.is_within_bounds(tilemap.player_position)
	var destination := current_tile_position
	for cell in ram_cells:
		if not tilemap.is_within_bounds(cell):
			break
		if can_move_to_tile(cell):
			destination = cell
		if tilemap.get_tile_data(cell).type == Enums.TileType.RESOURCE:
			tilemap.set_resource_count(cell, 0)
	if destination != current_tile_position and set_movement_target(destination):
		await movement_finished
	if action_is_live(action, generation):
		if hits_player:
			strike_player(10, RAM_SOUND)
		else:
			SoundManager.play_sound(RAM_SOUND)
		_set_recovering(true)
		ram_cells.clear()
		boss_caption = "OPEN PLATING - takes 50% more damage until recovery ends."
		update_intent()

func _draw() -> void:
	if not is_instance_valid(tilemap) or is_dying or encounter_finished:
		return
	for cell in ram_cells:
		draw_plate(cell, Color(0.92, 0.65, 0.28))
		var at := to_local(tilemap.cell_to_world(cell))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-12, -3), at + Vector2(0, 5), at + Vector2(12, -3), at + Vector2(0, 12)]), Color(0.96, 0.74, 0.4, 0.65))
	if recovering:
		for side in [-1, 1]:
			var at := Vector2(side * 24, -32)
			draw_colored_polygon(PackedVector2Array([at, at + Vector2(side * 13, -20), at + Vector2(side * 16, 18)]), Color(0.95, 0.86, 0.59, 0.65))
