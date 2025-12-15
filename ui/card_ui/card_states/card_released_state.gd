extends CardState

var played: bool


func enter() -> void:
	card_ui.state.text = "RELEASED"
	played = false

	if card_ui.targets.is_empty() and card_ui.card.is_single_targeted():
		var tilemap: ProcGenTilemap = card_ui.get_tree().get_first_node_in_group("map_layer")
		for enemy in card_ui.get_tree().get_nodes_in_group("enemy"):
			if tilemap and tilemap.is_tile_behind_fog(enemy.current_tile_position):
				continue
			card_ui.targets.append(enemy)
			break

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
