extends RefCounted

const VERSION := "1.0.0"
var name := "random"
var rng := RandomNumberGenerator.new()

func choose(observation: Dictionary, actions: Array[Dictionary]) -> Dictionary:
	var ranked: Array[Dictionary] = []
	for action in actions:
		var score := rng.randf()
		if name != "random":
			score = score_action(observation, action)
		ranked.append({"action": action, "score": score})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary): return a.score > b.score)
	return {"action": ranked[0].action, "reason": "Highest %s policy score" % name, "alternatives": ranked.slice(0, 12), "version": VERSION}

func score_action(state: Dictionary, action: Dictionary) -> float:
	if action.kind == "end_turn":
		return -10.0
	if action.kind != "play_card":
		return -2.0 if action.kind in ["leave_rewards", "skip_card", "leave_event"] else 2.0 + rng.randf()
	var score := 1.0 / (1.0 + float(action.cost))
	if int(action.card_type) == Enums.CardType.ATTACK:
		score += 10.0 + 5.0 / maxf(float(action.target_health), 1.0) + (1.0 if action.obelisk else 2.0)
	elif int(action.card_type) == Enums.CardType.MOVEMENT:
		var destination := Vector2(action.tile[0], action.tile[1])
		var origin := Vector2(state.player_tile[0], state.player_tile[1])
		var nearest := INF
		var current_nearest := INF
		for enemy in state.enemies:
			var position := Vector2(enemy.tile[0], enemy.tile[1])
			nearest = minf(nearest, destination.distance_to(position))
			current_nearest = minf(current_nearest, origin.distance_to(position))
		if not state.enemies.is_empty():
			score += (current_nearest - nearest) * 3.0
		else:
			score += rng.randf() * 2.0
		if name == "stress":
			score += 12.0 + destination.length() * 0.1
	else:
		score += 4.0 if state.health < 25 else 2.0
	return score
