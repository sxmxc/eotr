class_name GameWorld
extends Node2D

const BATTLE_PRESENTATION := preload("res://ui/world_ui/battle_presentation.gd")

@export var battle_stats: BattleStats
@export var player_stats: PlayerStats
@export var run_stats: RunStats:
	set = set_run_stats
@export var relics: RelicHandler
@export var audio_playlist: AudioStreamPlaylist
@export var shrink_frequency : int = 3

@onready var tilemap: ProcGenTilemap = $Tilemap
@onready var debug_ui = $GameWorldUI/DebugUI
@onready var player: Player = $Player
@onready var game_world_ui = $GameWorldUI
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var map_camera : Camera2D = $MapCamera
@onready var world_camera: PhantomCamera2D = %WorldCamera
@onready var tutorial_ui: TutorialUI = $TutorialUI

var battle_presentation: BattlePresentation
var audio_stream_player : AudioStreamPlayer
var current_round : int : 
	set = set_current_round
var rounds_until_shrink : int :
	set = set_rounds_until_shrink
var battle_over_handled := false

func _ready():
	_ensure_battle_presentation()
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)

	tilemap.player_position_updated.connect(player._on_position_updated)
	tilemap.player_teleported.connect(player._on_player_teleported)

	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	Events.obelisk_destroyed.connect(_on_obelisk_destroyed)
	

	


func start_world() -> void:
	battle_over_handled = false
	get_tree().paused = false
	Events.enemy_died.connect(_on_enemy_died)
	audio_stream_player = SoundManager.play_music_queue(audio_playlist,1)
	audio_stream_player.stream_paused = false

	tilemap.generate_tilemap(battle_stats)

	game_world_ui.player_stats = player_stats
	player.stats = player_stats
	player_handler.relics = relics
	player_handler.tilemap = tilemap
	enemy_handler.tilemap = tilemap
	var reserved_start_tiles: Array[Vector2i] = []
	var force_start_tile := battle_stats and battle_stats.enforce_start_tile_type
	var player_starting_position := Vector2i.ZERO

	if force_start_tile:
		player_starting_position = tilemap.get_starting_tile(
			battle_stats.starting_tile_type,
			true
		)
		if tilemap.is_tile_valid(player_starting_position):
			reserved_start_tiles.append(player_starting_position)

	enemy_handler.setup_enemies(battle_stats, reserved_start_tiles)
	enemy_handler.reset_enemy_actions.call_deferred()
	current_round = 1
	rounds_until_shrink = shrink_frequency - 1
	battle_stats.enemy_gold_reward = 0
	battle_stats.enemy_resource_reward = 0

	if not force_start_tile or not tilemap.is_tile_valid(player_starting_position):
		player_starting_position = tilemap.get_starting_tile()
	if not tilemap.is_tile_valid(player_starting_position):
		player_starting_position = tilemap.get_random_valid_tile()
	tilemap.fog_clear_radius = player.stats.view_range
	tilemap.move_player(player_starting_position, false)
	tilemap.queue_start_tile_effects()
	if is_instance_valid(battle_presentation):
		battle_presentation.play_intro(audio_stream_player)
	Events.tile_selected.emit(tilemap.tile_map_data[player_starting_position])
	tilemap.place_obelisk(get_tree().get_first_node_in_group("obelisk"))
	
	var message = WorldMessageData.new(
		"The World has awakened!",
		WorldMessageData.Priority.IMPORTANT
	)
	Events.world_message_requested.emit(message)

	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Enums.RelicType.START_OF_COMBAT)

	get_tree().create_timer(1).timeout.connect(
		func():
			Events.world_message_requested.emit(
				WorldMessageData.new(
					"The Obelisk has revealed itself",
					WorldMessageData.Priority.CRITICAL
				)
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

func set_current_round(value: int) -> void:
	if not is_node_ready():
		await ready
	current_round = value
	Events.round_updated.emit(current_round)
	
func set_rounds_until_shrink(value: int) -> void:
	if not is_node_ready():
		await ready
	rounds_until_shrink = value
	Events.rounds_until_shrink_updated.emit(rounds_until_shrink)

func shrink_game_board(amount: int = 1) -> void:
	world_camera.follow_target = tilemap.center_marker
	world_camera.priority = 50
	world_camera.set_zoom(Vector2(2.5,2.5))
	Events.world_message_requested.emit(
		WorldMessageData.new(
			"The void consumes",
			WorldMessageData.Priority.CRITICAL
		)
	)
	await world_camera.tween_completed
	await tilemap.shrink_map(amount)

	world_camera.priority = 0
	world_camera.set_zoom(Vector2.ONE)
	rounds_until_shrink = shrink_frequency

func _on_enemy_turn_ended() -> void:
	if current_round % shrink_frequency == 0:
		await shrink_game_board(1)
	current_round += 1
	rounds_until_shrink -= 1
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()

func _on_enemy_died(enemy: Enemy) -> void:
	BountySystem.apply_bounty_for_enemy(run_stats, enemy.stats.enemy_name, battle_stats)

func _on_enemies_child_order_changed() -> void:
	if battle_over_handled:
		return
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics):
		relics.activate_relics_by_type(Enums.RelicType.END_OF_COMBAT)


func _on_obelisk_destroyed() -> void:
	if battle_over_handled:
		return
	var msg := WorldMessageData.new(
		"Obelisk shattered! The rift calms.",
		WorldMessageData.Priority.CRITICAL
	)
	Events.world_message_requested.emit(msg)
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_rollover)
	relics.activate_relics_by_type(Enums.RelicType.END_OF_COMBAT)


func _on_player_died() -> void:
	_handle_battle_over("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()

func _on_relics_activated(type: Enums.RelicType) -> void:
	match type:
		Enums.RelicType.START_OF_COMBAT:
			player_handler.start_battle(player_stats)
			game_world_ui.initialize_card_pile_ui()
			audio_stream_player.stream_paused = false
			tilemap.apply_start_tile_effects()
		Enums.RelicType.END_OF_COMBAT:
			_handle_battle_over("Victory!", BattleOverPanel.Type.WIN)


func _handle_battle_over(message: String, result: BattleOverPanel.Type) -> void:
	if battle_over_handled:
		return
	battle_over_handled = true
	if is_instance_valid(battle_presentation):
		call_deferred("_play_battle_outro", message, result)
		return
	_emit_battle_over(message, result)


func _play_battle_outro(message: String, result: BattleOverPanel.Type) -> void:
	if is_instance_valid(battle_presentation):
		battle_presentation.play_outro(result == BattleOverPanel.Type.WIN, audio_stream_player)
		await get_tree().create_timer(0.55).timeout
	_emit_battle_over(message, result)


func _emit_battle_over(message: String, result: BattleOverPanel.Type) -> void:
	if is_instance_valid(audio_stream_player):
		audio_stream_player.stream_paused = true
	Events.battle_over_screen_requested.emit(message, result)


func _ensure_battle_presentation() -> void:
	if battle_presentation and is_instance_valid(battle_presentation):
		return
	battle_presentation = BATTLE_PRESENTATION.new()
	add_child(battle_presentation)
