extends Control
class_name CardPileView

const CARD_MENU_UI_SCENE = preload("res://ui/card_menu_ui/card_menu_ui.tscn")

@export var card_pile: CardPile

@onready var title: Label = %Title
@onready var card_container: GridContainer = %CardContainer
@onready var card_popup: CardPopup = %CardPopup
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(hide)
	for card: Node in card_container.get_children():
		card.queue_free()
		
	card_popup.hide_popup()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if card_popup.visible:
			card_popup.hide_popup()
		else:
			hide()
			
func show_current_view(new_title: String, randomized: bool = false) -> void:
	for card: Node in card_container.get_children():
		card.queue_free()
	card_popup.hide_popup()
	title.text = new_title
	_update_view.call_deferred(randomized)
	
func _update_view(randomized: bool) -> void:
	if not card_pile:
		return
		
	var all_cards := card_pile.cards.duplicate()
	if randomized:
		all_cards.shuffle()
		
	for card: Card in all_cards:
		var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		card_container.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(card_popup.show_popup)
	show()
