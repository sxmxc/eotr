extends CardState

const DRAG_MINIMUM_THRESHOLD := 0.05

var minimum_drag_time_elapsed := false

func enter() -> void:
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		card_ui.reparent(ui_layer)
	card_ui.visuals.panel.set("theme_override_styles/panel", card_ui.STYLE_DRAGGING)
	Events.card_drag_started.emit(card_ui)
	card_ui.rotation_degrees = 0
	minimum_drag_time_elapsed = false
	var threshold_timer := get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(func(): minimum_drag_time_elapsed = true)
	
func on_input(event: InputEvent) -> void:
	var single_targeted := card_ui.card.is_single_targeted()
	var mouse_motion := event is InputEventMouseMotion
	var cancel = event.is_action_pressed("right_mouse")
	var confirm = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	var player = get_tree().get_first_node_in_group("player")
	var tilemap = get_tree().get_first_node_in_group("map_layer")
	
	tilemap.highlight_cells(card_ui.card.get_valid_targets(card_ui, player.modifier_handler))
	
	if single_targeted and mouse_motion and card_ui.targets.size() > 0:
		transition_requested.emit(self, CardState.State.AIMING)
		return
	
	if mouse_motion:
		card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.pivot_offset
	
	if cancel:
		transition_requested.emit(self, CardState.State.BASE)
	elif confirm:
		get_viewport().set_input_as_handled()
		transition_requested.emit(self,CardState.State.RELEASED)

func exit() -> void:
	var tilemap: ProcGenTilemap = get_tree().get_first_node_in_group("map_layer")
	tilemap.clear_highlight()
	Events.card_drag_ended.emit(card_ui)
