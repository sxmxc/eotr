extends CardState

var played: bool


func enter() -> void:
	card_ui.state.text = "RELEASED"
	played = false

	if card_ui.can_execute(card_ui.targets):
		Events.tooltip_hide_requested.emit()
		card_ui.visuals.set_hover_outline(false)
		played = true
		card_ui.play()


func post_enter() -> void:
	if played:
		return
	Events.world_message_requested.emit(WorldMessageData.new("No valid target. Aim at a highlighted target, or right click to cancel.", WorldMessageData.Priority.ROUTINE))
	transition_requested.emit(self, CardState.State.BASE)
