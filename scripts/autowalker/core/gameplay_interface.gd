extends RefCounted

var world: GameWorld
var progression: RefCounted

func ready_for_action() -> bool:
	if progression and not progression.legal_actions().is_empty():
		return true
	return is_instance_valid(world) and is_instance_valid(world.player) and world.player.pending_effects == 0 and not world.battle_over_handled and world.battle_state.phase == BattleStateController.Phase.PLAYER_TURN and world.player_handler.hand_ready and not world.player_handler.resolving_action

func observe() -> Dictionary:
	if progression and (not is_instance_valid(world) or world.battle_over_handled):
		return progression.observe()
	var enemies: Array = []
	for node in world.enemy_handler.get_children():
		if node is Enemy and not node.is_dying and not world.tilemap.is_tile_behind_fog(node.current_tile_position):
			enemies.append({"name": node.stats.enemy_name, "health": node.stats.health, "block": node.stats.block,
				"tile": [node.current_tile_position.x, node.current_tile_position.y], "obelisk": node is Obelisk,
				"intent": node.current_action.intent.current_text if node.current_action and node.current_action.intent else "No action"})
	return {"turn": world.current_round, "phase": BattleStateController.Phase.keys()[world.battle_state.phase],
		"health": world.player_stats.health, "energy": world.player_stats.energy, "block": world.player_stats.block,
		"player_tile": [world.tilemap.player_position.x, world.tilemap.player_position.y],
		"collapse_in": world.rounds_until_shrink, "enemies": enemies}

func legal_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if progression:
		actions = progression.legal_actions()
		if not actions.is_empty():
			return actions
	if not is_instance_valid(world) or world.battle_over_handled:
		return []
	if not ready_for_action():
		return actions
	var cards: Array = _active_cards()
	for slot in cards.size():
		var ui := cards[slot] as CardUI
		if not ui or ui.disabled or not ui.card or not world.player_stats.can_play_card(ui.card):
			continue
		var cells: Array[Vector2i] = ui.card.get_valid_targets(ui, world.player.modifier_handler)
		if not ui.card.is_single_targeted():
			cells = [world.tilemap.player_position]
		for cell in cells:
			var target := _target(ui.card, cell)
			if not target:
				continue
			var targets: Array[Node] = [target]
			if ui.can_execute(targets):
				var action := {"kind": "play_card", "slot": slot, "card": ui.card.id, "name": ui.card.name,
					"tile": [cell.x, cell.y], "cost": ui.card.get_energy_cost(world.player_stats),
					"card_type": int(ui.card.card_type), "target_health": target.stats.health if target is Enemy else 0,
					"obelisk": target is Obelisk}
				actions.append(action)
			if target is TilemapTarget:
				target.free()
	actions.append({"kind": "end_turn"})
	return actions

func _target(card: Card, cell: Vector2i) -> Node:
	if not card.is_single_targeted():
		return world.player
	if world.tilemap.is_tile_behind_fog(cell):
		return null
	if card.target_type == Enums.TargetType.SINGLE_TILE:
		var target := TilemapTarget.new(cell, world.tilemap)
		world.add_child(target)
		return target
	for node in world.enemy_handler.get_children():
		if node is Enemy and node.current_tile_position == cell and node.stats.health > 0 and not node.is_dying:
			return node
	return null

func execute(action: Dictionary) -> bool:
	# Enumerate again immediately; artifacts never grant extra permissions.
	var normalized: Variant = JSON.parse_string(JSON.stringify(action))
	var current_actions: Array = JSON.parse_string(JSON.stringify(legal_actions()))
	if not normalized in current_actions:
		return false
	if action.kind not in ["play_card", "end_turn"]:
		return progression.execute(action)
	if action.kind == "end_turn":
		Events.player_turn_ended.emit()
		return true
	var ui := _active_cards()[int(action.slot)] as CardUI
	var cell := Vector2i(int(action.tile[0]), int(action.tile[1]))
	var target := _target(ui.card, cell)
	if not is_instance_valid(target):
		return false
	ui.targets.assign([target])
	world.tilemap.show_target_highlights([cell])
	if target is Enemy:
		Events.enemy_selected.emit(target)
	await ui.play()
	world.tilemap.clear_target_highlights()
	if is_instance_valid(target) and target is TilemapTarget:
		target.queue_free()
	return true

func _active_cards() -> Array:
	return world.player_handler.player_hand.get_cards().filter(func(ui): return ui is CardUI and not ui.disabled)

func checkpoint() -> Dictionary:
	if progression and (not is_instance_valid(world) or world.battle_over_handled):
		var deck: Array = []
		for card: Card in progression.run_node.player_stats.deck.cards:
			deck.append(card.id)
		return {"state": progression.observe(), "actions": progression.legal_actions(), "deck": deck, "rng": str(RNG.instance.state)}
	# Diagnostic-only checkpoint includes hidden entities to detect replay divergence.
	var enemies: Array = []
	for node in world.enemy_handler.get_children():
		if node is Enemy and not node.is_dying:
			enemies.append([node.stats.enemy_name, node.stats.health, node.stats.block, node.current_tile_position.x, node.current_tile_position.y, node.turn_ticker])
	var hand: Array = []
	for ui: CardUI in world.player_handler.player_hand.get_cards():
		if not ui.disabled:
			hand.append(ui.card.id)
	return {"state": observe(), "all_enemies": enemies, "hand": hand, "rng": str(RNG.instance.state)}

func fingerprint() -> String:
	return JSON.stringify(checkpoint()).sha256_text()
