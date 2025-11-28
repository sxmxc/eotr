extends CenterContainer
class_name CardMenuUI

signal tooltip_requested(card: Card)
signal selection_toggled(card: Card, selected: bool)
signal hovered(card: Card)
signal hover_ended(card: Card)

const CARD_PANEL_BASE = preload("res://resources/themes/card_panel_base.tres")
const CARD_PANEL_HOVER = preload("res://resources/themes/card_panel_hover.tres")

@export var card: Card : set = set_card
@export var selectable := false
@export var tooltip_on_right_click := false

@onready var visuals: CardVisuals = $Visuals

var _selected := false
var _is_hovered := false


func _ready() -> void:
	_update_panel_style()


func _on_visuals_mouse_entered() -> void:
	_is_hovered = true
	_update_panel_style()
	hovered.emit(card)


func _on_visuals_mouse_exited() -> void:
	_is_hovered = false
	_update_panel_style()
	hover_ended.emit(card)


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		if selectable:
			set_selected(!_selected)
			selection_toggled.emit(card, _selected)
		else:
			tooltip_requested.emit(card)
	elif tooltip_on_right_click and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		tooltip_requested.emit(card)


func set_selected(value: bool) -> void:
	if not selectable:
		value = false
	if _selected == value:
		return
	_selected = value
	_update_panel_style()


func is_selected() -> bool:
	return _selected


func clear_selection() -> void:
	set_selected(false)


func _update_panel_style() -> void:
	if _selected:
		visuals.panel.set("theme_override_styles/panel", CARD_PANEL_HOVER)
	elif _is_hovered:
		visuals.panel.set("theme_override_styles/panel", CARD_PANEL_HOVER)
	else:
		visuals.panel.set("theme_override_styles/panel", CARD_PANEL_BASE)


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready
	card = value
	visuals.card = card
