class_name Obelisk
extends Enemy

const MOVING_ENEMY_SCENE = preload("res://scenes/enemy/moving_enemy.tscn")
const SHATTER_EMBER_FX := preload("res://ui/fx/ember_burst_fx.tscn")
const OBELISK_SPAWN_ACTION_SCRIPT := preload("res://scenes/enemy/obelisk/obelisk_spawn_action.gd")

@export var spawn_pool: Array[EnemyStats]
@export var enemy_handler: EnemyHandler
@export_range(1, 6) var spawn_search_radius := 2
@export_range(1, 6) var preview_spawn_count := 3

var spawn_tile_queue: Array[Vector2i] = []
var telegraph_tiles: Array[Vector2i] = []
var damage_taken_this_encounter := false


func _ready() -> void:
	super._ready()
	if not damage_taken.is_connected(_on_damage_taken):
		damage_taken.connect(_on_damage_taken)
	call_deferred("_initialize_spawn_tiles")


func spawn_enemy(_enemy: Enemy) -> void:
	pass


func spawn_random_enemy() -> bool:
	if not _ensure_spawn_tiles():
		return false

	var spawn_tile = _next_spawn_tile()
	if spawn_tile == null:
		return false

	var new_spawn = MOVING_ENEMY_SCENE.instantiate()
	new_spawn.stats = RNG.array_pick_random(spawn_pool) as EnemyStats
	new_spawn.name = new_spawn.stats.enemy_name
	enemy_handler.add_enemy(new_spawn, spawn_tile)
	var world_message = WorldMessageData.new(
		"Obelisk spawns a %s from the void" % new_spawn.stats.enemy_name,
		WorldMessageData.Priority.IMPORTANT
	)
	Events.world_message_requested.emit(world_message)
	_refresh_spawn_tiles()
	return true

func do_death() -> void:
	if not _begin_death_sequence():
		return
	Talo.stats.track("obelisks_destroyed")
	if SHATTER_EMBER_FX:
		var shatter_fx := SHATTER_EMBER_FX.instantiate() as VisualFX
		shatter_fx.scale = Vector2(1.2, 1.2)
		add_child(shatter_fx)
		shatter_fx.execute()
	if is_instance_valid(phantom_camera_2d):
		var cam := phantom_camera_2d
		cam.set_tween_duration(0.5)
		cam.priority = 30
		var cam_tween := cam.create_tween()
		cam_tween.tween_property(cam, "zoom", Vector2(2.0, 2.0), 0.35)
		cam_tween.tween_interval(0.15)
		cam_tween.tween_property(cam, "zoom", Vector2(2.4, 2.4), 0.2)
		cam_tween.tween_property(cam, "zoom", Vector2(3, 3), 0.35)
		cam_tween.tween_callback(func(): cam.priority = 1)
	_clear_spawn_telegraph()
	_fade_out_and_queue_free(0.25)

func _on_area_2d_mouse_entered():
	super._on_area_2d_mouse_entered()
	
func _on_area_2d_mouse_exited():
	super._on_area_2d_mouse_exited()


func has_taken_damage() -> bool:
	return damage_taken_this_encounter


func has_viable_spawn_tile() -> bool:
	return _ensure_spawn_tiles()


func peek_next_spawn_tile():
	if not _ensure_spawn_tiles():
		return null
	if spawn_tile_queue.is_empty():
		return null
	return spawn_tile_queue[0]


func _on_damage_taken(_amount: int) -> void:
	damage_taken_this_encounter = true


func _initialize_spawn_tiles() -> void:
	_refresh_spawn_tiles()


func _refresh_spawn_tiles() -> void:
	if not tilemap:
		return
	_rebuild_spawn_tile_queue()
	_update_spawn_telegraph()


func _ensure_spawn_tiles() -> bool:
	if not tilemap:
		return false
	_prune_spawn_tile_queue()
	if spawn_tile_queue.is_empty():
		_rebuild_spawn_tile_queue()
	_update_spawn_telegraph()
	return not spawn_tile_queue.is_empty()


func _next_spawn_tile():
	_prune_spawn_tile_queue()
	if spawn_tile_queue.is_empty():
		return null
	var next_tile = spawn_tile_queue[0]
	spawn_tile_queue.remove_at(0)
	return next_tile


func _prune_spawn_tile_queue() -> void:
	if not tilemap:
		return
	for i in range(spawn_tile_queue.size() - 1, -1, -1):
		if not tilemap.is_tile_valid(spawn_tile_queue[i]):
			spawn_tile_queue.remove_at(i)


func _rebuild_spawn_tile_queue() -> void:
	if not tilemap:
		return
	var possible_tiles = tilemap.get_surrounding_tiles_in_radius(current_tile_position, spawn_search_radius)
	var valid_tiles: Array[Vector2i] = []
	for tile in possible_tiles:
		if tilemap.is_tile_valid(tile):
			valid_tiles.append(tile)
	valid_tiles.sort_custom(Callable(self, "_spawn_tile_sorter"))
	if preview_spawn_count > 0 and valid_tiles.size() > preview_spawn_count:
		valid_tiles = valid_tiles.slice(0, preview_spawn_count)
	spawn_tile_queue = valid_tiles


func _spawn_tile_sorter(a: Vector2i, b: Vector2i) -> bool:
	var origin = Vector2(current_tile_position)
	var offset_a = Vector2(a) - origin
	var offset_b = Vector2(b) - origin
	var angle_a = offset_a.angle()
	var angle_b = offset_b.angle()
	if not is_equal_approx(angle_a, angle_b):
		return angle_a < angle_b
	return offset_a.length_squared() < offset_b.length_squared()


func _update_spawn_telegraph() -> void:
	if not tilemap:
		return
	_clear_spawn_telegraph()
	if preview_spawn_count <= 0:
		return
	if not _should_show_spawn_telegraph():
		return
	var count = min(preview_spawn_count, spawn_tile_queue.size())
	for i in range(count):
		var cell = spawn_tile_queue[i]
		tilemap.highlight_cell(cell)
		telegraph_tiles.append(cell)


func _clear_spawn_telegraph() -> void:
	if not tilemap:
		return
	for cell in telegraph_tiles:
		tilemap.clear_highlight_cell(cell)
	telegraph_tiles.clear()


func _should_show_spawn_telegraph() -> bool:
	var spawn_action: EnemyAction = _get_spawn_action()
	if not spawn_action:
		return false

	var has_spawn_tile := not spawn_tile_queue.is_empty()
	if not has_spawn_tile:
		return false

	var next_turn: int = turn_ticker + 1
	var damage_override: bool = spawn_action.allow_damage_override and damage_taken_this_encounter
	var meets_min_turns: bool = next_turn >= spawn_action.minimum_turns_before_spawn or damage_override
	var frequency_ready: bool = spawn_action.spawn_turn_freq > 0 and (next_turn % spawn_action.spawn_turn_freq == 0)

	if not meets_min_turns or not frequency_ready:
		return false

	if enemy_handler and enemy_handler.get_active_mobile_enemy_count() >= spawn_action.live_enemy_cap:
		return false

	return true


func _get_spawn_action():
	if not enemy_action_picker:
		return null
	for action in enemy_action_picker.get_children():
		if action and action.get_script() == OBELISK_SPAWN_ACTION_SCRIPT:
			return action as EnemyAction
	return null
