extends Node
class_name PlayerHandler

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.25

@export var player: Player
@export var player_hand : PlayerHand

var player_stats: PlayerStats

func _ready() -> void:
	Events.card_played.connect(_on_card_played)

func start_battle(stats: PlayerStats) -> void:
	player_stats = stats
	player_stats.draw_pile = player_stats.deck.duplicate(true)
	player_stats.draw_pile.shuffle()
	player_stats.discard = CardPile.new()
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	start_turn()
	
func start_turn() -> void:
	player_stats.block = 0
	player_stats.reset_energy()
	player.status_handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)

func end_turn() -> void:
	player_hand.disable_hand()
	player.status_handler.apply_statuses_by_type(Enums.StatusType.END_OF_TURN)

func draw_card() -> void:
	reshuffle_deck_from_discard()
	player_hand.add_card(player_stats.draw_pile.draw_card())
	reshuffle_deck_from_discard()
	
func draw_cards(amount: int) -> void:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	
	tween.finished.connect(
		func(): Events.player_hand_drawn.emit()
	)

func discard_cards() -> void:
	if player_hand.get_cards().size() == 0:
		Events.player_hand_discarded.emit()
		return
	var tween:= create_tween()
	for card_ui in player_hand.get_cards():
		tween.tween_callback(player_stats.discard.add_card.bind(card_ui.card))
		tween.tween_callback(player_hand.discard_card.bind(card_ui))
		tween.tween_interval(HAND_DISCARD_INTERVAL)
	tween.finished.connect(
		func(): Events.player_hand_discarded.emit()
	)

func reshuffle_deck_from_discard() -> void:
	if not player_stats.draw_pile.is_empty():
		return
	
	while not player_stats.discard.is_empty():
		player_stats.draw_pile.add_card(player_stats.discard.draw_card())
	
	player_stats.draw_pile.shuffle()
	

func _on_card_played(card: Card) -> void:
	if card.exhaust or card.card_type == Enums.CardType.POWER:
		return
		
	player_stats.discard.add_card(card)
	
func _on_statuses_applied(type: Enums.StatusType) -> void:
	match type:
		Enums.StatusType.START_OF_TURN:
			draw_cards(player_stats.cards_per_turn)
		Enums.StatusType.END_OF_TURN:
			discard_cards()
	
