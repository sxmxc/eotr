extends Control
class_name CardCostSelection

signal selection_completed(selected_cards: Array[Card], request: CardCostSelectionRequest)
signal selection_cancelled(request: CardCostSelectionRequest)

const CARD_MENU_UI_SCENE: PackedScene = preload("res://ui/card_menu_ui/card_menu_ui.tscn")

@export var max_columns: int = 6

@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var hover_label: RichTextLabel = %HoverLabel
@onready var selection_label: Label = %SelectionLabel
@onready var card_container: GridContainer = %CardContainer
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton
@onready var card_popup: CardPopup = %CardPopup

var _request: CardCostSelectionRequest
var _selected_cards: Array[Card] = []
var _selected_nodes: Array[CardMenuUI] = []
var _card_by_node: Dictionary = {}


func _ready() -> void:
	hide()
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	Events.card_cost_selection_requested.connect(_on_card_cost_selection_requested)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _request:
		return
	if event.is_action_pressed("ui_cancel") and _request.allow_cancel:
		_on_cancel_pressed()


func _on_card_cost_selection_requested(request: CardCostSelectionRequest) -> void:
	_request = request
	_reset_cards()
	_populate_cards(request.cards)
	title_label.text = request.title if request.title != "" else "Select cards"
	body_label.text = request.body if request.body != "" else _build_default_body(request)
	hover_label.text = ""
	selection_label.text = ""
	cancel_button.visible = request.allow_cancel
	cancel_button.disabled = not request.allow_cancel
	cancel_button.text = request.cancel_label if request.cancel_label != "" else "Cancel"
	confirm_button.text = request.confirm_label if request.confirm_label != "" else "Confirm"
	_update_selection_label()
	show()


func _on_card_selection_toggled(card: Card, selected: bool, card_ui: CardMenuUI) -> void:
	if not _request:
		return
	if selected:
		if _selected_nodes.size() >= _request.get_clamped_max():
			var dropped: CardMenuUI = _selected_nodes.pop_front()
			if is_instance_valid(dropped):
				dropped.clear_selection()
				var dropped_card: Card = _card_by_node.get(dropped)
				if dropped_card:
					_selected_cards.erase(dropped_card)
		_selected_nodes.append(card_ui)
		_selected_cards.append(card)
	else:
		_selected_nodes.erase(card_ui)
		_selected_cards.erase(card)
	_update_selection_label()


func _on_card_tooltip_requested(card: Card) -> void:
	card_popup.show_popup(card)


func _on_card_hovered(card: Card) -> void:
	hover_label.text = "[b]%s[/b]\n%s" % [card.name, card.get_default_description()]


func _on_card_hover_ended(_card: Card) -> void:
	hover_label.text = ""


func _on_confirm_pressed() -> void:
	if not _request:
		return
	Events.card_cost_selection_completed.emit(_selected_cards.duplicate(), _request)
	selection_completed.emit(_selected_cards.duplicate(), _request)
	_hide_popup()


func _on_cancel_pressed() -> void:
	if not _request:
		return
	if _request.allow_cancel:
		Events.card_cost_selection_cancelled.emit(_request)
		selection_cancelled.emit(_request)
	_hide_popup()


func _reset_cards() -> void:
	card_popup.hide_popup()
	for node in card_container.get_children():
		node.queue_free()
	_selected_cards.clear()
	_selected_nodes.clear()
	_card_by_node.clear()


func _populate_cards(cards: Array[Card]) -> void:
	var clamped_columns: int = clampi(max_columns, 1, max(1, cards.size()))
	card_container.columns = clamped_columns
	for card: Card in cards:
		var card_ui := CARD_MENU_UI_SCENE.instantiate() as CardMenuUI
		card_container.add_child(card_ui)
		card_ui.card = card
		card_ui.selectable = true
		card_ui.tooltip_on_right_click = true
		card_ui.selection_toggled.connect(_on_card_selection_toggled.bind(card_ui))
		card_ui.tooltip_requested.connect(_on_card_tooltip_requested)
		card_ui.hovered.connect(_on_card_hovered)
		card_ui.hover_ended.connect(_on_card_hover_ended)
		_card_by_node[card_ui] = card


func _update_selection_label() -> void:
	if not _request:
		selection_label.text = ""
		confirm_button.disabled = true
		return

	var current := _selected_cards.size()
	var min_needed := _request.get_clamped_min()
	var max_allowed := _request.get_clamped_max()
	selection_label.text = "%d / %d selected" % [current, max_allowed]
	confirm_button.disabled = current < min_needed


func _build_default_body(request: CardCostSelectionRequest) -> String:
	var min_needed := request.get_clamped_min()
	var max_allowed := request.get_clamped_max()
	if min_needed == max_allowed:
		return "Select %d card(s) to pay the cost." % min_needed
	return "Select %d-%d cards to pay the cost." % [min_needed, max_allowed]


func _hide_popup() -> void:
	_reset_cards()
	_request = null
	hide()
