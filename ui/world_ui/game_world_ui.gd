extends CanvasLayer
class_name GameWorldUI

@export var player_stats : PlayerStats : set = _set_player_stats


@onready var hand : PlayerHand = $PlayerUI/Hand as PlayerHand
@onready var stats_ui : StatsUI = $PlayerUI/Stats as StatsUI
@onready var tile_info : TileInfoUI = $PlayerUI/TileInfo as TileInfoUI
@onready var end_turn_button = %EndTurnButton
@onready var draw_pile_button: CardPileButton = %DrawPileButton
@onready var discard_pile_button: CardPileButton = %DiscardPileButton
@onready var exhaust_pile_button: CardPileButton = %ExhaustPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var exhaust_pile_view: CardPileView = %ExhaustPileView
@onready var status_handler: StatusHandler = $PlayerUI/StatusHandler
@onready var enemy_stats_container: GridContainer = %EnemyStatsContainer
@onready var enemy_stats_scroll: ScrollContainer = %EnemyStatsScroll
@onready var tutorial_ui: TutorialUI = $"../TutorialUI"
@onready var card_spotlight: HBoxContainer = %CardSpotlight

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	if GameSettings.show_tutorial:
		Events.player_hand_drawn.connect(show_tutorial)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("Discard Pile"))
	exhaust_pile_button.pressed.connect(exhaust_pile_view.show_current_view.bind("Exhaust Pile"))
	status_handler.status_owner = get_tree().get_first_node_in_group("player")
	for child in enemy_stats_container.get_children():
		child.queue_free()
	
func initialize_card_pile_ui() -> void:
	draw_pile_button.card_pile = player_stats.draw_pile
	draw_pile_view.card_pile = player_stats.draw_pile
	discard_pile_button.card_pile = player_stats.discard
	discard_pile_view.card_pile = player_stats.discard
	exhaust_pile_button.card_pile = player_stats.exhaust_pile
	exhaust_pile_view.card_pile = player_stats.exhaust_pile
	
func show_tutorial() -> void:
	tutorial_ui.display_tutorial()
	await tutorial_ui.completed
	GameSettings.show_tutorial = false
	var data : SettingsData = GameSettings.get_current_settings()
	data.tutorial_enabled = false
	GameSettings.save_settings(data)
	Events.player_hand_drawn.disconnect(show_tutorial)
	

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	stats_ui.player_stats = player_stats
	hand.player_stats = player_stats
	hand.card_spotlight = card_spotlight

func _on_player_hand_drawn() -> void:
	end_turn_button.disabled = false
	pass

func _on_end_turn_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()
