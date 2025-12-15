extends Node2D
class_name EnemyHandler

const ENEMY_STATS_UI = preload("res://ui/enemy_ui/enemy_stats_ui.tscn")
const ENEMY_STATS_UI_SCALE := Vector2(0.75, 0.75)
const ENEMY_STATS_UI_OFFSET := Vector2(0, -42)
# Pacing tunables for spotlighted vs batched enemy turns.
const SPOTLIGHT_TWEEN_DURATION := 0.6
const QUICK_TWEEN_DURATION := 0.18
const QUICK_RESOLVE_DELAY := 0.08
const SPOTLIGHT_POST_DELAY := 0.3
const QUICK_POST_DELAY := 0.1
const MIN_GOLD_FOR_SPOTLIGHT := 3

@export var tilemap: ProcGenTilemap

var acting_enemies: Array[Enemy] = []
var world_ui: CanvasLayer
var quick_turn_enemies: Dictionary = {}
var enemy_turn_count := 0

func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	#Events.card_played.connect(reset_enemy_actions)
	Events.player_moved.connect(reset_enemy_actions)
	world_ui = get_tree().get_first_node_in_group("ui_layer") as CanvasLayer


func add_enemy(enemy: Enemy, tile_pos: Vector2i) -> void:
	if not enemy:
		return
	world_ui = get_tree().get_first_node_in_group("ui_layer") as CanvasLayer
	if world_ui and world_ui.enemy_stats_container:
		var queue_button := _build_queue_button(enemy)
		world_ui.enemy_stats_container.add_child(queue_button)
		enemy.tree_exiting.connect(queue_button.queue_free)
		enemy.set_queue_button(queue_button)
		enemy.queue_button = queue_button
	enemy.tilemap = tilemap
	enemy.position = tilemap.base_layer.map_to_local(tile_pos)
	enemy.current_tile_position = tile_pos
	if not enemy.status_handler:
		enemy.status_handler = enemy.get_node_or_null("StatusHandler") as StatusHandler
	if not enemy.stats_ui:
		# attach a floating intent/stats UI to the enemy itself so sandbox works without the queue
		var floating_ui := ENEMY_STATS_UI.instantiate() as EnemyStatsUI
		floating_ui.position = ENEMY_STATS_UI_OFFSET
		floating_ui.scale = ENEMY_STATS_UI_SCALE
		enemy.add_child(floating_ui)
		floating_ui.setup_enemy_ui(enemy)
		enemy.stats_ui = floating_ui
	if enemy.stats_ui and enemy.stats:
		enemy.stats_ui.update_stats(enemy.stats)
		enemy.stats_ui.hide()
	add_child(enemy)
	if enemy.status_handler:
		enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))
	enemy.update_action()


func setup_enemies(battle_stats: BattleStats, reserved_tiles: Array[Vector2i] = []) -> void:
	if not battle_stats:
		return

	enemy_turn_count = 0
	for enemy: Enemy in get_children():
		enemy.queue_free()

	var all_new_enemies := battle_stats.enemies.instantiate()

	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		new_enemy_child.tilemap = tilemap
		var random_tile = tilemap.get_random_valid_tile(reserved_tiles)
		new_enemy_child.position = tilemap.base_layer.map_to_local(random_tile)
		new_enemy_child.current_tile_position = random_tile
		if world_ui and world_ui.enemy_stats_container:
			var queue_button := _build_queue_button(new_enemy_child)
			world_ui.enemy_stats_container.add_child(queue_button)
			new_enemy_child.tree_exiting.connect(queue_button.queue_free)
			new_enemy_child.set_queue_button(queue_button)
			new_enemy_child.queue_button = queue_button
		if not new_enemy_child.status_handler:
			new_enemy_child.status_handler = new_enemy_child.get_node_or_null("StatusHandler") as StatusHandler
		if not new_enemy_child.stats_ui:
			var floating_ui := ENEMY_STATS_UI.instantiate() as EnemyStatsUI
			floating_ui.position = ENEMY_STATS_UI_OFFSET
			floating_ui.scale = ENEMY_STATS_UI_SCALE
			new_enemy_child.add_child(floating_ui)
			floating_ui.setup_enemy_ui(new_enemy_child)
			new_enemy_child.stats_ui = floating_ui
		if new_enemy_child.stats_ui and new_enemy_child.stats:
			new_enemy_child.stats_ui.update_stats(new_enemy_child.stats)
		add_child(new_enemy_child)
		if new_enemy_child.status_handler:
			new_enemy_child.status_handler.statuses_applied.connect(
				_on_enemy_statuses_applied.bind(new_enemy_child)
			)
		if new_enemy is Obelisk:
			new_enemy_child.tree_exited.connect(_obelisk_destroyed)
			new_enemy_child.enemy_handler = self

	all_new_enemies.queue_free()


func reset_enemy_actions(_args = null) -> void:
	for enemy: Enemy in get_children():
		enemy.current_action = null
		enemy.update_action()


func start_turn() -> void:
	print("Enemy turn starting")
	if get_child_count() == 0:
		return

	enemy_turn_count += 1
	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

	if Talo.current_player:
		var event_props := {
			"turn_number": enemy_turn_count,
			"enemy_count": acting_enemies.size(),
		}
		Talo.events.track("enemy_turn_started", event_props)

	_start_next_enemy_turn()


func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		if not world_ui:
			world_ui = get_tree().get_first_node_in_group("ui_layer") as CanvasLayer
		if world_ui and world_ui.enemy_stats_scroll:
			world_ui.enemy_stats_scroll.scroll_vertical = 0
			world_ui.enemy_stats_scroll.scroll_horizontal = 0
		Events.enemy_turn_ended.emit()
		print("All enemies done")
		return

	var current_enemy := acting_enemies[0]
	var spotlight := _requires_spotlight(current_enemy)

	_configure_enemy_camera(current_enemy, spotlight)

	if spotlight and current_enemy.stats.call_sound:
		SoundManager.play_sound(current_enemy.stats.call_sound)

	if spotlight:
		await current_enemy.phantom_camera_2d.tween_completed
	else:
		await get_tree().create_timer(QUICK_RESOLVE_DELAY).timeout

	current_enemy.stats.block = 0
	if current_enemy.status_handler:
		current_enemy.status_handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)

func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()

func _on_enemy_statuses_applied(type: Enums.StatusType, enemy: Enemy) -> void:
	match type:
		Enums.StatusType.START_OF_TURN:
			if enemy.stats_ui:
				enemy.stats_ui.grab_focus()
			print("Start of turn effects have been applied to %s" % enemy.name)
			enemy.do_turn()
		Enums.StatusType.END_OF_TURN:
			print("End of turn effects being applied to %s" % enemy.name)
			enemy.phantom_camera_2d.priority = 0
			if enemy.stats_ui:
				enemy.stats_ui.release_focus()
			acting_enemies.erase(enemy)
			var quick_turn: bool = quick_turn_enemies.get(enemy.get_instance_id(), false)
			quick_turn_enemies.erase(enemy.get_instance_id())
			var delay := QUICK_POST_DELAY if quick_turn else SPOTLIGHT_POST_DELAY
			get_tree().create_timer(delay).timeout.connect(_start_next_enemy_turn)


func _on_enemy_died(enemy: Enemy) -> void:
	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	quick_turn_enemies.erase(enemy.get_instance_id())

	if is_enemy_turn:
		_start_next_enemy_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	if enemy.status_handler:
		enemy.status_handler.apply_statuses_by_type(Enums.StatusType.END_OF_TURN)


func _obelisk_destroyed() -> void:
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


func _build_queue_button(enemy: Enemy) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(200, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.text = _format_queue_label(enemy)
	button.pressed.connect(func():
		Events.enemy_selected.emit(enemy)
	)
	button.mouse_entered.connect(func():
		if enemy:
			enemy._on_queue_button_entered()
	)
	button.mouse_exited.connect(func():
		if enemy:
			enemy._on_queue_button_exited()
	)
	if enemy.stats:
		if not enemy.stats.stats_changed.is_connected(func(): button.text = _format_queue_label(enemy)):
			enemy.stats.stats_changed.connect(func(): button.text = _format_queue_label(enemy))
	return button


func _format_queue_label(enemy: Enemy) -> String:
	var stats := enemy.stats
	var enemy_name: String = enemy.name
	if stats and stats.enemy_name:
		enemy_name = stats.enemy_name
	if not stats:
		return enemy_name
	var block_suffix: String = ""
	if stats.block > 0:
		block_suffix = " +" + str(stats.block)
	return "%s %d/%d%s" % [enemy_name, stats.health, stats.max_health, block_suffix]


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
		count += 1
	return count
