class_name GameWorld
extends Node2D

@export var battle_stats: EncounterDefinition
@export var player_stats: PlayerStats
@export var run_stats: RunStats:
	set = set_run_stats
@export var relics: RelicHandler
@export var audio_playlist: AudioStreamPlaylist
@export var shrink_frequency : int = 3

@onready var tilemap: ProcGenTilemap = $Tilemap
@onready var player: Player = $Player
@onready var game_world_ui = $GameWorldUI
@onready var debug_ui = game_world_ui.debug_ui
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var card_interaction: CardInteractionController = $CardInteractionController
@onready var target_selector: TargetSelector = $CardTargetSelector
@onready var battle_state: BattleStateController = $BattleState
@onready var map_camera : Camera2D = $MapCamera
@onready var world_camera = %WorldCamera
@onready var tutorial_ui: TutorialUI = $TutorialUI
@onready var battle_presentation: BattlePresentation = $BattlePresentation

var audio_stream_player : AudioStreamPlayer
var current_round : int : 
	set = set_current_round
var rounds_until_shrink : int :
	set = set_rounds_until_shrink
var battle_over_handled := false
var victory_committed := false
var initial_health := 0
var initial_health_damage := 0
var initial_healing := 0
var encounter_started_ms := 0

func _ready():
	card_interaction.bind_world(self)
	game_world_ui.hand.interaction_controller = card_interaction
	game_world_ui.bind_world(player, tilemap, map_camera)
	player_handler.player_hand = game_world_ui.hand
	player.stats_ui = game_world_ui.stats_ui
	enemy_handler.enemy_rail = game_world_ui.enemy_rail
	player.status_handler = game_world_ui.status_handler
	game_world_ui.status_handler.status_owner = player
	game_world_ui.tutorial_ui = tutorial_ui
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	battle_state.shrink_frequency = shrink_frequency

	tilemap.player_position_updated.connect(player._on_position_updated)
	tilemap.player_teleported.connect(player._on_player_teleported)

	Events.player_died.connect(_on_player_died)
	Events.obelisk_destroyed.connect(_on_obelisk_destroyed)
	

	


func start_world() -> void:
	encounter_started_ms = Time.get_ticks_msec()
	# Definitions stay immutable; reward counters belong to this combat instance.
	battle_stats = battle_stats.duplicate()
	shrink_frequency = battle_stats.collapse_frequency
	battle_over_handled = false
	victory_committed = false
	battle_state.end_battle()
	battle_state.shrink_frequency = shrink_frequency
	get_tree().paused = false
	Events.enemy_died.connect(_on_enemy_died)
	initial_health = player_stats.health
	initial_health_damage = player_stats.total_health_damage
	initial_healing = player_stats.total_healing
	TelemetryManager.track_event("encounter_started", {"encounter": battle_stats.get_encounter_id(), "width": battle_stats.battle_field_width, "height": battle_stats.battle_field_height})
	audio_stream_player = SoundManager.play_music_queue(audio_playlist,1)
	audio_stream_player.stream_paused = false

	tilemap.generate_tilemap(battle_stats)
	if run_stats and run_stats.act_index < ActDefinition.campaign().size():
		var act := ActDefinition.campaign()[run_stats.act_index]
		$ActEnvironment/Illustration.texture = act.background
		$ParallaxBackgroundNode.visible = act.background == null
		if act.music:
			audio_stream_player.stream = battle_stats.boss_music if battle_stats.boss_music else act.music
			audio_stream_player.play()

	game_world_ui.player_stats = player_stats
	player.stats = player_stats
	if not player_stats.stats_changed.is_connected(target_selector._reset_cache):
		player_stats.stats_changed.connect(target_selector._reset_cache)
	if not player_stats.stats_changed.is_connected(enemy_handler.refresh_enemy_intents):
		player_stats.stats_changed.connect(enemy_handler.refresh_enemy_intents)
	player_handler.relics = relics
	player_handler.tilemap = tilemap
	enemy_handler.tilemap = tilemap
	var reserved_start_tiles: Array[Vector2i] = []
	var force_start_tile := battle_stats and battle_stats.enforce_start_tile_type
	var player_starting_position := Vector2i.ZERO

	if tilemap.is_tile_valid(battle_stats.player_start_cell):
		player_starting_position = battle_stats.player_start_cell
		reserved_start_tiles.append(player_starting_position)
	elif force_start_tile:
		player_starting_position = tilemap.get_starting_tile(
			battle_stats.starting_tile_type,
			true
		)
		if tilemap.is_tile_valid(player_starting_position):
			reserved_start_tiles.append(player_starting_position)
	else:
		player_starting_position = tilemap.get_starting_tile()
		reserved_start_tiles.append(player_starting_position)
	# Keep the first card decision from starting inside an unavoidable melee pile.
	for adjacent in tilemap.base_layer.get_surrounding_cells(player_starting_position):
		reserved_start_tiles.append(adjacent)

	enemy_handler.setup_enemies(battle_stats, reserved_start_tiles)
	game_world_ui.get_node("BossHealth").bind_world(self)
	enemy_handler.reset_enemy_actions.call_deferred()
	battle_stats.enemy_gold_reward = 0
	battle_stats.enemy_resource_reward = 0

	if not tilemap.is_tile_valid(player_starting_position):
		player_starting_position = tilemap.get_starting_tile()
	if not tilemap.is_tile_valid(player_starting_position):
		player_starting_position = tilemap.get_random_valid_tile()
	tilemap.fog_clear_radius = player.stats.view_range
	tilemap.move_player(player_starting_position, false)
	tilemap.queue_start_tile_effects()
	if is_instance_valid(battle_presentation):
		if battle_stats.category == EncounterDefinition.Category.BOSS:
			battle_presentation.intro_text = battle_stats.encounter_name
			battle_presentation.win_text = "Rift sealed"
			battle_presentation.prepare_boss(enemy_handler.get_child(0) as Enemy)
		battle_presentation.play_intro()
	Events.tile_selected.emit(tilemap.tile_map_data[player_starting_position])
	tilemap.place_obelisk(get_tree().get_first_node_in_group("obelisk"))
	world_camera.frame_battle(true)
	if is_instance_valid(battle_presentation):
		battle_presentation.finished.connect(world_camera.frame_battle.bind(false), CONNECT_ONE_SHOT)
	else:
		world_camera.frame_battle()
	
	var message = WorldMessageData.new(
		"The World has awakened!",
		WorldMessageData.Priority.IMPORTANT
	)
	Events.world_message_requested.emit(message)

	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Enums.RelicType.START_OF_COMBAT)

	get_tree().create_timer(1).timeout.connect(
		func():
			if not is_instance_valid(tilemap.obelisk):
				return
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
	if DisplayServer.get_name() != "headless":
		Utils.shake(map_camera, 12.0, 0.2)
	Events.world_message_requested.emit(
		WorldMessageData.new(
			"The void consumes",
			WorldMessageData.Priority.CRITICAL
		)
	)
	await tilemap.shrink_map(amount)

	# Reframe once per completed collapse, never per disappearing tile or during aim.
	if not world_camera.manual:
		world_camera.frame_battle(world_camera.overview)
	rounds_until_shrink = shrink_frequency

func _on_enemy_died(enemy: Enemy) -> void:
	BountySystem.apply_bounty_for_enemy(run_stats, enemy.stats.enemy_name, battle_stats)

func _on_enemies_child_order_changed() -> void:
	check_victory.call_deferred()


func check_victory() -> void:
	if battle_over_handled or victory_committed or not battle_state.battle_active:
		return
	if player.stats.health <= 0 or player_handler.resolving_action:
		return
	if battle_state.phase in [BattleStateController.Phase.ENEMY_TURN, BattleStateController.Phase.SHRINKING]:
		return
	for node in enemy_handler.get_children():
		if node is Enemy and not node.is_dying and node.stats.health > 0:
			return
	_commit_victory()


func _commit_victory() -> void:
	if victory_committed or battle_over_handled:
		return
	victory_committed = true
	battle_state.end_battle()
	relics.activate_relics_by_type(Enums.RelicType.END_OF_COMBAT)


func _on_obelisk_destroyed() -> void:
	if battle_over_handled:
		return
	TelemetryManager.track_event("obelisk_destroyed", {"turn": current_round, "remaining": enemy_handler.get_active_mobile_enemy_count()})
	var msg := WorldMessageData.new(
		"Obelisk shattered! The rift calms.",
		WorldMessageData.Priority.CRITICAL
	)
	Events.world_message_requested.emit(msg)
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_rollover)
	if battle_stats.victory_objective == EncounterDefinition.VictoryObjective.DESTROY_OBELISK:
		_commit_victory()
	else:
		check_victory.call_deferred()


func _on_player_died() -> void:
	TelemetryManager.track_event("run_failed", {"reason": "combat", "encounter": battle_stats.encounter_id})
	player_stats.is_running = false
	_handle_battle_over("Game Over!", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()

func _on_relics_activated(type: Enums.RelicType) -> void:
	match type:
		Enums.RelicType.START_OF_COMBAT:
			battle_state.start_battle()
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
	TelemetryManager.track_event("encounter_completed", {"encounter": battle_stats.get_encounter_id(),
		"outcome": "win" if result == BattleOverPanel.Type.WIN else "loss", "turns": current_round,
		"damage_taken": player_stats.total_health_damage - initial_health_damage,
		"net_health_loss": initial_health - player_stats.health,
		"healing_received": player_stats.total_healing - initial_healing}, 2,
		{"duration_ms": Time.get_ticks_msec() - encounter_started_ms, "starting_health": initial_health,
		"ending_health": player_stats.health, "deck_size": player_stats.deck.cards.size()})
	battle_state.end_battle()
	if is_instance_valid(battle_presentation):
		call_deferred("_play_battle_outro", message, result)
		return
	_emit_battle_over(message, result)


func _play_battle_outro(message: String, result: BattleOverPanel.Type) -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(battle_presentation):
		battle_presentation.play_outro(result == BattleOverPanel.Type.WIN)
		await battle_presentation.finished
	_emit_battle_over(message, result)


func _emit_battle_over(message: String, result: BattleOverPanel.Type) -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(audio_stream_player):
		audio_stream_player.stream_paused = true
	Events.battle_over_screen_requested.emit(message, result)
