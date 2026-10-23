extends CardState

func enter() -> void:
	if is_instance_valid(card_ui.interaction_controller):
		card_ui.reparent(card_ui.interaction_controller.world.game_world_ui)
	card_ui.visuals.set_hover_outline(false)
	card_ui.visuals.set_interactable(false)
	card_ui.rotation_degrees = 0
	
func on_input(event: InputEvent) -> void:
	if is_instance_valid(card_ui.interaction_controller):
		card_ui.interaction_controller.handle_input(self, event)

func exit() -> void:
	card_ui.visuals.set_interactable(card_ui.playable and not card_ui.disabled)
