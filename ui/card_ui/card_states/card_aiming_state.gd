extends CardState


func enter() -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.card_aim_scan)
	card_ui.scale = Vector2.ONE
	card_ui.state.text = "AIMING"
	card_ui.targets.clear()
	# The selected card stays in the bottom interaction zone. The field remains clear.
	var origin := Vector2(card_ui.parent.global_position.x + card_ui.parent.size.x / 2.0 - card_ui.size.x / 2.0, card_ui.get_viewport_rect().size.y - card_ui.size.y - card_ui.aim_bottom_inset)
	card_ui.animate_to_position(origin, card_ui.inspection_duration)
	card_ui.drop_point_detector.monitoring = false


func on_input(event: InputEvent) -> void:
	if is_instance_valid(card_ui.interaction_controller):
		card_ui.interaction_controller.handle_input(self, event)
