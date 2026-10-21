extends RefCounted

var run_node: Run

func view() -> Node:
	return run_node.current_view.get_child(0) if run_node.current_view.get_child_count() else null

func observe() -> Dictionary:
	return {"phase": "progression", "floor": run_node.run_stats.completed_floors + run_node.map.floors_climbed, "act": run_node.run_stats.act_index + 1, "health": run_node.player_stats.health,
		"gold": run_node.run_stats.gold, "resources": run_node.run_stats.resources,
		"max_health": run_node.player_stats.max_health, "deck_size": run_node.player_stats.deck.cards.size()}

func legal_actions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current := view()
	if run_node.map.visible:
		for i in run_node.map.map_nodes.get_child_count():
			var route := run_node.map.map_nodes.get_child(i) as MapNodeUI
			if route.available and not route.map_node.selected:
				result.append({"kind": "route", "index": i, "type": Enums.MapNodeType.keys()[route.map_node.type]})
	elif current is ActTransition:
		result.append({"kind": "next_act"})
	elif current is BattleRewards:
		for child in current.ui_layer.get_children():
			if child is CardRewards and not child.is_queued_for_deletion():
				for i in child.rewards.size():
					result.append({"kind": "card_reward", "index": i, "card": child.rewards[i].id})
				result.append({"kind": "skip_card"})
				return result
		for list_name in ["rewards", "enemy_rewards"]:
			var container: Node = current.get(list_name)
			for i in container.get_child_count():
				var button := container.get_child(i) as Button
				if button and not button.disabled and not button.is_queued_for_deletion():
					result.append({"kind": "reward", "list": list_name, "index": i, "name": button.reward_text})
		result.append({"kind": "leave_rewards"})
	elif current is Rest and not current.rest_button.disabled:
		result.append({"kind": "rest"})
	elif current is Shop:
		for i in current.relics.get_child_count():
			var relic := current.relics.get_child(i) as ShopRelic
			if not relic.is_queued_for_deletion() and not relic.buy_button.disabled:
				result.append({"kind": "buy_relic", "index": i, "relic": relic.relic.id, "cost": relic.resource_cost})
		for i in current.cards.get_child_count():
			var card := current.cards.get_child(i) as ShopCard
			if not card.is_queued_for_deletion() and not card.buy_button.disabled:
				result.append({"kind": "buy_card", "index": i, "card": card.card.id, "cost": card.gold_cost})
		result.append({"kind": "leave_shop"})
	elif current is Treasure and not current.opening and not current.reward_emitted:
		result.append({"kind": "treasure"})
	elif current is EventRoom:
		if not current.option_a_button.disabled:
			result.append({"kind": "event_option", "index": 0})
		if not current.option_b_button.disabled:
			result.append({"kind": "event_option", "index": 1})
		if not current.leave_button.disabled:
			result.append({"kind": "leave_event"})
	elif current is GameWorld and current.battle_over_handled and current.victory_committed:
		var panel := current.game_world_ui.get_node("BattleOverLayer/BattleOverPanel") as BattleOverPanel
		if panel.visible and run_node.get_tree().paused:
			result.append({"kind": "continue_battle"})
	return result

func execute(action: Dictionary) -> bool:
	if not JSON.parse_string(JSON.stringify(action)) in JSON.parse_string(JSON.stringify(legal_actions())):
		return false
	var current := view()
	match action.kind:
		"next_act": current.get_node("Center/Layout/Continue").pressed.emit()
		"route": return run_node.map.map_nodes.get_child(int(action.index)).select_route()
		"reward":
			var button: Button = current.get(action.list).get_child(int(action.index))
			button.pressed.emit()
		"card_reward", "skip_card":
			for child in current.ui_layer.get_children():
				if child is CardRewards:
					if action.kind == "skip_card": child._on_skip_pressed()
					else: child._on_card_confirmed(child.rewards[int(action.index)])
					break
		"leave_rewards": current._on_back_button_pressed()
		"rest": current._on_rest_button_pressed()
		"leave_shop": current._on_leave_button_pressed()
		"buy_card": current.cards.get_child(int(action.index)).buy_button.pressed.emit()
		"buy_relic": current.relics.get_child(int(action.index)).buy_button.pressed.emit()
		"treasure": current.open_button.pressed.emit()
		"event_option": current._run_option_by_index(int(action.index))
		"leave_event": current._leave_event()
		"continue_battle": current.game_world_ui.get_node("BattleOverLayer/BattleOverPanel").continue_button.pressed.emit()
	return true
