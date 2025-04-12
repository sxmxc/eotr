extends ColorRect
class_name CardRewards

signal card_reward_selected(card: Card)

const CARD_MENU_UI_SCENE = preload("res://ui/card_menu_ui/card_menu_ui.tscn")

@export var rewards: Array[Card]:
	set = set_rewards

@onready var cards: HBoxContainer = %Cards
@onready var skip_button: Button = %SkipButton
@onready var card_popup: CardPopup = $CardPopup
@onready var take_button: Button = %TakeButton

var selected_card: Card


func _ready() -> void:
	_clear_rewards()

	take_button.pressed.connect(
		func():
			card_reward_selected.emit(selected_card)
			queue_free()
	)
	skip_button.pressed.connect(
		func():
			card_reward_selected.emit(null)
			queue_free()
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		card_popup.hide_popup()


func _clear_rewards() -> void:
	for card: Node in cards.get_children():
		card.queue_free()
	card_popup.hide_popup()
	selected_card = null


func _show_popup(card: Card) -> void:
	selected_card = card
	card_popup.show_popup(card)


func set_rewards(new_cards: Array[Card]) -> void:
	rewards = new_cards
	if not is_node_ready():
		await ready

	_clear_rewards()
	for card: Card in rewards:
		var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		cards.add_child(new_card)
		new_card.card = card
		new_card.visuals.card_text_label.text = card.get_default_description()
		new_card.tooltip_requested.connect(_show_popup)
