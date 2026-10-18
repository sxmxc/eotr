extends Resource
class_name EncounterRegistry

@export var encounters: Array[EncounterDefinition] = []

func find(encounter_id: String) -> EncounterDefinition:
	for encounter in encounters:
		if encounter.encounter_id == encounter_id:
			return encounter
	return null

func select(tier: int, categories: Array[int], required_tags: Array[String] = [], excluded_ids: Array[String] = [], override_id: String = "", rng: RandomNumberGenerator = null) -> EncounterDefinition:
	if not override_id.is_empty():
		var override := find(override_id)
		return override if override and override.unlocked else null
	var candidates: Array[EncounterDefinition] = []
	for encounter in encounters:
		if not encounter.unlocked or encounter.battle_tier != tier or encounter.weight <= 0.0:
			continue
		if not categories.has(encounter.category):
			continue
		var eligible := true
		for tag in required_tags:
			if not encounter.tags.has(tag):
				eligible = false
		if eligible:
			candidates.append(encounter)
	var fresh: Array[EncounterDefinition] = []
	for encounter in candidates:
		if not excluded_ids.has(encounter.encounter_id):
			fresh.append(encounter)
	if not fresh.is_empty():
		candidates = fresh
	if candidates.is_empty():
		return null
	var total := 0.0
	for encounter in candidates:
		total += encounter.weight
	var used_rng := rng if rng else RNG.instance
	var roll := used_rng.randf() * total
	for encounter in candidates:
		roll -= encounter.weight
		if roll < 0.0:
			return encounter
	return candidates.back()
