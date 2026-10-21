extends Control
class_name CardPopup

signal card_confirmed(card: Card)

const CARD_MENU_UI_SCENE = preload("res://ui/card_menu_ui/card_menu_ui.tscn")

@export var confirmation_enabled := false
@export_range(1.0, 1.5, 0.05) var card_presentation_scale := 1.25

@onready var card_description: RichTextLabel = %CardDescription
@onready var popup_card: CenterContainer = %PopupCard
@onready var confirm_button: Button = %ConfirmButton
@onready var close_button: Button = %CloseButton

var current_card: Card


func _ready() -> void:
	confirm_button.visible = confirmation_enabled
	confirm_button.pressed.connect(_confirm_card)


func show_popup(card: Card) -> void:
	_clear_card()
	current_card = card
	var new_card := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
	new_card.presentation_scale = card_presentation_scale
	popup_card.add_child(new_card)
	new_card.card = card
	new_card.tooltip_requested.connect(hide_popup.unbind(1))
	new_card.visuals.card_text_label.text = card.get_default_description()
	card_description.text = card.get_default_description()
	show()


func hide_popup():
	_clear_card()
	hide()


func _clear_card() -> void:
	current_card = null
	for child: Node in popup_card.get_children():
		popup_card.remove_child(child)
		child.queue_free()


func _confirm_card() -> void:
	if current_card:
		card_confirmed.emit(current_card)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		hide_popup()
