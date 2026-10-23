extends CardState

func enter() -> void:
	card_ui.state.text = "CLICKED"
	card_ui.drop_point_detector.monitoring = true
	card_ui.original_index = card_ui.get_index()

func on_input(event: InputEvent) -> void:
	if is_instance_valid(card_ui.interaction_controller):
		card_ui.interaction_controller.handle_input(self, event)
