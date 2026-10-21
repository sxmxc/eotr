extends RefCounted

const VERSION := "2.1.0"
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
		if action.kind == "buy_relic":
			return 12.0
		if action.kind in ["buy_card", "card_reward"]:
			if int(state.get("deck_size", 11)) >= 22: return -4.0
			var preferred := {"nano_shield": 16.0, "mana_leech": 14.0, "adrenaline_rush": 14.0, "rift_knowledge": 12.0, "phase_slash": 10.0, "focus": 8.0, "arcane_explosion": 8.0}
			return float(preferred.get(action.card, 1.0 if action.kind == "buy_card" else 2.0)) + rng.randf()
		if action.kind == "route":
			var missing: int = int(state.get("max_health", 35)) - int(state.health)
			return {"REST": 12.0 if missing >= 8 else 1.0, "TREASURE": 10.0, "EVENT": 5.0, "SHOP": 8.0 if int(state.get("gold", 0)) >= 100 or int(state.get("resources", 0)) >= 6 else 2.0, "MONSTER": 3.0, "ELITE": -3.0, "BOSS": 0.0}.get(action.type, 0.0) + rng.randf()
		if action.kind == "reward":
			if action.name.begins_with("Recover"):
				return 15.0 if int(state.get("max_health", 35)) - int(state.health) >= 4 else -3.0
			if action.name == "Discover a new card":
				return 1.0 if int(state.get("deck_size", 11)) < 22 else -3.0
		if action.kind == "card_reward" and int(state.get("deck_size", 11)) >= 22:
			return -4.0
		return -2.0 if action.kind in ["leave_rewards", "skip_card", "leave_event"] else 2.0 + rng.randf()
	var score := 1.0 / (1.0 + float(action.cost))
	if action.card in ["mana_surge", "nano_shield", "adrenaline_rush", "rift_knowledge"]:
		return score + 20.0
	if int(action.card_type) == Enums.CardType.DEFENSE and int(state.block) < 8:
		return score + 14.0
	if int(action.card_type) == Enums.CardType.ATTACK:
		score += 10.0 + 5.0 / maxf(float(action.target_health), 1.0) + (1.0 if action.obelisk else 2.0)
	elif int(action.card_type) == Enums.CardType.MOVEMENT:
		var destination := Vector2(action.tile[0], action.tile[1])
		var origin := Vector2(state.player_tile[0], state.player_tile[1])
		if destination == origin:
			return -12.0
		var nearest := INF
		var current_nearest := INF
		for enemy in state.enemies:
			var position := Vector2(enemy.tile[0], enemy.tile[1])
			nearest = minf(nearest, destination.distance_to(position))
			current_nearest = minf(current_nearest, origin.distance_to(position))
		if not state.enemies.is_empty():
			score += (current_nearest - nearest) * 3.0
			if nearest >= current_nearest and name != "stress":
				return -11.0
		else:
			score += rng.randf() * 2.0
		if name == "stress":
			score += 12.0 + destination.length() * 0.1
	else:
		score += 4.0 if state.health < 25 else 2.0
	return score
