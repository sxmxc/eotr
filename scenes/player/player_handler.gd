class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.25

@export var relics: RelicHandler
@export var player: Player
@export var player_hand: PlayerHand

var player_stats: PlayerStats
var card_types_played: Array[Enums.CardType] = []


func _ready() -> void:
	if not LimboConsole.has_command("draw_card"):
		LimboConsole.register_command(draw_card, "draw_card", "Draw card from deck")
	Events.card_played.connect(_on_card_played)


func start_battle(stats: PlayerStats) -> void:
	player_stats = stats
	player_stats.draw_pile = player_stats.deck.deep_duplicate()
	player_stats.draw_pile.shuffle()
	player_stats.discard = CardPile.new()
	relics.relics_activated.connect(_on_relics_activated)
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	start_turn()


func start_turn() -> void:
	card_types_played = []
	player.phantom_camera_2d.priority = 20
	player_stats.block = 0
	player_stats.reset_energy()
	relics.activate_relics_by_type(Enums.RelicType.START_OF_TURN)


func end_turn() -> void:
	player_hand.disable_hand()
	relics.activate_relics_by_type(Enums.RelicType.END_OF_TURN)
	Events.enemy_info_hide_requested.emit()
	player.phantom_camera_2d.priority = 0


func draw_card() -> void:
	reshuffle_deck_from_discard()
	player_hand.add_card(player_stats.draw_pile.draw_card())
	reshuffle_deck_from_discard()


func draw_cards(amount: int) -> void:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)

	tween.finished.connect(func(): Events.player_hand_drawn.emit())


func discard_cards() -> void:
	if player_hand.get_cards().size() == 0:
		Events.player_hand_discarded.emit()
		return
	var tween := create_tween()
	var world_ui :GameWorldUI = get_tree().get_first_node_in_group("ui_layer")
	var discard_pile_position = world_ui.discard_pile_button.global_position
	
	for card_ui in player_hand.get_cards():
		var card_ui_offset = Vector2(card_ui.global_position.x, card_ui.global_position.y - 100)
		tween.tween_property(card_ui,"global_position", card_ui_offset,HAND_DISCARD_INTERVAL/2)
		tween.tween_property(card_ui,"global_position", discard_pile_position,HAND_DISCARD_INTERVAL/2)
		tween.parallel().tween_property(card_ui, "scale", Vector2(.05,.05),HAND_DISCARD_INTERVAL)
		tween.tween_callback(player_stats.discard.add_card.bind(card_ui.card))
		tween.tween_callback(player_hand.discard_card.bind(card_ui))
		#tween.tween_interval(HAND_DISCARD_INTERVAL)
	tween.finished.connect(func(): Events.player_hand_discarded.emit())


func reshuffle_deck_from_discard() -> void:
	if not player_stats.draw_pile.is_empty():
		return

	while not player_stats.discard.is_empty():
		player_stats.draw_pile.add_card(player_stats.discard.draw_card())

	player_stats.draw_pile.shuffle()


func _on_card_played(card: Card) -> void:
	if not card_types_played.has(card.card_type):
		card_types_played.append(card.card_type)
	if card.exhaust or card.card_type == Enums.CardType.POWER:
		return

	player_stats.discard.add_card(card)


func _on_statuses_applied(type: Enums.StatusType) -> void:
	match type:
		Enums.StatusType.START_OF_TURN:
			draw_cards(player_stats.cards_per_turn)
		Enums.StatusType.END_OF_TURN:
			discard_cards()


func _on_relics_activated(type: Enums.RelicType) -> void:
	match type:
		Enums.RelicType.START_OF_TURN:
			player.status_handler.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
		Enums.RelicType.END_OF_TURN:
			player.status_handler.apply_statuses_by_type(Enums.StatusType.END_OF_TURN)
