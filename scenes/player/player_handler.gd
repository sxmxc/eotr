class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.25
const HEX_TRAIL = preload("res://ui/player_ui/hex_trail.tscn")

@export var relics: RelicHandler
@export var player: Player
@export var player_hand: PlayerHand
@export var tilemap: ProcGenTilemap

var player_stats: PlayerStats
var card_types_played: Array[Enums.CardType] = []


func _ready() -> void:
	if not LimboConsole.has_command("draw_card"):
		LimboConsole.register_command(draw_card, "draw_card", "Draw card from deck")
	Events.card_played.connect(_on_card_played)
	Events.player_moved.connect(_on_player_moved)


func start_battle(stats: PlayerStats) -> void:
	player_stats = stats
	player_stats.draw_pile = player_stats.deck.deep_duplicate()
	player_stats.draw_pile.shuffle()
	player_stats.discard = CardPile.new()
	player_stats.exhaust_pile = CardPile.new()
	relics.relics_activated.connect(_on_relics_activated)
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	start_turn()


func start_turn() -> void:
	card_types_played = []
	if !is_instance_valid(player):
		return
	player.phantom_camera_2d.priority = 20
	player_stats.block = 0
	player_stats.reset_energy()
	if tilemap.is_tile_mana_well(tilemap.player_position):
		player_stats.energy += 1
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
		tween.tween_interval(HAND_DISCARD_INTERVAL)
	tween.finished.connect(func(): Events.player_hand_discarded.emit())


func reshuffle_deck_from_discard() -> void:
	if not player_stats.draw_pile.is_empty():
		return
	
	var world_ui :GameWorldUI = get_tree().get_first_node_in_group("ui_layer")

	while not player_stats.discard.is_empty():
		player_stats.draw_pile.add_card(player_stats.discard.draw_card())
		var hex_trail = HEX_TRAIL.instantiate()
		var tween = create_tween()
		world_ui.discard_pile_button.add_child(hex_trail)
		hex_trail.global_position = world_ui.discard_pile_button.counter.global_position
		tween.tween_property(hex_trail,"global_position", Utils.get_node_global_center(world_ui.draw_pile_button.counter),1)
		tween.tween_callback(hex_trail.queue_free)		

	player_stats.draw_pile.shuffle()


func _on_player_moved() -> void:
	if !is_node_ready():
		await ready
	var tile_type : Enums.TileType = tilemap.get_tile_data(tilemap.player_position).type
	player.is_mana_buffed = false
	match tile_type:
		Enums.TileType.MANA_WELL:
			player_stats.energy += 1
			player.is_mana_buffed = true
		Enums.TileType.RIFT_GATE:
			var rift_gates : Array[Vector2i] = tilemap.get_tiles_of_type(Enums.TileType.RIFT_GATE)
			if rift_gates.size() > 1:
				var destination_gate = RNG.array_pick_random(rift_gates)
				if destination_gate == tilemap.player_position:
					while destination_gate == tilemap.player_position:
						destination_gate = RNG.array_pick_random(rift_gates)
				tilemap.teleport_player(destination_gate)
			
			
func _on_card_played(card: Card) -> void:
	if not card_types_played.has(card.card_type):
		card_types_played.append(card.card_type)
	if card.exhaust or card.card_type == Enums.CardType.POWER:
		player_stats.exhaust_pile.add_card(card)
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
