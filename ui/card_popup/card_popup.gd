extends Control
class_name CardPopup

const CARD_MENU_UI_SCENE = preload("res://ui/card_menu_ui/card_menu_ui.tscn")

@export var background_color: Color = Color(0x4b3d44f4)

@onready var background: ColorRect = $Background
@onready var card_description: RichTextLabel = %CardDescription
@onready var popup_card: CenterContainer = %PopupCard

func _ready() -> void: 
	for card: CardMenuUI in popup_card.get_children():
		card.queue_free()
		
	background.color = background_color

func show_popup(card: Card) -> void:
	var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	popup_card.add_child(new_card)
	new_card.card = card
	new_card.tooltip_requested.connect(hide_popup.unbind(1))
	card_description.text = card.description
	show()
	
func hide_popup():
	if not visible:
		return
	for card: CardMenuUI in popup_card.get_children():
		card.queue_free()
	hide()
	

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		hide_popup()
