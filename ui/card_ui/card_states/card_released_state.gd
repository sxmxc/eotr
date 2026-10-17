extends CardState

var played: bool


func enter() -> void:
	card_ui.state.text = "RELEASED"
	played = false

	# Only play if we still have a valid target.
	if not card_ui.targets.is_empty():
		if card_ui.card.is_single_targeted():
			var valid_cells := card_ui.card.get_valid_targets(
				card_ui, card_ui.player_modifiers
			)
			var target := card_ui.targets[0]
			if target is Enemy:
				if not valid_cells.has((target as Enemy).current_tile_position):
					card_ui.targets.clear()
		if not card_ui.targets.is_empty():
			Events.tooltip_hide_requested.emit()
			card_ui.visuals.set_hover_outline(false)
			played = true
			print("Played card on target(s) ", card_ui.targets)
			card_ui.play()


func post_enter() -> void:
	if played:
		return
	transition_requested.emit(self, CardState.State.BASE)
