extends RefCounted
class_name BountySystem

const CONTRACTS_PER_REFRESH := 3
const REFRESH_INTERVAL_FLOORS := 5
const HIGH_VALUE_CHANCE := 0.25
const HIGH_VALUE_MULTIPLIER := 2.0


static func ensure_contracts(
	run_stats: RunStats,
	floors_climbed: int,
	candidate_nodes: Array[MapNode],
	battle_stats_pool: BattleStatsPool
) -> void:
	if not run_stats:
		return

	var refresh_due: bool = run_stats.bounty_contracts.is_empty() or floors_climbed >= run_stats.next_bounty_refresh_floor
	if not refresh_due:
		return

	var candidate_battles: Array[BattleStats] = []
	for node: MapNode in candidate_nodes:
		if node and node.battle_stats:
			candidate_battles.append(node.battle_stats)

	if candidate_battles.is_empty() and battle_stats_pool:
		candidate_battles = battle_stats_pool.pool.duplicate()

	var enemy_data: Array[Dictionary] = _collect_enemy_data(candidate_battles)
	run_stats.bounty_contracts = _roll_contracts(enemy_data)
	run_stats.next_bounty_refresh_floor = floors_climbed + REFRESH_INTERVAL_FLOORS


static func apply_bounty_for_enemy(run_stats: RunStats, enemy_name: String, battle_stats: BattleStats) -> void:
	if not run_stats or not battle_stats:
		return
	for contract: BountyContract in run_stats.bounty_contracts:
		if contract.enemy_name != enemy_name:
			continue
		battle_stats.enemy_gold_reward += contract.gold
		battle_stats.enemy_resource_reward += contract.resources


static func _collect_enemy_data(battles: Array[BattleStats]) -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for bs: BattleStats in battles:
		if not bs or not bs.enemies:
			continue
		var instance: Node = bs.enemies.instantiate()
		for child in instance.get_children():
			var enemy := child as Enemy
			if not enemy or not enemy.stats:
				continue
			data.append({
				"name": enemy.stats.enemy_name,
				"gold": enemy.stats.gold_value,
				"resources": enemy.stats.resource_value_max
			})
		instance.free()
	return data


static func _roll_contracts(enemy_data: Array[Dictionary]) -> Array[BountyContract]:
	var contracts: Array[BountyContract] = []
	if enemy_data.is_empty():
		return contracts

	var unique_by_name: Dictionary = {}
	for entry in enemy_data:
		var name: String = entry.get("name", "")
		if name.is_empty():
			continue
		if not unique_by_name.has(name):
			unique_by_name[name] = entry

	var pool: Array[Dictionary] = []
	for value in unique_by_name.values():
		pool.append(value as Dictionary)
	if pool.is_empty():
		return contracts

	var picks: int = min(CONTRACTS_PER_REFRESH, pool.size())
	for _i in range(picks):
		var selected: Dictionary = _pick_weighted_entry(pool)
		if selected.is_empty():
			break
		var is_high_value: bool = RNG.instance.randf() < HIGH_VALUE_CHANCE
		var gold_reward: int = _compute_gold_reward(selected, is_high_value)
		var resource_reward: int = _compute_resource_reward(selected, is_high_value)
		var contract: BountyContract = BountyContract.new()
		contract.enemy_name = selected["name"]
		contract.gold = gold_reward
		contract.resources = resource_reward
		contract.is_high_value = is_high_value
		contracts.append(contract)
		var filtered: Array[Dictionary] = []
		for entry in pool:
			if entry.get("name", "") != contract.enemy_name:
				filtered.append(entry)
		pool = filtered
		if pool.is_empty():
			break
	return contracts


static func _pick_weighted_entry(entries: Array[Dictionary]) -> Dictionary:
	var total_weight := 0.0
	for entry in entries:
		total_weight += _entry_weight(entry)
	if total_weight <= 0.0:
		return entries[0]
	var roll: float = RNG.instance.randf_range(0.0, total_weight)
	for entry in entries:
		var weight: float = _entry_weight(entry)
		if weight <= 0.0:
			continue
		roll -= weight
		if roll <= 0.0:
			return entry
	return entries.back()


static func _entry_weight(entry: Dictionary) -> float:
	var gold: float = float(entry.get("gold", 1))
	var res: float = float(entry.get("resources", 0))
	return max(1.0, gold * 0.6 + res * 0.4)


static func _compute_gold_reward(entry: Dictionary, high_value: bool) -> int:
	var base_gold: int = int(entry.get("gold", 1))
	var scaled := int(round(base_gold * RNG.instance.randf_range(1.5, 2.5) + RNG.instance.randi_range(4, 10)))
	if high_value:
		scaled = int(round(scaled * HIGH_VALUE_MULTIPLIER))
	return max(1, scaled)


static func _compute_resource_reward(entry: Dictionary, high_value: bool) -> int:
	var base_res: int = int(entry.get("resources", 0))
	var scaled := int(round(base_res * RNG.instance.randf_range(0.6, 1.4)))
	if high_value:
		scaled = int(round(scaled * HIGH_VALUE_MULTIPLIER))
	return max(0, scaled)
