extends Control
class_name DevSandboxPanel

@export var tilemap: ProcGenTilemap
@export var enemy_handler: EnemyHandler
@export var player_handler: PlayerHandler
@export var player_hand: PlayerHand
@export var player: Player
@export var battle_stats: BattleStats
@export var map_camera: MapCamera
@export var phantom_host: Node
@export var card_registry: CardRegistry
@export var encounter_registry: EncounterRegistry
@export var enemy_catalog: EnemyCatalog
var registry_data: RegistryData

var regen_map_button: Button
var enemy_dropdown: OptionButton
var enemy_tier_filter_dropdown: OptionButton
var spawn_enemy_button: Button
var clear_enemies_button: Button
var card_dropdown: OptionButton
var card_rarity_filter_dropdown: OptionButton
var add_hand_button: Button
var add_draw_button: Button
var add_discard_button: Button
var draw_card_button: Button
var center_camera_button: Button
var zoom_in_button: Button
var zoom_out_button: Button
var free_camera_toggle: CheckButton
var clear_fog_button: Button
var refill_energy_button: Button
var refill_health_button: Button
var pass_turn_button: Button

var card_paths: Array[String] = []
var enemy_paths: Array[String] = []
var card_entries: Array[Dictionary] = []
var enemy_entries: Array[Dictionary] = []
var default_enemy_scene_path := "res://scenes/enemy/moving_enemy.tscn"
var obelisk_enemy_scene_path := "res://scenes/enemy/obelisk/obelisk_enemy.tscn"


func _ready() -> void:
	_bind_nodes()
	if regen_map_button:
		regen_map_button.pressed.connect(_on_regen_map_pressed)
	if spawn_enemy_button:
		spawn_enemy_button.pressed.connect(_on_spawn_enemy_pressed)
	if clear_enemies_button:
		clear_enemies_button.pressed.connect(_on_clear_enemies_pressed)
	if enemy_tier_filter_dropdown:
		enemy_tier_filter_dropdown.item_selected.connect(_on_enemy_filter_changed)
	if add_hand_button:
		add_hand_button.pressed.connect(_on_add_to_hand_pressed)
	if add_draw_button:
		add_draw_button.pressed.connect(_on_add_to_draw_pressed)
	if add_discard_button:
		add_discard_button.pressed.connect(_on_add_to_discard_pressed)
	if draw_card_button:
		draw_card_button.pressed.connect(_on_draw_card_pressed)
	if card_rarity_filter_dropdown:
		card_rarity_filter_dropdown.item_selected.connect(_on_card_filter_changed)
	if center_camera_button:
		center_camera_button.pressed.connect(_on_center_camera_pressed)
	if zoom_in_button:
		zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	if zoom_out_button:
		zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	if free_camera_toggle:
		free_camera_toggle.toggled.connect(_on_free_camera_toggled)
	if clear_fog_button:
		clear_fog_button.pressed.connect(_on_clear_fog_pressed)
	if refill_energy_button:
		refill_energy_button.pressed.connect(_on_refill_energy_pressed)
	if refill_health_button:
		refill_health_button.pressed.connect(_on_refill_health_pressed)
	if pass_turn_button:
		pass_turn_button.pressed.connect(_on_pass_turn_pressed)
	_build_databases()


func _bind_nodes() -> void:
	regen_map_button = get_node_or_null("%RegenMapButton")
	enemy_dropdown = get_node_or_null("%EnemyDropdown")
	enemy_tier_filter_dropdown = get_node_or_null("%EnemyTierFilter")
	spawn_enemy_button = get_node_or_null("%SpawnEnemyButton")
	clear_enemies_button = get_node_or_null("%ClearEnemiesButton")
	card_dropdown = get_node_or_null("%CardDropdown")
	card_rarity_filter_dropdown = get_node_or_null("%CardRarityFilter")
	add_hand_button = get_node_or_null("%AddHandButton")
	add_draw_button = get_node_or_null("%AddDrawButton")
	add_discard_button = get_node_or_null("%AddDiscardButton")
	draw_card_button = get_node_or_null("%DrawCardButton")
	center_camera_button = get_node_or_null("%CenterCameraButton")
	zoom_in_button = get_node_or_null("%ZoomInButton")
	zoom_out_button = get_node_or_null("%ZoomOutButton")
	free_camera_toggle = get_node_or_null("%FreeCameraToggle")
	clear_fog_button = get_node_or_null("%ClearFogButton")
	refill_energy_button = get_node_or_null("%RefillEnergyButton")
	refill_health_button = get_node_or_null("%RefillHealthButton")
	pass_turn_button = get_node_or_null("%PassTurnButton")


func _on_regen_map_pressed() -> void:
	if not tilemap or not battle_stats:
		return
	tilemap.generate_tilemap(battle_stats)


func _on_spawn_enemy_pressed() -> void:
	if not enemy_handler or not tilemap:
		return
	var scene_path := _get_selected_enemy_path()
	if scene_path.is_empty():
		return
	var selected_stats := _get_selected_enemy_stats()
	if not selected_stats:
		print("Sandbox: no EnemyStats found for selection; aborting spawn")
		return
	var packed_scene := load(scene_path)
	if packed_scene is PackedScene:
		var enemy := packed_scene.instantiate() as Enemy
		if not enemy:
			# attempt to find an Enemy child
			var inst = packed_scene.instantiate()
			for child in inst.get_children():
				enemy = child as Enemy
				if enemy:
					break
			if not enemy:
				print("Sandbox: selected enemy scene did not produce Enemy: ", scene_path)
				return
		enemy.stats = selected_stats
		enemy.name = selected_stats.enemy_name
		if not enemy:
			return
		var spawn_tile := tilemap.get_random_valid_tile([])
		if not tilemap.is_tile_valid(spawn_tile):
			print("Sandbox: no valid spawn tile for enemy")
			return
		enemy_handler.add_enemy(enemy, spawn_tile)


func _on_clear_enemies_pressed() -> void:
	if not enemy_handler:
		return
	for enemy: Enemy in enemy_handler.get_children():
		enemy.queue_free()
	enemy_handler.acting_enemies.clear()


func _on_enemy_filter_changed(_idx: int) -> void:
	_populate_enemy_dropdown()


func _on_card_filter_changed(_idx: int) -> void:
	_populate_card_dropdown()


func _on_add_to_hand_pressed() -> void:
	var card := _load_card()
	if not card or not player_hand:
		return
	player_hand.add_card(card)


func _on_add_to_draw_pressed() -> void:
	_add_card_to_pile("draw")


func _on_add_to_discard_pressed() -> void:
	_add_card_to_pile("discard")


func _on_draw_card_pressed() -> void:
	if player_handler:
		player_handler.draw_card()

func _on_center_camera_pressed() -> void:
	if not map_camera:
		return
	if player:
		map_camera.position = player.global_position
	elif tilemap and tilemap.base_layer:
		map_camera.position = tilemap.base_layer.map_to_local(tilemap.get_center_tile_coord())
	map_camera.clamp_position_to_limits()


func _on_zoom_in_pressed() -> void:
	_adjust_zoom(-0.1)


func _on_zoom_out_pressed() -> void:
	_adjust_zoom(0.1)


func _adjust_zoom(delta: float) -> void:
	if not map_camera:
		return
	var zoom_value := map_camera.zoom.x + delta
	var min_zoom := map_camera.min_zoom
	var max_zoom := map_camera.max_zoom
	zoom_value = clampf(zoom_value, max_zoom, min_zoom)
	map_camera.zoom = Vector2(zoom_value, zoom_value)
	map_camera.clamp_position_to_limits()


func _on_free_camera_toggled(enabled: bool) -> void:
	if phantom_host:
		phantom_host.process_mode = Node.PROCESS_MODE_DISABLED if enabled else Node.PROCESS_MODE_INHERIT
	if map_camera:
		map_camera.make_current()


func _on_clear_fog_pressed() -> void:
	if tilemap:
		tilemap.hide_fog()


func _on_refill_energy_pressed() -> void:
	if player and player.stats:
		player.stats.energy = player.stats.max_energy
		player.stats.stats_changed.emit()


func _on_refill_health_pressed() -> void:
	if player and player.stats:
		player.stats.health = player.stats.max_health
		player.stats.stats_changed.emit()


func _on_pass_turn_pressed() -> void:
	if player_handler and enemy_handler:
		player_handler.end_turn()
		enemy_handler.start_turn()


func _build_databases() -> void:
	registry_data = _get_registry_data()
	if registry_data:
		if not card_registry:
			card_registry = registry_data.card_registry
		if not encounter_registry:
			encounter_registry = registry_data.encounter_registry
		if not enemy_catalog:
			enemy_catalog = registry_data.enemy_catalog

	card_entries = []
	if registry_data:
		card_entries += registry_data.get_card_entries()
	card_entries += _gather_card_entries()
	card_entries += _gather_card_entries_from_paths()
	enemy_entries = _gather_enemy_entries_from_catalog()
	print("Sandbox: gathered card entries = ", card_entries.size())
	print("Sandbox: gathered enemy entries = ", enemy_entries.size())
	_populate_card_filters()
	_populate_enemy_filters()
	_populate_card_dropdown()
	_populate_enemy_dropdown()


func _gather_card_entries() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	if card_registry and not card_registry.entries.is_empty():
		for entry: Dictionary in card_registry.entries:
			if entry.get("unlocked", true) == false:
				continue
			var card: Card = entry.get("card", null)
			if not card:
				continue
			var label := card.name if card.name else card.resource_path.get_file().get_basename()
			results.append({
				"card": card,
				"path": card.resource_path,
				"label": label,
				"rarity": entry.get("rarity", card.card_rarity)
			})
	else:
		card_paths = _gather_resources("res://resources/data/cards", ["tres"])
		for path: String in card_paths:
			results.append({
				"card": null,
				"path": path,
				"label": path.get_file().get_basename(),
				"rarity": null
			})
	return results


func _gather_card_entries_from_paths() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	card_paths = _gather_resources("res://resources/data/cards", ["tres"])
	for path: String in card_paths:
		var label := path.get_file().get_basename()
		var rarity: Variant = null
		var loaded_card := load(path)
		if loaded_card is Card:
			var card_res := loaded_card as Card
			if card_res.name:
				label = card_res.name
			rarity = card_res.card_rarity
		results.append({
			"card": loaded_card if loaded_card is Card else null,
			"path": path,
			"label": label,
			"rarity": rarity
		})
	return results


func _gather_enemy_entries() -> Array[Dictionary]:
	return _gather_enemy_entries_from_paths()


func _gather_enemy_entries_from_paths() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var root: String = "res://scenes/enemy"
	var exclude_files := ["enemy.tscn", "moving_enemy.tscn", "enemy_action_picker.tscn"]
	var file_paths := _gather_resources(root, ["tscn"])
	print("Sandbox: enemy scan file paths count = ", file_paths.size())

	for path: String in file_paths:
		var file_name_local := path.get_file()
		if exclude_files.has(file_name_local):
			continue
		var base := file_name_local.get_basename()
		if not (base.ends_with("_enemy") or base.ends_with("_enemy_ai")):
			continue
		var label: String = path.replace(root + "/", "")
		results.append({
			"path": path,
			"label": label,
			"tier": -1,
			"stats_path": "",
			"tags": []
		})
	print("Sandbox: enemy entries built = ", results.size())
	return results


func _gather_enemy_entries_from_catalog() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if enemy_catalog:
		for entry: Dictionary in enemy_catalog.entries:
			var scene: PackedScene = entry.get("scene", null)
			var stats: EnemyStats = entry.get("stats", null)
			if not scene or not stats:
				continue
			results.append({
				"path": scene.resource_path,
				"stats_path": stats.resource_path,
				"label": entry.get("label", stats.enemy_name if stats else "Enemy"),
				"tier": _derive_tier_from_tags(entry.get("tags", [])),
				"tags": entry.get("tags", [])
			})
	if results.is_empty():
		results = _gather_enemy_entries_from_stats()
	if results.is_empty():
		results = _gather_enemy_entries_from_paths()
	return results


func _gather_enemy_entries_from_stats() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var stat_paths := _gather_resources("res://scenes/enemy", ["tres"])
	for stats_path: String in stat_paths:
		var res := load(stats_path)
		if not (res is EnemyStats):
			continue
		var stats := res as EnemyStats
		var scene_path := default_enemy_scene_path
		if stats_path.find("/obelisk/") != -1:
			scene_path = obelisk_enemy_scene_path
		var label := stats.enemy_name if stats.enemy_name else stats_path.get_file().get_basename()
		results.append({
			"path": scene_path,
			"stats_path": stats_path,
			"label": label,
			"tier": _derive_tier_from_tags([]),
			"tags": []
		})
	print("Sandbox: enemy entries from stats = ", results.size())
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
		else:
			if extensions.has(res_name.get_extension()):
				results.append(full_path)
		res_name = dir.get_next()
	dir.list_dir_end()
	results.sort()
	return results


func _derive_tier_from_tags(tags: Array) -> int:
	for tag in tags:
		if not (tag is String):
			continue
		var tag_str := (tag as String).to_lower()
		if not tag_str.begins_with("tier"):
			continue
		var digits := ""
		for c in tag_str:
			var char_str := str(c)
			if char_str.is_valid_int():
				digits += char_str
		if not digits.is_empty():
			return int(digits)
	return -1


func _derive_entry_tier(entry: Dictionary) -> int:
	if entry.has("tier"):
		var tier_val: Variant = entry.get("tier")
		if tier_val is int and tier_val >= 0:
			return tier_val
	return _derive_tier_from_tags(entry.get("tags", []))


func _populate_enemy_filters() -> void:
	if not enemy_tier_filter_dropdown:
		return
	enemy_tier_filter_dropdown.clear()
	enemy_tier_filter_dropdown.add_item("All Tiers", -1)
	var tiers: Array = []
	for entry: Dictionary in enemy_entries:
		var tier_value := _derive_entry_tier(entry)
		if tier_value < 0:
			continue
		if not tiers.has(tier_value):
			tiers.append(tier_value)
	for tier_value in tiers:
		enemy_tier_filter_dropdown.add_item("Tier %s" % tier_value, tier_value)
	enemy_tier_filter_dropdown.select(0)


func _populate_card_filters() -> void:
	if not card_rarity_filter_dropdown:
		return
	card_rarity_filter_dropdown.clear()
	card_rarity_filter_dropdown.add_item("All Rarities", -1)
	card_rarity_filter_dropdown.add_item("Common", Enums.CardRarity.COMMON)
	card_rarity_filter_dropdown.add_item("Uncommon", Enums.CardRarity.UNCOMMON)
	card_rarity_filter_dropdown.add_item("Rare", Enums.CardRarity.RARE)
	card_rarity_filter_dropdown.select(0)


func _populate_enemy_dropdown() -> void:
	if not enemy_dropdown:
		return
	enemy_dropdown.clear()
	enemy_dropdown.disabled = false
	print("Sandbox: populating enemy dropdown with ", enemy_entries.size(), " entries")
	var selected_tier := -1
	if enemy_tier_filter_dropdown:
		selected_tier = enemy_tier_filter_dropdown.get_selected_id()
	var idx := 0
	for entry: Dictionary in enemy_entries:
		var tier_value := _derive_entry_tier(entry)
		if selected_tier != -1 and tier_value != selected_tier:
			continue
		var label: String = entry.get("label", "Enemy")
		enemy_dropdown.add_item(label, idx)
		var meta: Dictionary = {
			"scene_path": entry.get("path", ""),
			"stats_path": entry.get("stats_path", ""),
			"label": label,
			"tier": tier_value,
			"tags": entry.get("tags", [])
		}
		enemy_dropdown.set_item_metadata(idx, meta)
		print("Sandbox: add enemy option ", label, " -> ", meta.get("scene_path", ""))
		idx += 1
	if enemy_dropdown.item_count > 0:
		enemy_dropdown.select(0)
	else:
		enemy_dropdown.add_item("No enemies found", 0)
		enemy_dropdown.disabled = true


func _populate_card_dropdown() -> void:
	if not card_dropdown:
		return
	card_dropdown.clear()
	card_dropdown.disabled = false
	var selected_rarity := -1
	if card_rarity_filter_dropdown:
		selected_rarity = card_rarity_filter_dropdown.get_selected_id()
	var idx := 0
	for entry: Dictionary in card_entries:
		var rarity_value = entry.get("rarity", -1)
		if rarity_value == null:
			rarity_value = -1
		elif rarity_value is Enums.CardRarity:
			rarity_value = int(rarity_value)
		elif rarity_value is int:
			rarity_value = rarity_value
		else:
			rarity_value = int(rarity_value)
		if selected_rarity != -1 and rarity_value != selected_rarity:
			continue
		card_dropdown.add_item(entry.get("label", "Card"), idx)
		var meta: Variant = entry.get("card", null)
		if not meta:
			meta = entry.get("path", "")
		card_dropdown.set_item_metadata(idx, meta)
		idx += 1
	if card_dropdown.item_count > 0:
		card_dropdown.select(0)
	else:
		card_dropdown.add_item("No cards found", 0)
		card_dropdown.disabled = true


func _get_selected_enemy_path() -> String:
	if enemy_dropdown and enemy_dropdown.item_count > 0:
		var idx: int = enemy_dropdown.get_selected_id()
		if idx < 0:
			return ""
		var meta: Variant = enemy_dropdown.get_item_metadata(idx)
		if meta is Dictionary:
			return (meta as Dictionary).get("scene_path", "")
		if meta is String:
			return meta
	return ""


func _get_selected_enemy_stats() -> EnemyStats:
	if enemy_dropdown and enemy_dropdown.item_count > 0:
		var idx: int = enemy_dropdown.get_selected_id()
		if idx < 0:
			return null
		var meta_stats: Variant = null
		var meta: Variant = enemy_dropdown.get_item_metadata(idx)
		if meta is Dictionary:
			meta_stats = (meta as Dictionary).get("stats_path", null)
		if meta_stats is String and not (meta_stats as String).is_empty():
			var res := load(meta_stats)
			if res is EnemyStats:
				return res as EnemyStats
	return null


func _get_selected_card_path() -> String:
	if card_dropdown and card_dropdown.item_count > 0:
		var idx: int = card_dropdown.get_selected_id()
		var meta: Variant = card_dropdown.get_item_metadata(idx)
		if meta is String:
			return meta
		if meta is Card:
			var card_meta := meta as Card
			if card_meta and not card_meta.resource_path.is_empty():
				return card_meta.resource_path
	return ""


func _add_card_to_pile(which: String) -> void:
	var card := _load_card()
	if not card or not player_handler or not player_handler.player_stats:
		return
	match which:
		"draw":
			player_handler.player_stats.draw_pile.add_card(card)
		"discard":
			player_handler.player_stats.discard.add_card(card)


func _load_card() -> Card:
	var path := _get_selected_card_path()
	var meta: Variant = null
	if card_dropdown and card_dropdown.item_count > 0:
		meta = card_dropdown.get_item_metadata(card_dropdown.get_selected_id())
	if meta is Card:
		return (meta as Card).duplicate()

	if path.is_empty():
		return null
	var res := load(path)
	if res is Card:
		return (res as Card).duplicate()
	if res is Resource:
		var card_res := res as Card
		if card_res:
			return card_res.duplicate()
	return null


func _get_registry_data() -> RegistryData:
	return get_tree().get_root().get_node_or_null("RegistryData") as RegistryData
