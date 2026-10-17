extends CardState

var mouse_over_card: bool


func enter() -> void:
	if not card_ui.is_node_ready():
		await card_ui.ready
	if card_ui.tween and card_ui.tween.is_running():
		card_ui.tween.kill()

	card_ui.visuals.set_hover_outline(false)
	card_ui.visuals.set_interactable(card_ui.playable and not card_ui.disabled)
	card_ui.reparent_requested.emit(card_ui)
	card_ui.state.text = "BASE"
	card_ui.pivot_offset = Vector2.ZERO
	card_ui.scale = Vector2.ONE
	card_ui.set_inspected(false, true)
	Events.tooltip_hide_requested.emit()

func exit() -> void:
	card_ui.set_inspected(false, true)
	card_ui.visuals.set_hover_outline(false)

func on_gui_input(event: InputEvent) -> void:
	if not card_ui.playable or card_ui.disabled:
		return

	if mouse_over_card and event.is_action_pressed("left_mouse"):
		card_ui.pivot_offset = card_ui.get_global_mouse_position() - card_ui.global_position
		transition_requested.emit(self, CardState.State.CLICKED)


func on_mouse_entered() -> void:
	if card_ui.disabled:
		return
	mouse_over_card = true
	card_ui.z_index = 100
	card_ui.set_inspected(true)
	card_ui.request_description()
	if not card_ui.playable or card_ui.disabled:
		return
	card_ui.visuals.set_hover_outline(true)


func on_mouse_exited() -> void:
	mouse_over_card = false
	card_ui.z_index = card_ui.get_index()
	card_ui.set_inspected(false)
	card_ui.visuals.set_hover_outline(false)
	Events.tooltip_hide_requested.emit()
