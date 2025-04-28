extends Node2D
class_name EnemyHandler

const ENEMY_STATS_UI = preload("res://ui/enemy_ui/enemy_stats_ui.tscn")

@export var tilemap: ProcGenTilemap

var acting_enemies: Array[Enemy] = []
var world_ui : GameWorldUI

func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.card_played.connect(reset_enemy_actions)
	Events.player_moved.connect(reset_enemy_actions)
	world_ui = get_tree().get_first_node_in_group("ui_layer") as GameWorldUI


func add_enemy(enemy: Enemy, tile_pos: Vector2i) -> void:
	var stats_panel : EnemyStatsUI = ENEMY_STATS_UI.instantiate()
	world_ui = get_tree().get_first_node_in_group("ui_layer") as GameWorldUI
	world_ui.enemy_stats_container.add_child(stats_panel)
	enemy.tilemap = tilemap
	enemy.position = tilemap.base_layer.map_to_local(tile_pos)
	enemy.current_tile_position = tile_pos
	stats_panel.setup_enemy_ui(enemy)
	add_child(enemy)
	enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))
	enemy.update_action()


func setup_enemies(battle_stats: BattleStats) -> void:
	if not battle_stats:
		return

	for enemy: Enemy in get_children():
		enemy.queue_free()

	var all_new_enemies := battle_stats.enemies.instantiate()

	for new_enemy: Node2D in all_new_enemies.get_children():
		var stats_panel : EnemyStatsUI = ENEMY_STATS_UI.instantiate()
		world_ui.enemy_stats_container.add_child(stats_panel)
		
		var new_enemy_child := new_enemy.duplicate() as Enemy
		new_enemy_child.tilemap = tilemap
		var random_tile = Vector2i(
			RNG.instance.randi_range(0, tilemap.map_width - 1), RNG.instance.randi_range(0, tilemap.map_height - 1)
		)
		new_enemy_child.position = tilemap.base_layer.map_to_local(random_tile)
		new_enemy_child.current_tile_position = random_tile
		if !stats_panel.ready:
			await stats_panel.ready
		stats_panel.setup_enemy_ui(new_enemy_child)
		add_child(new_enemy_child)
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

	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

	_start_next_enemy_turn()


func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		world_ui.enemy_stats_scroll.scroll_horizontal = 0
		Events.enemy_turn_ended.emit()
		print("All enemies done")
		return

	acting_enemies[0].phantom_camera_2d.priority = 20
	SoundManager.play_sound_random_pitch(acting_enemies[0].stats.call_sound)
	await acting_enemies[0].phantom_camera_2d.tween_completed
	acting_enemies[0].status_handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)

func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()


func _on_enemy_statuses_applied(type: Enums.StatusType, enemy: Enemy) -> void:
	match type:
		Enums.StatusType.START_OF_TURN:
			enemy.stats_ui.grab_focus()
			print("Start of turn effects have been applied to %s" % enemy.name)
			
			enemy.do_turn()
		Enums.StatusType.END_OF_TURN:
			print("End of turn effects being applied to %s" % enemy.name)
			enemy.phantom_camera_2d.priority = 0
			enemy.stats_ui.release_focus()
			acting_enemies.erase(enemy)
			get_tree().create_timer(1).timeout.connect(_start_next_enemy_turn)


func _on_enemy_died(enemy: Enemy) -> void:
	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)

	if is_enemy_turn:
		_start_next_enemy_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	enemy.status_handler.apply_statuses_by_type(Enums.StatusType.END_OF_TURN)


func _obelisk_destroyed() -> void:
	Events.obelisk_destroyed.emit()
