extends Control
class_name PlayerHand

@export var player: Player
@export var player_stats: PlayerStats:
	set = _set_player_stats

@onready var card_ui_scene = preload("res://ui/card_ui/card_ui.tscn")
@onready var hand_container = $HandContainer

var cards_played_this_turn := 0


func _ready() -> void:
	Events.card_played.connect(_on_card_played)


func add_card(card: Card) -> void:
	var new_card_ui := card_ui_scene.instantiate() as CardUI
	hand_container.add_child(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = hand_container
	new_card_ui.player_stats = player_stats
	new_card_ui.player_modifiers = player.modifier_handler
	new_card_ui.visuals.card_text_label.text = new_card_ui.get_description()
	new_card_ui.values_modified = new_card_ui.is_values_modified()
	


func get_cards() -> Array:
	return hand_container.get_children()


func discard_card(card: CardUI) -> void:
	card.queue_free()


func disable_hand() -> void:
	for card: CardUI in hand_container.get_children():
		card.disabled = true


func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value


func _on_card_played(_card: Card) -> void:
	cards_played_this_turn += 1


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	child.reparent(hand_container)
	var new_index := clampi(child.original_index, 0, hand_container.get_child_count())
	hand_container.move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)
