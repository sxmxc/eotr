class_name RiftBoss
extends MovingEnemy

const BOSS_ACTION = preload("res://scenes/enemy/bosses/boss_action.gd")
var encounter_finished := false
var feedback := 0.0
var boss_caption := ""

func _ready() -> void:
	super._ready()
	Events.player_turn_started.connect(_prepare_boss_turn)
	Events.player_died.connect(_finish_encounter)
	Events.battle_over_screen_requested.connect(_finish_encounter_from_screen)

func setup_ai() -> void:
	if is_instance_valid(enemy_action_picker):
		enemy_action_picker.queue_free()
	enemy_action_picker = EnemyActionPicker.new()
	var action := BOSS_ACTION.new()
	action.name = "Signature"
	action.intent = Intent.new()
	action.intent.icon = preload("res://assets/rift/ui/attack.svg")
	enemy_action_picker.add_child(action)
	add_child(enemy_action_picker)
	enemy_action_picker.enemy = self

func _process(delta: float) -> void:
	feedback = maxf(feedback - delta * 2.5, 0.0)
	queue_redraw()

func _prepare_boss_turn() -> void:
	if encounter_finished or is_dying or stats.health <= 0:
		return
	prepare_signature()
	update_intent()
	queue_redraw()

func prepare_signature() -> void:
	pass

func get_boss_summary() -> String:
	return boss_caption

func describe_boss_intent(plan: Intent) -> void:
	plan.current_text = "Wait"
	plan.detail_text = boss_caption

func perform_boss_turn(_action: EnemyAction, _generation: int) -> void:
	pass

func action_is_live(action: EnemyAction, generation: int) -> bool:
	return is_inside_tree() and not encounter_finished and not is_dying \
		and stats.health > 0 and action.action_generation == generation \
		and is_instance_valid(tilemap.player) and tilemap.player.stats.health > 0

func wait_for_player_effects(action: EnemyAction, generation: int) -> bool:
	while action_is_live(action, generation) and tilemap.player.pending_effects > 0:
		await get_tree().process_frame
	return action_is_live(action, generation)

func strike_player(amount: int, sound: AudioStream) -> void:
	var effect := DamageEffect.new()
	effect.source_actor = self
	effect.amount = modifier_handler.get_modified_value(amount, Enums.ModifierType.DMG_DEALT)
	effect.sound_fx = sound
	effect.execute([tilemap.player])
	feedback = 1.0

func retreat_from_collapse(action: EnemyAction, generation: int) -> bool:
	var world := get_parent().get_parent() as GameWorld
	if not world or world.rounds_until_shrink > 0 or not tilemap.get_battlemap_edge_clockwise().has(current_tile_position):
		return false
	var center := tilemap.get_center_tile_coord()
	var edge := tilemap.get_battlemap_edge_clockwise()
	var best := current_tile_position
	var distance := 999
	for cell in tilemap.base_layer.get_used_cells():
		if not can_move_to_tile(cell) or edge.has(cell):
			continue
		var d := tilemap.hex_distance(tilemap.offset_to_cube(cell), tilemap.offset_to_cube(center))
		if d < distance:
			best = cell
			distance = d
	if best != current_tile_position and set_movement_target(best):
		await movement_finished
		return action_is_live(action, generation)
	return false

func _finish_encounter() -> void:
	encounter_finished = true
	queue_redraw()

func _finish_encounter_from_screen(_text: String, _type: BattleOverPanel.Type) -> void:
	_finish_encounter()

func draw_plate(cell: Vector2i, color: Color) -> void:
	if not tilemap.is_within_bounds(cell) or tilemap.is_tile_behind_fog(cell):
		return
	var at := to_local(tilemap.cell_to_world(cell))
	var points := PackedVector2Array([
		at + Vector2(-22, -7), at + Vector2(0, -18), at + Vector2(22, -7),
		at + Vector2(22, 5), at + Vector2(0, 16), at + Vector2(-22, 5),
	])
	draw_colored_polygon(points, Color(color, 0.16))
	points.append(points[0])
	draw_polyline(points, color, 1.5, true)
