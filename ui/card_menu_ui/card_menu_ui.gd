extends CenterContainer
class_name CardMenuUI

signal tooltip_requested(card: Card)

const CARD_PANEL_BASE = preload("res://resources/themes/card_panel_base.tres")
const CARD_PANEL_HOVER = preload("res://resources/themes/card_panel_hover.tres")

@export var card: Card : set = set_card

@onready var visuals: CardVisuals = $Visuals

func _on_visuals_mouse_entered() -> void:
	visuals.panel.set("theme_override_styles/panel", CARD_PANEL_HOVER)
	pass # Replace with function body.


func _on_visuals_mouse_exited() -> void:
	visuals.panel.set("theme_override_styles/panel", CARD_PANEL_BASE)
	pass # Replace with function body.


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		tooltip_requested.emit(card)
	pass # Replace with function body.

func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
		
	card = value
	visuals.card = card
