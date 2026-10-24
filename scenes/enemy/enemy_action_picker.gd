class_name EnemyActionPicker
extends Node

@export var enemy: Enemy:
	set = set_enemy
@export var target: Node2D:
	set = set_target


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	setup_chances()


func get_action() -> EnemyAction:
	refresh_target()
	var action := get_first_conditional_action()
	if action:
		return action

	return get_chance_based_action()


func get_first_conditional_action() -> EnemyAction:
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CONDITIONAL:
			continue

		if action.is_eligible():
			return action
	return null


func get_chance_based_action() -> EnemyAction:
	var decision_context := _build_decision_context()
	var weighted_actions: Array[Dictionary] = []
	var cumulative_weight := 0.0

	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue

		var action_weight := action.get_weight(decision_context)
		if not action.is_eligible():
			continue
		if action_weight <= 0.0:
			continue

		cumulative_weight += action_weight
		weighted_actions.append({
			"action": action,
			"cumulative": cumulative_weight
		})

	if weighted_actions.is_empty():
		return null

	var roll := RNG.instance.randf_range(0.0, cumulative_weight)
	for action_entry in weighted_actions:
		if action_entry["cumulative"] > roll:
			return action_entry["action"]
	return weighted_actions.back()["action"]


func setup_chances() -> void:
	# Weighting is recalculated per decision to respond to combat state; keep
	# this hook for editor readiness.
	pass


func set_enemy(value: Enemy) -> void:
	enemy = value

	for action: EnemyAction in get_children():
		action.enemy = enemy


func set_target(value: Node2D) -> void:
	target = value

	for action: EnemyAction in get_children():
		action.target = target


func _build_decision_context() -> Dictionary:
	if !is_instance_valid(enemy) or not is_instance_valid(target):
		return {}
	var context := {}
	var player: Node2D = target
	var player_stats: Stats = player.stats if player else null
	var enemy_stats := enemy.stats if enemy else null

	context["distance_to_player"] = _get_tile_distance_to_player()
	context["player_block"] = player_stats.block if player_stats else 0
	context["player_health"] = player_stats.health if player_stats else 0
	context["player_max_health"] = player_stats.max_health if player_stats else 1
	context["player_energy"] = player.stats.energy if player is Player else 0
	context["enemy_health"] = enemy_stats.health if enemy_stats else 0
	context["enemy_max_health"] = enemy_stats.max_health if enemy_stats else 1

	return context


func _get_tile_distance_to_player() -> float:
	if not enemy or not target:
		return 0.0
	if not enemy.tilemap or not enemy.tilemap.base_layer:
		return 0.0

	var enemy_tile := enemy.tilemap.base_layer.local_to_map(enemy.position)
	var player_tile := enemy.tilemap.base_layer.local_to_map(target.position)
	return Vector2(enemy_tile).distance_to(Vector2(player_tile))


func _get_first_chance_based_action() -> EnemyAction:
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		return action
	return null


func refresh_target() -> void:
	if not is_instance_valid(enemy) or not enemy.tilemap: return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var world := enemy.get_parent().get_parent() as GameWorld
	if not world or not world.summons: return
	if world.summons.living().is_empty():
		target = player
		return
	# Boss signatures and rooted rift seals preserve their authored player targets.
	if enemy.stats.tactics and enemy.stats.tactics.role == EnemyTactics.Role.DEBT_EATER:
		target = player
		return
	for action: Node in get_children():
		var path: String = action.get_script().resource_path if action.get_script() else ""
		if "/bosses/" in path or path.ends_with("rift_weaver_action.gd"):
			target = player
			return
	var candidates: Array[Node2D] = []
	if is_instance_valid(player): candidates.append(player)
	candidates.append_array(world.summons.living())
	var best: Node2D = player
	var best_hex_distance := 999
	for candidate in candidates:
		var cell := candidate.current_tile_position as Vector2i if candidate is Construct else enemy.tilemap.player_position
		var steps := _engagement_distance(cell)
		var hex_distance := SummonHandler.distance(enemy.tilemap, enemy.current_tile_position, cell)
		if steps < 999 and hex_distance < best_hex_distance:
			best = candidate
			best_hex_distance = hex_distance
	target = best

func _engagement_distance(destination: Vector2i) -> int:
	var board := enemy.tilemap
	var preferred := enemy.stats.tactics.preferred_range if enemy.stats.tactics else 1
	var frontier: Array[Vector2i] = [enemy.current_tile_position]
	var distances: Dictionary[Vector2i, int] = {enemy.current_tile_position: 0}
	var index := 0
	while index < frontier.size():
		var cell := frontier[index]
		index += 1
		if SummonHandler.distance(board, cell, destination) <= preferred:
			return distances[cell]
		if not enemy is MovingEnemy: continue
		for neighbor in board.base_layer.get_surrounding_cells(cell):
			if not distances.has(neighbor) and (enemy as MovingEnemy).can_move_to_tile(neighbor):
				distances[neighbor] = distances[cell] + 1
				frontier.append(neighbor)
	return 999
