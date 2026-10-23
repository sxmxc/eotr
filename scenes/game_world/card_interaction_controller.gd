class_name CardInteractionController
extends Node

var world: GameWorld
var resolving_card: CardUI


func can_execute(ui: CardUI, selected_targets: Array[Node]) -> bool:
	if not is_instance_valid(world) or not world.is_inside_tree() or world.is_queued_for_deletion():
		return false
	if not is_instance_valid(ui) or ui.interaction_controller != self or not ui._play_context_active():
		return false
	if ui.disabled or not ui.card or ui.player_stats != world.player_stats:
		return false
	if not ui.player_stats.can_play_card(ui.card):
		return false
	var handler := world.player_handler
	if is_instance_valid(resolving_card) or handler.resolving_action or not handler.hand_ready:
		return false
	if world.player.pending_effects > 0 or world.battle_over_handled \
		or world.battle_state.phase != BattleStateController.Phase.PLAYER_TURN:
		return false
	if selected_targets.is_empty():
		return false
	for target: Node in selected_targets:
		if not is_instance_valid(target) or not target.is_inside_tree() or target.is_queued_for_deletion():
			return false
	if ui.card.is_single_targeted():
		var target := selected_targets[0]
		var cell: Vector2i
		if target is Enemy:
			if target.get_parent() != world.enemy_handler or target.is_dying or target.stats.health <= 0:
				return false
			cell = target.current_tile_position
		elif target is TilemapTarget:
			if target.tilemap != world.tilemap:
				return false
			cell = target.tile_position
		else:
			return false
		if not ui.card.get_valid_targets(ui, ui.player_modifiers).has(cell) or world.tilemap.is_tile_behind_fog(cell):
			return false
	return ui.card.is_valid_target(selected_targets, ui.player_modifiers)


func begin_play(ui: CardUI, selected_targets: Array[Node]) -> bool:
	if not can_execute(ui, selected_targets):
		return false
	resolving_card = ui
	world.player_handler.resolving_action = true
	ui.disabled = true
	return true


func finish_play(ui: CardUI) -> void:
	if resolving_card != ui:
		return
	resolving_card = null
	if is_instance_valid(world) and is_instance_valid(world.player_handler):
		world.player_handler.resolving_action = false
