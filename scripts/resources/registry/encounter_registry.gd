extends Resource
class_name EncounterRegistry

@export var entries: Array[Dictionary] = []

var _rng: RandomNumberGenerator


func clear_entries() -> void:
	entries.clear()


func add_battle_stats(
	battle_stats: BattleStats,
	tags: Array[String] = [],
	is_boss: bool = false,
	unlocked: bool = true
) -> void:
	if not battle_stats:
		return

	var entry := {
		"stats": battle_stats,
		"tier": battle_stats.battle_tier,
		"weight": float(battle_stats.weight),
		"tags": tags.duplicate(),
		"is_elite": battle_stats.is_elite,
		"is_boss": is_boss,
		"unlocked": unlocked
	}
	entries.append(entry)


func build_from_pool(pool: BattleStatsPool, default_tags: Array[String] = []) -> void:
	clear_entries()
	if not pool:
		return

	for stats: BattleStats in pool.pool:
		add_battle_stats(stats, default_tags)


func get_entries_for_tier(
	tier: int,
	required_tags: Array[String] = [],
	include_elite: bool = true,
	include_boss: bool = true
) -> Array[Dictionary]:
	return entries.filter(
		func(entry: Dictionary) -> bool:
			if entry.get("unlocked", true) == false:
				return false
			if entry.get("tier", -1) != tier:
				return false
			if not include_elite and entry.get("is_elite", false):
				return false
			if not include_boss and entry.get("is_boss", false):
				return false
			for tag: String in required_tags:
				var tags: Array = entry.get("tags", [])
				if not tags.has(tag):
					return false
			return true
	)


func get_random_battle(
	tier: int,
	required_tags: Array[String] = [],
	include_elite: bool = true,
	include_boss: bool = true,
	rng: RandomNumberGenerator = null
) -> BattleStats:
	var candidates := get_entries_for_tier(tier, required_tags, include_elite, include_boss)
	if candidates.is_empty():
		return null

	var total_weight := 0.0
	for entry: Dictionary in candidates:
		var entry_weight := float(entry.get("weight", 0.0))
		if entry_weight <= 0.0 and entry.has("stats") and entry.get("stats") is BattleStats:
			entry_weight = float((entry.get("stats") as BattleStats).weight)
		total_weight += entry_weight

	var used_rng := _get_rng(rng)
	var roll := used_rng.randf_range(0.0, total_weight)
	var accumulated := 0.0

	for entry: Dictionary in candidates:
		var entry_weight := float(entry.get("weight", 0.0))
		if entry_weight <= 0.0 and entry.has("stats") and entry.get("stats") is BattleStats:
			entry_weight = float((entry.get("stats") as BattleStats).weight)
		accumulated += entry_weight
		if roll <= accumulated:
			return entry.get("stats", null)

	return candidates.back().get("stats", null)


func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng


func _get_rng(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if rng:
		return rng
	if _rng:
		return _rng
	return RNG.instance
