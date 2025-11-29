extends CardState

const MOUSE_Y_CANCEL_THRESHOLD := 1000


func enter() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var tilemap = get_tree().get_first_node_in_group("map_layer")
	tilemap.show_target_highlights(card_ui.card.get_valid_targets(card_ui, player.modifier_handler))
	SoundManager.play_sound_random_pitch(AudioLibrary.card_aim_scan)
	card_ui.scale = Vector2.ONE
	card_ui.state.text = "AIMING"
	card_ui.targets.clear()
	var offset := Vector2(card_ui.parent.size.x / 2, -card_ui.size.y / 2)
	offset.x -= card_ui.size.x / 2
	card_ui.animate_to_position(card_ui.parent.global_position + offset, 0.2)
	card_ui.drop_point_detector.monitoring = false
	Events.card_aim_started.emit(card_ui)


func exit() -> void:
	var tilemap : ProcGenTilemap = get_tree().get_first_node_in_group("map_layer")
	tilemap.clear_target_highlights()
	Events.card_aim_ended.emit(card_ui)


func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
	var mouse_at_bottom := card_ui.get_global_mouse_position().y > MOUSE_Y_CANCEL_THRESHOLD

	if (mouse_motion and mouse_at_bottom) or event.is_action_pressed("right_mouse"):
		card_ui.targets.clear()
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, CardState.State.RELEASED)
