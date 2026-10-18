extends Node

@export var card_registry: CardRegistry
@export var encounter_registry: EncounterRegistry
@export var enemy_catalog: EnemyCatalog
@export var card_registry_paths: Array[String] = [
	"res://resources/data/registries/card_registry_riftwalker.tres"
]
@export var encounter_registry_paths: Array[String] = [
	"res://resources/data/registries/encounter_registry_act1.tres"
]
@export var enemy_catalog_paths: Array[String] = [
	"res://resources/data/catalogs/enemy_catalog.tres"
]


func _ready() -> void:
	_ensure_card_registry()
	_ensure_encounter_registry()
	_ensure_enemy_catalog()


func _ensure_card_registry() -> void:
	if card_registry:
		return
	for path: String in card_registry_paths:
		var res := load(path)
		if res is CardRegistry:
			card_registry = res
			return


func _ensure_encounter_registry() -> void:
	if encounter_registry:
		return
	for path: String in encounter_registry_paths:
		var res := load(path)
		if res is EncounterRegistry:
			encounter_registry = res
			return


func _ensure_enemy_catalog() -> void:
	if enemy_catalog:
		return
	for path: String in enemy_catalog_paths:
		var res := load(path)
		if res is EnemyCatalog:
			enemy_catalog = res
			return


func get_card_entries() -> Array[Dictionary]:
	_ensure_card_registry()
	if card_registry and not card_registry.entries.is_empty():
		return card_registry.entries.duplicate()
	return _scan_card_resources()


func get_encounter_entries() -> Array[Dictionary]:
	_ensure_encounter_registry()
	if encounter_registry and not encounter_registry.entries.is_empty():
		return encounter_registry.entries.duplicate()
	return _scan_encounter_resources()


func _scan_card_resources() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var dir := DirAccess.open("res://resources/data/cards")
	if not dir:
		return results
	var paths := _gather_resources("res://resources/data/cards", ["tres"])
	for path in paths:
		var res := load(path)
		if res is Card:
			var card := res as Card
			results.append({
				"card": card,
				"path": path,
				"label": card.name if card.name else path.get_file().get_basename(),
				"rarity": card.card_rarity,
				"tags": card.tags
			})
	return results


func _scan_encounter_resources() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var paths := _gather_resources("res://resources/data/battles", ["tres"])
	for path in paths:
		var res := load(path)
		if res is BattleStats:
			var stats := res as BattleStats
			results.append({
				"path": path,
				"label": path.get_file().get_basename(),
				"tier": stats.battle_tier,
				"is_elite": stats.is_elite
			})
	return results


func _gather_resources(base_path: String, extensions: Array[String]) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(base_path)
	if not dir:
		return results
	dir.list_dir_begin()
	var res_name := dir.get_next()
	while res_name != "":
		if res_name.begins_with("."):
			res_name = dir.get_next()
			continue
		var full_path := base_path.path_join(res_name)
		if dir.current_is_dir():
			results += _gather_resources(full_path, extensions)
		elif extensions.has(res_name.get_extension()):
			results.append(full_path)
		res_name = dir.get_next()
	dir.list_dir_end()
	results.sort()
	return results
