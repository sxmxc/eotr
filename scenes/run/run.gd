class_name Run
extends Node

const GAME_WORLD_SCENE = preload("res://scenes/game_world/game_world.tscn")
const BATTLE_REWARDS_SCENE = preload("res://scenes/battle_rewards/battle_rewards.tscn")
const REST_SCENE = preload("res://scenes/rest/rest.tscn")
const SHOP_SCENE = preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE = preload("res://scenes/treasure/treasure.tscn")
const WIN_SCREEN_SCENE = preload("res://scenes/win_screen/win_screen.tscn")
const EVENT_SCENE = preload("res://scenes/event/event_room.tscn")
const MAIN_MENU_PATH = "res://scenes/menus/main_menu.tscn"

@export var run_bootstrap: RunBootstrap
@export var music_playlist : AudioStreamPlaylist

@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var hud = $TopBar
@onready var relic_handler: RelicHandler = hud.relic_handler
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var map_legend = $MapLegendUI
@onready var run_time_ui: RunTimerUI = hud.run_time_ui
@onready var tutorial_ui: TutorialUI = $TutorialUI


var run_stats: RunStats
var player_stats: PlayerStats
var save_data: SaveGame
var audio_stream_player: AudioStreamPlayer


func _ready() -> void:
	if not run_bootstrap:
		return

	pause_menu.save_and_quit.connect(_on_save_and_quit)

	match run_bootstrap.type:
		RunBootstrap.Type.NEW_RUN:
			print("Starting new run")
			player_stats = run_bootstrap.selected_player_class.create_instance()
			_start_run()
		RunBootstrap.Type.CONTINUED_RUN:
			print("Continuing run")
			_load_run()

func add_resources(amount: int) -> void:
	var event_props := {
		"command": "add_resources"
	}
	TelemetryManager.track_event("console_command_used", event_props)
	TelemetryManager.track_stat("console_commands_used")
	run_stats.resources += amount
	
func add_gold(amount: int) -> void:
	var event_props := {
		"command": "add_gold"
	}
	TelemetryManager.track_event("console_command_used", event_props)
	TelemetryManager.track_stat("console_commands_used")
	run_stats.gold += amount

func _destroy_all_enemies() -> void:
	var event_props := {
		"command": "yeet_em_all"
	}
	TelemetryManager.track_event("console_command_used", event_props)
	TelemetryManager.track_stat("console_commands_used")
	get_tree().call_group("enemy", "queue_free")


func _start_run() -> void:
	SoundManager.play_music_queue(music_playlist,1)
	var event_props : Dictionary[String, String] = {
		"player_class": player_stats.player_class_name,
	}
	TelemetryManager.track_event("run_started", event_props)
	TelemetryManager.track_stat("runs_started")
	run_stats = RunStats.new()
	map.run_stats = run_stats
	_setup_event_connections()
	_connect_bounty_board()
	_setup_top_bar()
	map.generate_new_map()
	map.unlock_floor(0)
	save_data = SaveGame.new()
	player_stats.is_running = true
	_save_run(true)
	run_time_ui.start()
	if GameSettings.show_tutorial:
		tutorial_ui.display_tutorial()
		await tutorial_ui.completed


func _save_run(was_on_map: bool) -> bool:
	
	save_data.rng_seed = RNG.instance.seed
	save_data.rng_state = RNG.instance.state
	save_data.run_stats = run_stats
	save_data.player_stats = player_stats
	save_data.current_deck = player_stats.deck
	save_data.current_health = player_stats.health
	save_data.relics = relic_handler.get_all_relics()
	save_data.last_map_node = map.last_map_node
	save_data.map_data = map.map_data.duplicate()
	save_data.floors_climbed = map.floors_climbed
	save_data.was_on_map = was_on_map
	save_data.elapsed_run_time = run_time_ui.elapsed_time
	return save_data.save_data()


func _load_run() -> void:
	save_data = SaveGame.load_data()
	if not save_data:
		get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)
		return

	RNG.set_from_save_data(save_data.rng_seed, save_data.rng_state)
	run_stats = save_data.run_stats
	map.run_stats = run_stats
	player_stats = save_data.player_stats
	player_stats.deck = save_data.current_deck
	player_stats.health = save_data.current_health
	relic_handler.add_relics(save_data.relics)
	_setup_top_bar()
	_connect_bounty_board()
	_setup_event_connections()
	run_time_ui.resume_from(save_data.elapsed_run_time)
	
	map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_map_node)
	if save_data.last_map_node and not save_data.was_on_map:
		_on_map_exited(save_data.last_map_node)
		return
	
	SoundManager.play_music_queue(music_playlist,1)
	


func _change_view(scene: PackedScene) -> Node:
	if current_view.get_child_count() > 0:
		var old_view := current_view.get_child(0)
		current_view.remove_child(old_view)
		old_view.queue_free()

	get_tree().paused = false
	var new_view := scene.instantiate()
	current_view.add_child(new_view)
	map.hide_map()
	
	return new_view


func _show_map() -> void:
	if current_view.get_child_count() > 0:
		var old_view := current_view.get_child(0)
		current_view.remove_child(old_view)
		old_view.queue_free()
	SoundManager.play_music_queue(music_playlist,1)
	map.show_map()
	map.unlock_next_map_node()
	map_legend.show()
	_save_run(true)


func _setup_event_connections() -> void:
	Events.player_died.connect(run_time_ui.stop)
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_show_map)
	Events.rest_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.event_exited.connect(_show_map)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_on_treasure_room_exited)

	if not LimboConsole.has_command("yeet_em_all"):
		LimboConsole.register_command(_destroy_all_enemies, "yeet_em_all", "Destroy all enemies")
	if not LimboConsole.has_command("add_resources"):
		LimboConsole.register_command(add_resources, "add_resources", "Add resources")
	if not LimboConsole.has_command("add_gold"):
		LimboConsole.register_command(add_gold, "add_gold", "Add gold")

func _setup_top_bar() -> void:
	hud.bind_run(player_stats, run_stats)
	relic_handler.add_relic(player_stats.starting_relic)
	

func _connect_bounty_board() -> void:
	map_legend.bounty_board_requested.connect(_on_bounty_board_button_pressed)
	map.bounties_updated.connect(hud.update_bounties)


func _on_bounty_board_button_pressed() -> void:
	hud.show_bounties(run_stats.bounty_contracts, map.floors_climbed, run_stats.next_bounty_refresh_floor)


func _show_regular_rewards() -> void:
	var reward_scene := _change_view(BATTLE_REWARDS_SCENE) as BattleRewards
	reward_scene.run_stats = run_stats
	reward_scene.player_stats = player_stats
	reward_scene.relic_handler = relic_handler

	reward_scene.add_gold_reward(map.last_map_node.battle_stats.roll_gold_reward())
	reward_scene.add_resource_reward(map.last_map_node.battle_stats.roll_resource_reward())
	reward_scene.add_enemy_gold_reward(map.last_map_node.battle_stats.enemy_gold_reward)
	reward_scene.add_enemy_resource_reward(map.last_map_node.battle_stats.enemy_resource_reward)
	reward_scene.add_card_reward()


func _on_battle_won() -> void:
	var props : Dictionary [String, String] = {
		"floor" : "%s" % str(map.floors_climbed)
	}
	TelemetryManager.track_event("floor_completed", props)
	TelemetryManager.track_stat("floors_completed")
	if map.floors_climbed == MapGenerator.FLOORS:
		run_time_ui.stop()
		player_stats.is_running = false
		var event_props := {
			"player_class" : player_stats.player_class_name,
			"run_completion_time" : run_time_ui.elapsed_time
			}
		TelemetryManager.track_event("run_completed", event_props)
		
		var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
		win_screen.player_stats = player_stats
		SaveGame.delete_data()
	else:
		var event_props := {
			"player_class" : player_stats.player_class_name
			}
		TelemetryManager.track_event("battle_won", event_props)
		TelemetryManager.track_stat("battles_won")
		_show_regular_rewards()


func _on_game_world_entered(map_node: MapNode) -> void:
	var battle_scene: GameWorld = _change_view(GAME_WORLD_SCENE) as GameWorld
	battle_scene.player_stats = player_stats
	battle_scene.run_stats = run_stats
	battle_scene.battle_stats = map_node.battle_stats
	battle_scene.relics = relic_handler
	battle_scene.start_world()


func _on_rest_entered() -> void:
	var rest_scene: Rest = _change_view(REST_SCENE) as Rest
	rest_scene.player_stats = player_stats


func _on_treasure_room_entered() -> void:
	var treasure_scene := _change_view(TREASURE_SCENE) as Treasure
	treasure_scene.relic_handler = relic_handler
	treasure_scene.player_stats = player_stats
	treasure_scene.generate_relic()


func _on_event_entered() -> void:
	var event_scene := _change_view(EVENT_SCENE)
	if event_scene and event_scene.has_method("setup_event"):
		event_scene.setup_event(player_stats, run_stats, relic_handler)
	Events.event_entered.emit()


func _on_treasure_room_exited(relic: Relic) -> void:
	var reward_scene := _change_view(BATTLE_REWARDS_SCENE) as BattleRewards
	reward_scene.run_stats = run_stats
	reward_scene.player_stats = player_stats
	reward_scene.relic_handler = relic_handler

	reward_scene.add_relic_reward(relic)


func _on_shop_entered() -> void:
	var shop := _change_view(SHOP_SCENE) as Shop
	shop.player_stats = player_stats
	shop.run_stats = run_stats
	shop.relic_handler = relic_handler
	Events.shop_entered.emit(shop)
	shop.populate_shop()


func _on_map_exited(map_node: MapNode) -> void:
	map_legend.hide()
	_save_run(false)
	match map_node.type:
		Enums.MapNodeType.MONSTER, Enums.MapNodeType.ELITE:
			_track_floor_started(map_node)
			_on_game_world_entered(map_node)
		Enums.MapNodeType.TREASURE:
			_on_treasure_room_entered()
		Enums.MapNodeType.REST:
			_on_rest_entered()
		Enums.MapNodeType.SHOP:
			_on_shop_entered()
		Enums.MapNodeType.EVENT:
			_on_event_entered()
		Enums.MapNodeType.BOSS:
			_track_floor_started(map_node)
			_on_game_world_entered(map_node)


func _track_floor_started(map_node: MapNode) -> void:
	if not map_node or not map_node.battle_stats:
		return

	var battle_stats := map_node.battle_stats
	var event_props :Dictionary[String,String] = {
		"floor": "%s" % str(map.floors_climbed),
		"map_node_type": Enums.MapNodeType.keys()[map_node.type],
		"battle_tier":str(battle_stats.battle_tier),
		"is_elite": str(battle_stats.is_elite),
	}
	TelemetryManager.track_event("floor_started", event_props)


func _on_save_and_quit() -> void:
	# Encounters resume from the existing pre-encounter snapshot; do not serialize
	# partially resolved combat into the map save. Update time in either case.
	var checkpoint := SaveGame.load_data()
	if not checkpoint:
		Utils.show_save_error("The last checkpoint could not be read. Your run is still open; return to the map to save again.")
		return
	checkpoint.elapsed_run_time = run_time_ui.elapsed_time
	if checkpoint.save_data():
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
