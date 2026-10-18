extends Node2D
class_name EnemyHandler

const QUEUE_ENTRY = preload("res://ui/enemy_ui/enemy_queue_entry.tscn")
const ENEMY_STATS_UI = preload("res://ui/enemy_ui/enemy_stats_ui.tscn")
const ENEMY_STATS_PREVIEW = preload("res://ui/enemy_ui/enemy_stats_preview.tscn")
const EnemyRailUI = preload("res://ui/enemy_ui/enemy_rail.gd")
# Pacing tunables for spotlighted vs batched enemy turns.
const SPOTLIGHT_TWEEN_DURATION := 0.6
const QUICK_TWEEN_DURATION := 0.18
const QUICK_RESOLVE_DELAY := 0.08
const SPOTLIGHT_POST_DELAY := 0.3
const QUICK_POST_DELAY := 0.1
const MIN_GOLD_FOR_SPOTLIGHT := 3

@export var tilemap: ProcGenTilemap

var acting_enemies: Array[Enemy] = []
var enemy_rail: EnemyRailUI
var quick_turn_enemies: Dictionary = {}
var enemy_turn_count := 0
var active_enemy: Enemy
var turn_generation := 0

func _ready() -> void:
	Events.player_died.connect(cancel_turn)
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	#Events.card_played.connect(reset_enemy_actions)
	Events.player_moved.connect(reset_enemy_actions)


func add_enemy(enemy: Enemy, tile_pos: Vector2i, summoned: bool = false) -> void:
	if not enemy:
		return
	enemy.tilemap = tilemap
	enemy.position = tilemap.base_layer.map_to_local(tile_pos)
	enemy.current_tile_position = tile_pos
	if enemy_rail:
		var entry := QUEUE_ENTRY.instantiate()
		enemy_rail.queue.add_child(entry)
		entry.bind_enemy(enemy)
	if not enemy.status_handler:
		enemy.status_handler = enemy.get_node_or_null("StatusHandler") as StatusHandler
	if not enemy.stats_ui:
		# Combat owns inspection in screen space; standalone enemy previews retain a fallback.
		var inspector: EnemyStatsUI
		if is_instance_valid(enemy_rail):
			inspector = ENEMY_STATS_UI.instantiate() as EnemyStatsUI
			enemy_rail.inspection.add_child(inspector)
		else:
			inspector = ENEMY_STATS_PREVIEW.instantiate() as EnemyStatsUI
			enemy.add_child(inspector)
		inspector.setup_enemy_ui(enemy)
		enemy.stats_ui = inspector
	if enemy.stats_ui and enemy.stats:
		enemy.stats_ui.update_stats(enemy.stats)
		enemy.stats_ui.hide()
	add_child(enemy)
	Events.enemy_spawned.emit(enemy, summoned)
	TelemetryManager.track_event("enemy_spawned", {"enemy": enemy.stats.enemy_name, "obelisk": enemy is Obelisk, "summoned": summoned})
	if enemy.status_handler:
		enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))
	if enemy is Obelisk:
		enemy.tree_exiting.connect(_obelisk_destroyed.bind(enemy))
		enemy.enemy_handler = self
	enemy.update_action()


func setup_enemies(battle_stats: EncounterDefinition, reserved_tiles: Array[Vector2i] = []) -> void:
	if not battle_stats:
		return

	cancel_turn()
	enemy_turn_count = 0
	acting_enemies.clear()
	quick_turn_enemies.clear()
	for enemy: Enemy in get_children():
		if enemy.tree_exiting.is_connected(_obelisk_destroyed.bind(enemy)):
			enemy.tree_exiting.disconnect(_obelisk_destroyed.bind(enemy))
		remove_child(enemy)
		enemy.queue_free()

	var all_new_enemies := battle_stats.enemies.instantiate()
	var reserved: Array[Vector2i] = reserved_tiles.duplicate()
	reserved.append(tilemap.get_center_tile_coord())
	if not reserved_tiles.is_empty():
		for cell in tilemap.get_surrounding_tiles_in_radius(reserved_tiles[0], battle_stats.minimum_player_distance - 1):
			if not reserved.has(cell):
				reserved.append(cell)

	for new_enemy: Node2D in all_new_enemies.get_children():
		if not (new_enemy is Enemy):
			continue
		# Transfer authored instances instead of duplicating an instantiated scene.
		all_new_enemies.remove_child(new_enemy)
		new_enemy.owner = null
		var instance := new_enemy as Enemy
		var spawn := tilemap.get_center_tile_coord() if instance is Obelisk else tilemap.get_random_valid_tile(reserved)
		add_enemy(instance, spawn)
		reserved.append(spawn)

	all_new_enemies.free()


func reset_enemy_actions(_args = null) -> void:
	for enemy in get_children():
		if not (enemy is Enemy):
			continue
		enemy.current_action = null
		enemy.update_action()


func start_turn() -> void:
	cancel_turn()
	print("Enemy turn starting")
	if get_child_count() == 0:
		Events.enemy_turn_ended.emit()
		return

	enemy_turn_count += 1
	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

	TelemetryManager.track_event("enemy_turn_started", {"turn_number": enemy_turn_count, "enemy_count": acting_enemies.size()})

	_start_next_enemy_turn()


func _start_next_enemy_turn(expected_generation: int = -1) -> void:
	if expected_generation != -1 and expected_generation != turn_generation:
		return
	var world := get_parent() as GameWorld
	if world and not world.battle_state.battle_active:
		cancel_turn()
		return
	if is_instance_valid(active_enemy):
		return
	while not acting_enemies.is_empty() and (not is_instance_valid(acting_enemies[0]) or acting_enemies[0].is_dying or acting_enemies[0].stats.health <= 0):
		acting_enemies.pop_front()
	if acting_enemies.is_empty():
		if enemy_rail:
			enemy_rail.scroll.scroll_vertical = 0
			enemy_rail.scroll.scroll_horizontal = 0
		Events.enemy_turn_ended.emit()
		print("All enemies done")
		return

	var current_enemy := acting_enemies[0]
	active_enemy = current_enemy
	turn_generation += 1
	var generation := turn_generation
	var spotlight := _requires_spotlight(current_enemy)

	_configure_enemy_camera(current_enemy, spotlight)

	if spotlight and current_enemy.stats.call_sound:
		SoundManager.play_sound(current_enemy.stats.call_sound)

	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	elif spotlight:
		await current_enemy.phantom_camera_2d.tween_completed
	else:
		await get_tree().create_timer(QUICK_RESOLVE_DELAY).timeout
	if generation != turn_generation or not is_instance_valid(current_enemy) or current_enemy.is_dying:
		return

	current_enemy.stats.block = 0
	if current_enemy.status_handler:
		current_enemy.status_handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)

func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()

func _on_enemy_statuses_applied(type: Enums.StatusType, enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy != active_enemy:
		return
	var generation := turn_generation
	match type:
		Enums.StatusType.START_OF_TURN:
			await get_tree().process_frame
			while generation == turn_generation and is_instance_valid(enemy) and enemy.pending_damage > 0:
				await get_tree().process_frame
			if generation != turn_generation or not is_instance_valid(enemy) or enemy != active_enemy or enemy.is_dying:
				return
			if enemy.stats_ui:
				enemy.stats_ui.grab_focus()
			print("Start of turn effects have been applied to %s" % enemy.name)
			enemy.do_turn()
		Enums.StatusType.END_OF_TURN:
			if enemy != active_enemy:
				return
			print("End of turn effects being applied to %s" % enemy.name)
			enemy.phantom_camera_2d.priority = 0
			if enemy.stats_ui:
				enemy.stats_ui.release_focus()
			acting_enemies.erase(enemy)
			active_enemy = null
			var quick_turn: bool = quick_turn_enemies.get(enemy.get_instance_id(), false)
			quick_turn_enemies.erase(enemy.get_instance_id())
			var delay := QUICK_POST_DELAY if quick_turn else SPOTLIGHT_POST_DELAY
			get_tree().create_timer(delay).timeout.connect(_start_next_enemy_turn.bind(generation))


func _on_enemy_died(enemy: Enemy) -> void:
	TelemetryManager.track_event("enemy_died", {"enemy": enemy.stats.enemy_name, "turn": enemy_turn_count})
	var was_active := enemy == active_enemy
	acting_enemies.erase(enemy)
	quick_turn_enemies.erase(enemy.get_instance_id())

	if was_active:
		active_enemy = null
		turn_generation += 1
		_start_next_enemy_turn.call_deferred(turn_generation)


func _on_enemy_action_completed(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy != active_enemy:
		return
	var generation := turn_generation
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player") as Player
	while generation == turn_generation and is_instance_valid(player) and player.pending_effects > 0:
		await get_tree().process_frame
	if generation == turn_generation and is_instance_valid(enemy) and enemy == active_enemy and enemy.status_handler and not enemy.is_dying:
		enemy.status_handler.apply_statuses_by_type(Enums.StatusType.END_OF_TURN)

func cancel_turn() -> void:
	turn_generation += 1
	if is_instance_valid(active_enemy):
		if is_instance_valid(active_enemy.phantom_camera_2d):
			active_enemy.phantom_camera_2d.priority = 0
		if is_instance_valid(active_enemy.stats_ui):
			active_enemy.stats_ui.release_focus()
	active_enemy = null
	acting_enemies.clear()
	quick_turn_enemies.clear()


func _obelisk_destroyed(obelisk: Obelisk) -> void:
	if not obelisk.is_dying:
		return
	# Removing a battle scene must not count as destroying its objective.
	var ancestor: Node = self
	while ancestor:
		if ancestor.is_queued_for_deletion():
			return
		ancestor = ancestor.get_parent()
	Events.obelisk_destroyed.emit()


func _requires_spotlight(enemy: Enemy) -> bool:
	if not is_instance_valid(enemy):
		return false
	if enemy is Obelisk:
		return true
	if enemy.turn_ticker == 0:
		return true
	if acting_enemies.size() <= 1:
		return true
	if enemy.stats and enemy.stats.gold_value >= MIN_GOLD_FOR_SPOTLIGHT:
		return true
	return false


func _configure_enemy_camera(enemy: Enemy, spotlight: bool) -> void:
	if not is_instance_valid(enemy):
		return

	if spotlight:
		quick_turn_enemies.erase(enemy.get_instance_id())
	else:
		quick_turn_enemies[enemy.get_instance_id()] = true

	var tween_duration := SPOTLIGHT_TWEEN_DURATION if spotlight else QUICK_TWEEN_DURATION
	enemy.phantom_camera_2d.set_tween_duration(tween_duration)
	enemy.phantom_camera_2d.priority = 20


func get_active_mobile_enemy_count() -> int:
	var count := 0
	for node in get_children():
		var active_enemy := node as Enemy
		if not active_enemy:
			continue
		if active_enemy is Obelisk:
			continue
		if not is_instance_valid(active_enemy):
			continue
		if active_enemy.is_dying or active_enemy.stats.health <= 0:
			continue
		count += 1
	return count
