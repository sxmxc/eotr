extends CardState

var played: bool


func enter() -> void:
	card_ui.state.text = "RELEASED"
	played = false

	if not card_ui.targets.is_empty():
		Events.tooltip_hide_requested.emit()
		card_ui.visuals.panel.set("theme_override_styles/panel", card_ui.STYLE_BASE)
		played = true
		print("Played card on target(s) ", card_ui.targets)
		card_ui.play()


func post_enter() -> void:
	if played:
		return
	transition_requested.emit(self, CardState.State.BASE)
