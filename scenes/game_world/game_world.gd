class_name GameWorld
extends Node2D

@export var battle_stats: BattleStats
@export var player_stats: PlayerStats
@export var run_stats: RunStats:
	set = set_run_stats
@export var relics: RelicHandler

@onready var tilemap: ProcGenTilemap = $Tilemap
@onready var debug_ui = $GameWorldUI/DebugUI
@onready var player: Player = $Player
@onready var game_world_ui = $GameWorldUI
@onready var hand_container = $GameWorldUI/PlayerUI/Hand/HandContainer
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var map_camera: MapCamera = $MapCamera


func _ready():
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)

	tilemap.tile_selected.connect(debug_ui._on_tile_selected)
	tilemap.player_position_updated.connect(player._on_position_updated)

	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	Events.obilisk_destroyed.connect(_on_obilisk_destroyed)

	tilemap.generate_tilemap()


func start_world() -> void:
	get_tree().paused = false

	game_world_ui.player_stats = player_stats
	player.stats = player_stats
	player_handler.relics = relics
	enemy_handler.tilemap = tilemap
	enemy_handler.setup_enemies(battle_stats)
	#enemy_handler.reset_enemy_actions()

	var player_starting_position = Vector2i(
		int(tilemap.map_width / 2.0), int(tilemap.map_height / 2.0)
	)
	tilemap.fog_clear_radius = player.stats.view_range
	tilemap.move_player(player_starting_position)
	Events.tile_selected.emit(tilemap.tile_map_data[player_starting_position])
	tilemap.place_obilisk()

	var message = WorldMessageData.new("The World has awakened!")
	Events.world_message_requested.emit(message)

	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Enums.RelicType.START_OF_COMBAT)

	get_tree().create_timer(1).timeout.connect(
		func():
			Events.world_message_requested.emit(
				WorldMessageData.new("The Obilisk has revealed itself")
			)
	)


func set_player_stats(value: PlayerStats) -> void:
	if not is_node_ready():
		await ready
	player_stats = value


func set_run_stats(value: RunStats) -> void:
	if not is_node_ready():
		await ready
	run_stats = value
	player.run_stats = run_stats


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics):
		relics.activate_relics_by_type(Enums.RelicType.END_OF_COMBAT)


func _on_obilisk_destroyed() -> void:
	relics.activate_relics_by_type(Enums.RelicType.END_OF_COMBAT)


func _on_player_died() -> void:
	Events.battle_over_screen_requested.emit("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()


func _on_relics_activated(type: Enums.RelicType) -> void:
	match type:
		Enums.RelicType.START_OF_COMBAT:
			player_handler.start_battle(player_stats)
			game_world_ui.initialize_card_pile_ui()
		Enums.RelicType.END_OF_COMBAT:
			Events.battle_over_screen_requested.emit("Victory!", BattleOverPanel.Type.WIN)
