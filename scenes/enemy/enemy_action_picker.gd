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
	var action := get_first_conditional_action()
	if action:
		return action

	return get_chance_based_action()


func get_first_conditional_action() -> EnemyAction:
	for action: EnemyAction in get_children():
		if not action or action.type != EnemyAction.Type.CONDITIONAL:
			continue

		if action.is_performable():
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
		if action_weight <= 0.0:
			continue

		cumulative_weight += action_weight
		weighted_actions.append({
			"action": action,
			"cumulative": cumulative_weight
		})

	if weighted_actions.is_empty():
		return _get_first_chance_based_action()

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
	var context := {}
	var player := target as Player
	var player_stats := player.stats if player else null
	var enemy_stats := enemy.stats if enemy else null

	context["distance_to_player"] = _get_tile_distance_to_player()
	context["player_block"] = player_stats.block if player_stats else 0
	context["player_health"] = player_stats.health if player_stats else 0
	context["player_max_health"] = player_stats.max_health if player_stats else 1
	context["player_energy"] = player_stats.energy if player_stats else 0
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
