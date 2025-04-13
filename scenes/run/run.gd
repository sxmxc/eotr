class_name Run
extends Node

const GAME_WORLD_SCENE = preload("res://scenes/game_world/game_world.tscn")
const BATTLE_REWARDS_SCENE = preload("res://scenes/battle_rewards/battle_rewards.tscn")
const REST_SCENE = preload("res://scenes/rest/rest.tscn")
const SHOP_SCENE = preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE = preload("res://scenes/treasure/treasure.tscn")
const WIN_SCREEN_SCENE = preload("res://scenes/win_screen/win_screen.tscn")
const MAIN_MENU_PATH = "res://scenes/menus/main_menu.tscn"

@export var run_bootstrap: RunBootstrap

@onready var map: Map = $Map
@onready var current_view: Node = $CurrentView
@onready var health_ui: HealthUI = %HealthUI
@onready var gold_ui: GoldUI = %GoldUI
@onready var resources_ui: ResourceUI = %ResourcesUI
@onready var deck_button: CardPileButton = %DeckButton
@onready var deck_view: CardPileView = %DeckView
@onready var map_button: Button = %MapButton
@onready var game_world_button: Button = %GameWorldButton
@onready var shop_button: Button = %ShopButton
@onready var treasure_button: Button = %TreasureButton
@onready var rewards_button: Button = %RewardsButton
@onready var campfire_button: Button = %CampfireButton
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var relic_tooltip: RelicTooltip = %RelicTooltip
@onready var pause_menu: PauseMenu = $PauseMenu

var run_stats: RunStats
var player_stats: PlayerStats
var save_data: SaveGame


func _ready() -> void:
	if not run_bootstrap:
		return

	pause_menu.save_and_quit.connect(func(): get_tree().change_scene_to_file(MAIN_MENU_PATH))

	match run_bootstrap.type:
		RunBootstrap.Type.NEW_RUN:
			player_stats = run_bootstrap.selected_player_class.create_instance()
			_start_run()
		RunBootstrap.Type.CONTINUED_RUN:
			_load_run()


func _destroy_all_enemies() -> void:
	get_tree().call_group("enemy", "queue_free")


func _start_run() -> void:
	run_stats = RunStats.new()
	_setup_event_connections()
	_setup_top_bar()
	map.generate_new_map()
	map.unlock_floor(0)
	save_data = SaveGame.new()
	_save_run(true)


func _save_run(was_on_map: bool):
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
	save_data.save_data()


func _load_run() -> void:
	save_data = SaveGame.load_data()
	assert(save_data, "Couldn't load last save")

	RNG.set_from_save_data(save_data.rng_seed, save_data.rng_state)
	run_stats = save_data.run_stats
	player_stats = save_data.player_stats
	player_stats.deck = save_data.current_deck
	player_stats.health = save_data.current_health
	relic_handler.add_relics(save_data.relics)
	_setup_top_bar()
	_setup_event_connections()

	map.load_map(save_data.map_data, save_data.floors_climbed, save_data.last_map_node)
	if save_data.last_map_node and not save_data.was_on_map:
		_on_map_exited(save_data.last_map_node)


func _change_view(scene: PackedScene) -> Node:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	get_tree().paused = false
	var new_view := scene.instantiate()
	current_view.add_child(new_view)
	map.hide_map()

	return new_view


func _show_map() -> void:
	if current_view.get_child_count() > 0:
		current_view.get_child(0).queue_free()

	map.show_map()
	map.unlock_next_map_node()
	_save_run(true)


func _setup_event_connections() -> void:
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_show_map)
	Events.rest_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_on_treasure_room_exited)

	map_button.pressed.connect(_show_map)
	game_world_button.pressed.connect(_on_game_world_entered)
	shop_button.pressed.connect(_change_view.bind(SHOP_SCENE))
	treasure_button.pressed.connect(_change_view.bind(TREASURE_SCENE))
	rewards_button.pressed.connect(_change_view.bind(BATTLE_REWARDS_SCENE))
	campfire_button.pressed.connect(_change_view.bind(REST_SCENE))

	if not LimboConsole.has_command("yeet_em_all"):
		LimboConsole.register_command(_destroy_all_enemies, "yeet_em_all", "Destroy all enemies")


func _setup_top_bar() -> void:
	player_stats.stats_changed.connect(health_ui.update_stats.bind(player_stats))
	health_ui.update_stats(player_stats)
	gold_ui.run_stats = run_stats
	resources_ui.run_stats = run_stats
	relic_handler.add_relic(player_stats.starting_relic)
	Events.relic_tooltip_requested.connect(relic_tooltip.show_tooltip)
	deck_button.card_pile = player_stats.deck
	deck_view.card_pile = player_stats.deck
	deck_button.pressed.connect(deck_view.show_current_view.bind("Deck"))


func _show_regular_rewards() -> void:
	var reward_scene := _change_view(BATTLE_REWARDS_SCENE) as BattleRewards
	reward_scene.run_stats = run_stats
	reward_scene.player_stats = player_stats
	reward_scene.relic_handler = relic_handler

	reward_scene.add_gold_reward(map.last_map_node.battle_stats.roll_gold_reward())
	reward_scene.add_resource_reward(map.last_map_node.battle_stats.roll_resource_reward())
	reward_scene.add_card_reward()


func _on_battle_won() -> void:
	if map.floors_climbed == MapGenerator.FLOORS:
		var win_screen := _change_view(WIN_SCREEN_SCENE) as WinScreen
		win_screen.player_stats = player_stats
		SaveGame.delete_data()
	else:
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
	_save_run(false)

	match map_node.type:
		Enums.MapNodeType.MONSTER:
			_on_game_world_entered(map_node)
		Enums.MapNodeType.TREASURE:
			_on_treasure_room_entered()
		Enums.MapNodeType.REST:
			_on_rest_entered()
		Enums.MapNodeType.SHOP:
			_on_shop_entered()
		Enums.MapNodeType.BOSS:
			_on_game_world_entered(map_node)
