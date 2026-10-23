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
		# Version 0/1 maps continue as Act I, retaining the selected encounters.
		# Their first new act uses the authored Act II pool, never a regenerated map.
		if data and data.run_stats and data.progression_version < CURRENT_VERSION:
			data.run_stats.act_index = 0
			data.run_stats.completed_floors = 0
		return data.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SaveGame if data else null

	return null


static func delete_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
