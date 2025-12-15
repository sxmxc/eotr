extends CanvasLayer
class_name DevGameWorldUI

@export var player_stats: PlayerStats : set = set_player_stats
@export var hand: PlayerHand
@export var stats_ui: StatsUI
@export var status_handler: StatusHandler
@export var draw_pile_button: CardPileButton
@export var discard_pile_button: CardPileButton
@export var exhaust_pile_button: CardPileButton
@export var dev_panel: DevSandboxPanel
@export var player: Player
@export var enemy_stats_container: GridContainer
@export var enemy_stats_scroll: ScrollContainer


func _ready() -> void:
	if status_handler and player:
		status_handler.status_owner = player


func set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	if stats_ui:
		stats_ui.player_stats = player_stats
	if hand:
		hand.player_stats = player_stats
		hand.player = player
	if status_handler and player_stats:
		status_handler.status_owner = player


func initialize_card_pile_ui() -> void:
	if not player_stats:
		return
	if draw_pile_button:
		draw_pile_button.card_pile = player_stats.draw_pile
	if discard_pile_button:
		discard_pile_button.card_pile = player_stats.discard
	if exhaust_pile_button:
		exhaust_pile_button.card_pile = player_stats.exhaust_pile
