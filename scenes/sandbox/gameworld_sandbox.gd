extends Node2D
class_name GameWorldSandbox

const DEFAULT_PLAYER_STATS := preload("res://resources/data/stats/player/riftwalker_starting_stats.tres")

@export var player_stats_resource: PlayerStats = DEFAULT_PLAYER_STATS
@export var battle_stats: BattleStats
@export var run_stats: RunStats
@export var card_registry: CardRegistry
@export var encounter_registry: EncounterRegistry

@onready var tilemap: ProcGenTilemap = $Tilemap
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var player: Player = $Player
@onready var ui: DevGameWorldUI = %DevGameWorldUI
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var map_camera: MapCamera = $MapCamera
@onready var phantom_host: Node = $MapCamera/PhantomCameraHost

var player_stats: PlayerStats
var battle_started := false
var _previous_telemetry_suspended := false


func _enter_tree() -> void:
	_previous_telemetry_suspended = TelemetryManager.suspended
	TelemetryManager.suspended = true


func _exit_tree() -> void:
	TelemetryManager.suspended = _previous_telemetry_suspended


func _ready() -> void:
	if not ui.is_node_ready():
		await ui.ready
	_initialize_resources()
	await _wire_world_nodes()
	tilemap.map_generated.connect(_on_map_generated)
	tilemap.generate_tilemap(battle_stats)


func _initialize_resources() -> void:
	if player_stats_resource and player_stats_resource.has_method("create_instance"):
		player_stats = player_stats_resource.create_instance()
	else:
		player_stats = PlayerStats.new()
	if not battle_stats:
		battle_stats = BattleStats.new()
		battle_stats.battle_field_width = 11
		battle_stats.battle_field_height = 11
	if not run_stats:
		run_stats = RunStats.new()


func _wire_world_nodes() -> void:
	if not player.is_node_ready():
		await player.ready
	if ui.hand and not ui.hand.is_node_ready():
		await ui.hand.ready
	if ui.status_handler and not ui.status_handler.is_node_ready():
		await ui.status_handler.ready
	var panel := ui.dev_panel
	if panel and not panel.is_node_ready():
		await panel.ready
	var hand := ui.hand
	var status_handler := ui.status_handler
	var stats_ui := ui.stats_ui

	tilemap.fog_clear_radius = player_stats.view_range
	tilemap.player = player
	tilemap.player_position_updated.connect(player._on_position_updated)
	tilemap.player_teleported.connect(player._on_player_teleported)

	enemy_handler.tilemap = tilemap
	enemy_handler.enemy_rail = ui.enemy_rail

	player.stats = player_stats
	player.run_stats = run_stats
	if status_handler:
		player.status_handler = status_handler
	if stats_ui:
		player.stats_ui = stats_ui

	player_handler.player = player
	player_handler.player_hand = hand
	player_handler.relics = relic_handler
	player_handler.tilemap = tilemap

	ui.player = player
	ui.player_stats = player_stats
	if panel:
		panel.tilemap = tilemap
		panel.enemy_handler = enemy_handler
		panel.player_handler = player_handler
		panel.player_hand = ui.hand
		panel.player = player
		panel.battle_stats = battle_stats
		panel.map_camera = map_camera
		panel.phantom_host = phantom_host
		panel.card_registry = card_registry
		panel.encounter_registry = encounter_registry


func _on_map_generated() -> void:
	_clear_enemies()
	_position_player()
	_configure_camera_limits()
	if battle_started:
		return
	_start_battle()
	battle_started = true


func _start_battle() -> void:
	player_handler.start_battle(player_stats)
	ui.initialize_card_pile_ui()


func _position_player() -> void:
	if not battle_stats:
		return
	tilemap.fog_clear_radius = player_stats.view_range
	var start_tile := tilemap.get_starting_tile()
	if not tilemap.is_tile_valid(start_tile):
		start_tile = tilemap.get_random_valid_tile()
	tilemap.move_player(start_tile, false)
	tilemap.clear_fog_around(start_tile, tilemap.fog_clear_radius)


func _clear_enemies() -> void:
	for enemy: Enemy in enemy_handler.get_children():
		enemy.queue_free()
	enemy_handler.acting_enemies.clear()
	enemy_handler.quick_turn_enemies.clear()
	enemy_handler.enemy_turn_count = 0
	if ui.enemy_stats_container:
		for stats_panel: Control in ui.enemy_stats_container.get_children():
			stats_panel.queue_free()


func _configure_camera_limits() -> void:
	if not map_camera or not tilemap or not tilemap.base_layer:
		return
	var used_rect := tilemap.base_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return
	var corners: Array[Vector2] = [
		tilemap.base_layer.map_to_local(used_rect.position),
		tilemap.base_layer.map_to_local(used_rect.position + used_rect.size),
		tilemap.base_layer.map_to_local(used_rect.position + Vector2i(used_rect.size.x, 0)),
		tilemap.base_layer.map_to_local(used_rect.position + Vector2i(0, used_rect.size.y)),
	]
	var min_x: float = corners[0].x
	var max_x: float = corners[0].x
	var min_y: float = corners[0].y
	var max_y: float = corners[0].y
	for corner in corners:
		min_x = min(min_x, corner.x)
		max_x = max(max_x, corner.x)
		min_y = min(min_y, corner.y)
		max_y = max(max_y, corner.y)
	var padding := 96.0
	map_camera.limit_left = int(min_x - padding)
	map_camera.limit_right = int(max_x + padding)
	map_camera.limit_top = int(min_y - padding)
	map_camera.limit_bottom = int(max_y + padding)
	map_camera.position = tilemap.base_layer.map_to_local(tilemap.get_center_tile_coord())
	map_camera.clamp_position_to_limits()
