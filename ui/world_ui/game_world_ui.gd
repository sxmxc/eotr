extends CanvasLayer
class_name GameWorldUI

@export var player_stats : PlayerStats : set = _set_player_stats


@onready var hand : PlayerHand = $PlayerUI/Hand as PlayerHand
@onready var stats_ui : StatsUI = $PlayerUI/Stats as StatsUI
@onready var tile_info : TileInfoUI = $PlayerUI/TileInfo as TileInfoUI
@onready var end_turn_button = %EndTurnButton
@onready var draw_pile_button: CardPileButton = %DrawPileButton
@onready var discard_pile_button: CardPileButton = %DiscardPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var status_handler: StatusHandler = $PlayerUI/StatusHandler

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("Discard Pile"))
	status_handler.status_owner = get_tree().get_first_node_in_group("player")
	
func initialize_card_pile_ui() -> void:
	draw_pile_button.card_pile = player_stats.draw_pile
	draw_pile_view.card_pile = player_stats.draw_pile
	discard_pile_button.card_pile = player_stats.discard
	discard_pile_view.card_pile = player_stats.discard

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	stats_ui.player_stats = player_stats
	hand.player_stats = player_stats

func _on_player_hand_drawn() -> void:
	end_turn_button.disabled = false
	pass

func _on_end_turn_button_pressed() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()
