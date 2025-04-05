extends Node
class_name Run

const GAME_WORLD_SCENE = preload("res://scenes/game_world/game_world.tscn")
const BATTLE_REWARDS_SCENE = preload("res://scenes/battle_rewards/battle_rewards.tscn")
const REST_SCENE = preload("res://scenes/rest/rest.tscn")
const SHOP_SCENE = preload("res://scenes/shop/shop.tscn")
const TREASURE_SCENE = preload("res://scenes/treasure/treasure.tscn")

@export var run_bootstrap : RunBootstrap

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

var run_stats: RunStats
var player_stats: PlayerStats

func _ready()-> void:
	if not run_bootstrap:
		return
		
	match run_bootstrap.type:
		RunBootstrap.Type.NEW_RUN:
			player_stats = run_bootstrap.selected_player_class.create_instance()
			_start_run()
		RunBootstrap.Type.CONTINUED_RUN:
			print("Load run not implemented yet")
		
func _start_run() -> void:
	run_stats = RunStats.new()
	_setup_event_connections()
	_setup_top_bar()
	map.generate_new_map()
	map.unlock_floor(0)
	
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

func _setup_event_connections() -> void:
	Events.battle_won.connect(_on_battle_won)
	Events.battle_reward_exited.connect(_show_map)
	Events.rest_exited.connect(_show_map)
	Events.map_exited.connect(_on_map_exited)
	Events.shop_exited.connect(_show_map)
	Events.treasure_room_exited.connect(_show_map)
	
	map_button.pressed.connect(_show_map)
	game_world_button.pressed.connect(_on_game_world_entered)
	shop_button.pressed.connect(_change_view.bind(SHOP_SCENE))
	treasure_button.pressed.connect(_change_view.bind(TREASURE_SCENE))
	rewards_button.pressed.connect(_change_view.bind(BATTLE_REWARDS_SCENE))
	campfire_button.pressed.connect(_change_view.bind(REST_SCENE))
	
func _setup_top_bar() -> void:
	player_stats.stats_changed.connect(health_ui.update_stats.bind(player_stats))
	health_ui.update_stats(player_stats)
	gold_ui.run_stats = run_stats
	resources_ui.run_stats = run_stats
	deck_button.card_pile = player_stats.deck
	deck_view.card_pile = player_stats.deck
	deck_button.pressed.connect(deck_view.show_current_view.bind("Deck"))
	
func _on_battle_won() -> void:
	var reward_scene := _change_view(BATTLE_REWARDS_SCENE) as BattleRewards
	reward_scene.run_stats = run_stats
	reward_scene.player_stats = player_stats
	
	#Temp
	reward_scene.add_gold_reward(map.last_map_node.battle_stats.roll_gold_reward())
	reward_scene.add_resource_reward(map.last_map_node.battle_stats.roll_resource_reward())
	reward_scene.add_card_reward()
	
func _on_game_world_entered(map_node: MapNode) -> void:
	var battle_scene : GameWorld  = _change_view(GAME_WORLD_SCENE) as GameWorld
	battle_scene.player_stats = player_stats
	battle_scene.run_stats = run_stats
	battle_scene.battle_stats = map_node.battle_stats
	battle_scene.start_world()
	
func _on_rest_entered() -> void:
	var rest_scene : Rest = _change_view(REST_SCENE) as Rest
	rest_scene.player_stats = player_stats
	
func _on_map_exited(map_node: MapNode) -> void:
	match map_node.type:
		Enums.MapNodeType.MONSTER:
			_on_game_world_entered(map_node)
		Enums.MapNodeType.TREASURE:
			_change_view(TREASURE_SCENE)
		Enums.MapNodeType.REST:
			_on_rest_entered()
		Enums.MapNodeType.SHOP:
			_change_view(SHOP_SCENE)
		Enums.MapNodeType.BOSS:
			_on_game_world_entered(map_node)
