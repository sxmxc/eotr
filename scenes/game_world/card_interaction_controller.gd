class_name CardInteractionController
extends Node

var world: GameWorld
var resolving_card: CardUI
var active_card: CardUI
var relocation_unit: Construct
var _cards: Dictionary[int, WeakRef] = {}
var _shutting_down := false
var _input_was_open := false
var _gesture_state := CardState.State.BASE


func bind_world(value: GameWorld) -> void:
	world = value
	world.target_selector.bind_interaction(self, world.tilemap)
	world.target_selector.cache_invalidated.connect(refresh_preview)
	world.tilemap.presentation_changed.connect(world.target_selector._reset_cache)
	world.battle_state.phase_changed.connect(_on_phase_changed)
	world.tree_exiting.connect(shutdown)


func register_card(ui: CardUI) -> void:
	_cards[ui.get_instance_id()] = weakref(ui)


func card_exiting(ui: CardUI) -> void:
	# Reparenting also exits the tree. Reconcile after it has finished, using an ID
	# so the callback neither retains nor dereferences a destroyed card.
	_reconcile_card.call_deferred(ui.get_instance_id())


func _reconcile_card(id: int) -> void:
	if not _cards.has(id):
		return
	var ui := _cards[id].get_ref() as CardUI
	if is_instance_valid(ui) and ui.is_inside_tree() and not ui.is_queued_for_deletion():
		return
	_cards.erase(id)
	if not is_instance_valid(active_card) or active_card == ui:
		cancel_active(false)
	if not is_instance_valid(resolving_card) or resolving_card == ui:
		resolving_card = null
		if is_instance_valid(world) and is_instance_valid(world.player_handler):
			world.player_handler.resolving_action = false
	_refresh_cards()


func _process(_delta: float) -> void:
	if _shutting_down:
		return
	if is_instance_valid(active_card) and not can_interact(active_card):
		cancel_active()
	var input_open := _input_open()
	if input_open != _input_was_open:
		_input_was_open = input_open
		_refresh_cards()


func _input_open() -> bool:
	return not _shutting_down and is_instance_valid(world) and world.is_inside_tree() \
		and not world.is_queued_for_deletion() and not world.battle_over_handled \
		and world.battle_state.phase == BattleStateController.Phase.PLAYER_TURN \
		and world.player_handler.hand_ready and not world.player_handler.resolving_action \
		and world.player.pending_effects == 0


func is_locked_for(ui: CardUI) -> bool:
	return not _input_open() or is_instance_valid(resolving_card) \
		or (is_instance_valid(active_card) and active_card != ui)


func can_interact(ui: CardUI) -> bool:
	return is_instance_valid(ui) and ui.interaction_controller == self \
		and ui._play_context_active() and ui.card != null and not ui.disabled \
		and ui.parent == world.player_handler.player_hand \
		and ui.player_stats == world.player_stats and ui.player_stats.can_play_card(ui.card)


func transition(ui: CardUI, from: CardState, to: CardState.State) -> void:
	if ui.card_state_machine.current_state != from:
		return
	var entering_gesture := to in [CardState.State.CLICKED, CardState.State.DRAGGING, CardState.State.AIMING]
	if entering_gesture and not can_interact(ui):
		return
	if is_instance_valid(active_card) and active_card != ui:
		return
	_end_feedback(from.state, to == CardState.State.RELEASED)
	if entering_gesture:
		active_card = ui
		_gesture_state = to
	else:
		active_card = null
		_gesture_state = CardState.State.BASE
		if to == CardState.State.BASE:
			relocation_unit = null
			ui.targets.clear()
	ui.card_state_machine.change_state(to)
	ui.drop_point_detector.set_deferred("monitoring", to in [CardState.State.CLICKED, CardState.State.DRAGGING])
	match to:
		CardState.State.DRAGGING:
			Events.card_drag_started.emit(ui)
			show_targets(ui)
		CardState.State.AIMING:
			world.target_selector.begin_aim(ui)
			Events.card_aim_started.emit(ui)
			refresh_preview()
	_refresh_cards()


func _end_feedback(state: CardState.State, keep_target := false) -> void:
	var ui := active_card if is_instance_valid(active_card) else null
	if state == CardState.State.AIMING:
		if is_instance_valid(world) and is_instance_valid(world.target_selector):
			world.target_selector.end_aim(keep_target)
		Events.card_aim_ended.emit(ui)
	elif state == CardState.State.DRAGGING:
		Events.card_drag_ended.emit(ui)
	clear_targets()
	Events.tooltip_hide_requested.emit()


func cancel_active(restore_hand := true) -> void:
	relocation_unit = null
	var ui := active_card
	_end_feedback(_gesture_state, is_instance_valid(resolving_card) and not _shutting_down)
	if is_instance_valid(ui):
		ui.targets.clear()
	else:
		if is_instance_valid(world) and is_instance_valid(world.target_selector):
			world.target_selector.end_aim(is_instance_valid(resolving_card) and not _shutting_down)
		clear_targets()
		Events.tooltip_hide_requested.emit()
	active_card = null
	_gesture_state = CardState.State.BASE
	if restore_hand and is_instance_valid(ui) and ui.is_inside_tree() and not ui.is_queued_for_deletion():
		ui.card_state_machine.change_state(CardState.State.BASE)
	_refresh_cards()


func _on_phase_changed(phase: BattleStateController.Phase) -> void:
	if phase != BattleStateController.Phase.PLAYER_TURN:
		cancel_active()
	_refresh_cards()


func shutdown() -> void:
	_shutting_down = true
	cancel_active(false)
	if is_instance_valid(resolving_card):
		finish_play(resolving_card)


func _exit_tree() -> void:
	shutdown()


func _refresh_cards() -> void:
	for reference: WeakRef in _cards.values():
		var ui := reference.get_ref() as CardUI
		if is_instance_valid(ui) and ui.is_node_ready():
			ui._refresh_interaction_visuals()


func valid_cells(ui: CardUI) -> Array[Vector2i]:
	var candidates := world.target_selector.get_cached_targets(ui)
	var visible: Array[Vector2i] = []
	if ui.card.target_type in [Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ADJACENT_ENEMY]:
		for enemy: Enemy in world.enemy_handler.get_children():
			if _valid_target(ui, enemy, candidates):
				visible.append(enemy.current_tile_position)
	else:
		for cell: Vector2i in candidates:
			if world.tilemap.is_within_bounds(cell) and not world.tilemap.is_tile_behind_fog(cell):
				visible.append(cell)
	return visible


func is_preview_target(ui: CardUI, target: Node) -> bool:
	return _valid_target(ui, target, valid_cells(ui))


func _valid_target(ui: CardUI, target: Node, cells: Array[Vector2i]) -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree() or target.is_queued_for_deletion():
		return false
	var cell: Vector2i
	if target is Enemy:
		if target.get_parent() != world.enemy_handler or target.is_dying or target.stats.health <= 0:
			return false
		if ui.card.target_type not in [Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ADJACENT_ENEMY]:
			return false
		cell = target.current_tile_position
	elif target is Construct:
		if target.get_parent() != world.summons or target.is_dying or target.stats.health <= 0 or ui.card.target_type != Enums.TargetType.ALLY:
			return false
		cell = target.current_tile_position
	elif target is TilemapTarget:
		if target.tilemap != world.tilemap or (ui.card.target_type != Enums.TargetType.SINGLE_TILE and not is_relocating(ui)):
			return false
		cell = target.tile_position
	else:
		return false
	var targets: Array[Node] = []
	targets.assign([relocation_unit, target] if is_relocating(ui) and target is TilemapTarget else [target])
	return cells.has(cell) and not world.tilemap.is_tile_behind_fog(cell) \
		and ui.card.is_valid_target(targets, ui.player_modifiers)


func is_relocating(ui: CardUI) -> bool:
	return active_card == ui and ui.card.id == "redeployment" and is_instance_valid(relocation_unit) and not relocation_unit.is_dying


func select_target(ui: CardUI, target: Node) -> void:
	if active_card != ui or not is_preview_target(ui, target):
		return
	ui.targets.assign([relocation_unit, target] if is_relocating(ui) and target is TilemapTarget else [target])
	ui.request_description()
	if target is Enemy:
		Events.enemy_selected.emit(target)


func update_drop_target(ui: CardUI, area: Area2D, entered: bool) -> void:
	if active_card != ui or ui.card.is_single_targeted() or area != world.game_world_ui.card_drop_area:
		return
	if entered:
		if not ui.targets.has(area):
			ui.targets.append(area)
	else:
		ui.targets.erase(area)


func enemy_modifiers(ui: CardUI) -> ModifierHandler:
	if active_card != ui or ui.targets.size() != 1:
		return null
	var target := ui.targets[0]
	return target.modifier_handler if is_preview_target(ui, target) and target is Enemy else null


func refresh_preview() -> void:
	if not is_instance_valid(active_card) or not active_card.card.is_single_targeted():
		return
	if not active_card.targets.is_empty() and not is_preview_target(active_card, active_card.targets[-1]):
		active_card.targets.clear()
	show_targets(active_card)
	active_card.request_description()


func show_targets(ui: CardUI) -> void:
	if is_instance_valid(world) and active_card == ui:
		world.tilemap.show_target_highlights(valid_cells(ui))


func clear_targets() -> void:
	if is_instance_valid(world) and is_instance_valid(world.tilemap):
		world.tilemap.clear_target_highlights()


func handle_input(state: CardState, event: InputEvent) -> void:
	var ui := state.card_ui
	if active_card != ui or ui.interaction_controller != self or not is_instance_valid(world):
		return
	if not can_interact(ui):
		cancel_active()
		return
	var motion := event is InputEventMouseMotion
	var cancel := event.is_action_pressed("right_mouse")
	var confirm := event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	match state.state:
		CardState.State.CLICKED:
			if cancel or event.is_action_released("left_mouse"):
				_cancel(state)
			elif motion:
				state.transition_requested.emit(state, CardState.State.DRAGGING)
		CardState.State.DRAGGING:
			show_targets(ui)
			if ui.card.is_single_targeted() and motion:
				state.transition_requested.emit(state, CardState.State.AIMING)
				return
			if motion:
				ui.global_position = ui.get_global_mouse_position() - ui.pivot_offset
			if cancel:
				_cancel(state)
			elif confirm:
				_release(state)
		CardState.State.AIMING:
			var at_bottom := ui.get_global_mouse_position().y > ui.get_viewport_rect().size.y - ui.aim_cancel_margin
			if (motion and at_bottom) or cancel:
				_cancel(state)
			elif confirm:
				_release(state)


func _cancel(state: CardState) -> void:
	relocation_unit = null
	state.card_ui.targets.clear()
	state.transition_requested.emit(state, CardState.State.BASE)


func _release(state: CardState) -> void:
	var ui := state.card_ui
	if ui.card.id == "redeployment" and not is_relocating(ui) and ui.targets.size() == 1 and ui.targets[0] is Construct:
		relocation_unit = ui.targets[0]
		ui.targets.clear()
		world.target_selector._reset_cache()
		return
	if ui.card.id == "redeployment" and is_relocating(ui) and ui.targets.size() != 2:
		return
	state.card_ui.get_viewport().set_input_as_handled()
	state.transition_requested.emit(state, CardState.State.RELEASED)


func can_execute(ui: CardUI, selected_targets: Array[Node]) -> bool:
	if not is_instance_valid(world) or not world.is_inside_tree() or world.is_queued_for_deletion():
		return false
	if not is_instance_valid(ui) or ui.interaction_controller != self or not ui._play_context_active():
		return false
	if ui.disabled or not ui.card or ui.player_stats != world.player_stats:
		return false
	if ui.parent != world.player_handler.player_hand:
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
		if target is TilemapTarget:
			if target.tilemap != world.tilemap:
				return false
		elif target is Construct:
			if target.get_parent() != world.summons or target.is_dying: return false
		elif target != world.player and target != world.game_world_ui.card_drop_area and target.get_parent() != world.enemy_handler:
			return false
	if ui.card.id == "redeployment":
		return selected_targets.size() == 2 and selected_targets[0] is Construct and selected_targets[1] is TilemapTarget and ui.card.is_valid_target(selected_targets, ui.player_modifiers) and not world.tilemap.is_tile_behind_fog(selected_targets[0].current_tile_position)
	if ui.card.is_single_targeted():
		return selected_targets.size() == 1 and _valid_target(ui, selected_targets[0], ui.card.get_valid_targets(ui, ui.player_modifiers))
	return ui.card.is_valid_target(selected_targets, ui.player_modifiers)


func begin_play(ui: CardUI, selected_targets: Array[Node]) -> bool:
	if not can_execute(ui, selected_targets):
		return false
	resolving_card = ui
	if active_card == ui:
		_end_feedback(ui.card_state_machine.current_state.state, true)
		active_card = null
		_gesture_state = CardState.State.BASE
	world.player_handler.resolving_action = true
	ui.disabled = true
	_refresh_cards()
	return true


func finish_play(ui: CardUI) -> void:
	if resolving_card != ui:
		return
	resolving_card = null
	relocation_unit = null
	if is_instance_valid(world) and is_instance_valid(world.player_handler):
		world.player_handler.resolving_action = false
		if is_instance_valid(world.target_selector):
			world.target_selector.release_tile_target()
	_refresh_cards()
