class_name SaveGame
extends Resource

const SAVE_PATH := "user://savegame.res"
const CURRENT_VERSION := 2
@export var progression_version := 0

@export var rng_seed: int
@export var rng_state: int
@export var run_stats: RunStats
@export var player_stats: PlayerStats
@export var current_deck: CardPile
@export var current_health: int
@export var relics: Array[Relic]
@export var map_data: Array[Array]
@export var last_map_node: MapNode
@export var floors_climbed: int
@export var was_on_map: bool
@export var elapsed_run_time: float


func save_data() -> bool:
	progression_version = CURRENT_VERSION
	# Same-directory replacement avoids exposing a partially serialized save.
	# Keep the old file if writing or replacement fails. No remove-before-rename.
	const TEMP_PATH := "user://savegame.pending.res"
	var err := ResourceSaver.save(self, TEMP_PATH)
	if err == OK:
		err = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if err != OK:
		Utils.show_save_error("Progress could not be saved (%s). Your previous save is retained. Check free disk space and folder permissions, then try again before leaving the game." % error_string(err))
		return false
	return true


static func load_data() -> SaveGame:
	if FileAccess.file_exists(SAVE_PATH):
		# Reload the save and all embedded subresources. External authored assets
		# (including scripts) retain their normal cache; deep duplication below
		# isolates any external mutable resources in older saves.
		var data := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
		if not data:
			Utils.show_save_error("Your saved run could not be read. The save has been kept so it can be recovered.")
		if data and data.progression_version > CURRENT_VERSION:
			Utils.show_save_error("This run was saved by a newer game version. The save has been retained.")
			return null
		if data and (data.run_stats == null or data.player_stats == null or data.run_stats.act_index < 0 or data.run_stats.act_index >= 3 or data.map_data.size() < 15 or data.map_data.size() > 17 or data.floors_climbed < 0 or data.floors_climbed > data.map_data.size() or (data.floors_climbed > 0 and data.last_map_node == null)):
			Utils.show_save_error("This run has invalid progression data. The save has been retained.")
			return null
		# Run restores this pile directly; combat duplicates every card in it.
		# An empty pile is valid, but missing resources cannot be resumed safely.
		if data and (data.current_deck == null or data.current_deck.cards.has(null)):
			Utils.show_save_error("This run has missing deck or card data. The save has been retained so it can be recovered.")
			return null
		if data and not data._has_valid_map_graph():
			Utils.show_save_error("This run has invalid map data. The save has been retained so it can be recovered.")
			return null
		# Version 0/1 maps continue as Act I, retaining the selected encounters.
		# Their first new act uses the authored Act II pool, never a regenerated map.
		if data and data.run_stats and data.progression_version < CURRENT_VERSION:
			data.run_stats.act_index = 0
			data.run_stats.completed_floors = 0
		if data:
			var restored := data.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SaveGame
			restored._restore_missing_obelisk_compositions()
			return restored
		return null

	return null


func _has_valid_map_graph() -> bool:
	# Map renders every stored node and follows resource references directly.
	# Validate the grid before any route or camera code can consume it.
	for row: int in map_data.size():
		if map_data[row].size() != MapGenerator.MAP_WIDTH:
			return false
		for column: int in map_data[row].size():
			var node := map_data[row][column] as MapNode
			if node == null or node.row != row or node.column != column:
				return false
	for floor_nodes: Array in map_data:
		for node: MapNode in floor_nodes:
			# Only connected rooms and the final center boss are rendered/selectable.
			# Unused grid cells intentionally have no encounter resource.
			var is_room := not node.next_nodes.is_empty() or (node.row == map_data.size() - 1 and node.column == floori(MapGenerator.MAP_WIDTH * 0.5))
			if is_room and node.type in [Enums.MapNodeType.MONSTER, Enums.MapNodeType.ELITE, Enums.MapNodeType.BOSS] and node.battle_stats == null:
				return false
			for edge: Resource in node.next_nodes:
				var destination := edge as MapNode
				if destination == null or destination.row != node.row + 1 or destination.row >= map_data.size():
					return false
				if not map_data[destination.row].has(destination):
					return false
	if last_map_node:
		if floors_climbed == 0 or last_map_node.row != floors_climbed - 1:
			return false
		if not map_data[floors_climbed - 1].has(last_map_node):
			return false
	return true


func _restore_missing_obelisk_compositions() -> void:
	# Older checkpoints embed incomplete scenes. Restore only the composition of
	# known non-boss rooms; keep the saved map, rewards and other encounter fields.
	var registry := RegistryData.encounter_registry
	if not registry:
		return
	var replacements: Dictionary[PackedScene, PackedScene] = {}
	for floor_nodes: Array in map_data:
		for node: MapNode in floor_nodes:
			var definition := node.battle_stats
			if not definition or definition.category not in [EncounterDefinition.Category.NORMAL, EncounterDefinition.Category.ELITE] or not definition.enemies:
				continue
			var authored := registry.find(definition.encounter_id)
			if not authored or authored.category != definition.category or not authored.enemies:
				continue
			if not replacements.has(definition.enemies):
				var replacement := definition.enemies
				if not _scene_has_obelisk(replacement) and _scene_has_obelisk(authored.enemies):
					replacement = authored.enemies
				replacements[definition.enemies] = replacement
			definition.enemies = replacements[definition.enemies]


static func _scene_has_obelisk(scene: PackedScene) -> bool:
	var composition := scene.instantiate()
	var found := false
	for enemy: Node in composition.get_children():
		if enemy is Obelisk:
			found = true
			break
	composition.free()
	return found


static func delete_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
