extends Control
class_name DataEditor

const MAIN_MENU_PATH := "res://scenes/menus/main_menu.tscn"
const CARD_DIR := "res://resources/data/cards"
const CARD_REGISTRY_DIR := "res://resources/data/registries"
const CARD_PILES_DIR := "res://resources/data/card_piles"
const BATTLE_STATS_DIR := "res://resources/data/battles"

enum PickTarget {
	NONE,
	REGISTRY_CARD,
	ENCOUNTER_STATS,
	DECK_CARD,
	CARD_ART,
	CARD_SOUND,
	CARD_VISUAL,
	CARD_PROJECTILE
}

@onready var back_button: Button = %BackButton
@onready var status_label: Label = %StatusLabel
@onready var dirty_label: Label = %DirtyLabel
@onready var reload_button: Button = %ReloadButton
@onready var tabs: TabContainer = %Tabs
@onready var resource_picker: FileDialog = %ResourcePicker
@onready var save_dialog: FileDialog = %SaveDialog

# Cards
@onready var card_preview: CardUI = %CardPreview
@onready var card_list: ItemList = %CardList
@onready var card_search: LineEdit = %CardSearch
@onready var card_rarity_filter: OptionButton = %CardRarityFilter
@onready var card_id: LineEdit = %CardId
@onready var card_name: LineEdit = %CardName
@onready var card_type: OptionButton = %CardType
@onready var card_target: OptionButton = %CardTarget
@onready var card_rarity: OptionButton = %CardRarity
@onready var card_energy: SpinBox = %CardEnergy
@onready var card_exhaust: CheckButton = %CardExhaust
@onready var card_tags: LineEdit = %CardTags
@onready var card_description: TextEdit = %CardDescription
@onready var card_path: LineEdit = %CardPath
@onready var card_art_path: LineEdit = %CardArtPath
@onready var card_sound_path: LineEdit = %CardSoundPath
@onready var card_visual_path: LineEdit = %CardVisualPath
@onready var card_projectile_path: LineEdit = %CardProjectilePath
@onready var card_save_button: Button = %CardSaveButton
@onready var card_save_as_button: Button = %CardSaveAsButton
@onready var card_new_button: Button = %CardNewButton
@onready var card_refresh_button: Button = %CardRefreshButton
@onready var card_reload_button: Button = %CardRevertButton
@onready var browse_card_art: Button = %BrowseCardArt
@onready var browse_card_sound: Button = %BrowseCardSound
@onready var browse_card_visual: Button = %BrowseCardVisual
@onready var browse_card_projectile: Button = %BrowseCardProjectile

# Card registries
@onready var card_registry_list: ItemList = %CardRegistryList
@onready var card_registry_refresh: Button = %CardRegistryRefreshButton
@onready var card_registry_path: LineEdit = %CardRegistryPath
@onready var card_registry_entry_list: ItemList = %CardRegistryEntryList
@onready var card_registry_add_entry: Button = %CardRegistryAddEntry
@onready var card_registry_remove_entry: Button = %CardRegistryRemoveEntry
@onready var card_registry_apply_entry: Button = %CardRegistryApplyEntry
@onready var card_registry_save: Button = %CardRegistrySave
@onready var registry_card_path: LineEdit = %RegistryCardPath
@onready var registry_pick_card: Button = %RegistryPickCard
@onready var registry_class_id: LineEdit = %RegistryClassId
@onready var registry_weight: SpinBox = %RegistryWeight
@onready var registry_rarity: OptionButton = %RegistryRarity
@onready var registry_tags: LineEdit = %RegistryTags
@onready var registry_unlocked: CheckButton = %RegistryUnlocked
@onready var registry_allow_draft: CheckButton = %RegistryAllowDraft

# Encounter registries
@onready var encounter_registry_list: ItemList = %EncounterRegistryList
@onready var encounter_registry_refresh: Button = %EncounterRegistryRefreshButton
@onready var encounter_registry_path: LineEdit = %EncounterRegistryPath
@onready var encounter_registry_entry_list: ItemList = %EncounterRegistryEntryList
@onready var encounter_registry_add_entry: Button = %EncounterRegistryAddEntry
@onready var encounter_registry_remove_entry: Button = %EncounterRegistryRemoveEntry
@onready var encounter_registry_apply_entry: Button = %EncounterRegistryApplyEntry
@onready var encounter_registry_save: Button = %EncounterRegistrySave
@onready var encounter_stats_path: LineEdit = %EncounterStatsPath
@onready var encounter_pick_stats: Button = %EncounterPickStats
@onready var encounter_tier: SpinBox = %EncounterTier
@onready var encounter_weight: SpinBox = %EncounterWeight
@onready var encounter_tags: LineEdit = %EncounterTags
@onready var encounter_elite: CheckButton = %EncounterElite
@onready var encounter_boss: CheckButton = %EncounterBoss
@onready var encounter_unlocked: CheckButton = %EncounterUnlocked

# Decks
@onready var deck_list: ItemList = %DeckList
@onready var deck_refresh_button: Button = %DeckRefreshButton
@onready var deck_path: LineEdit = %DeckPath
@onready var deck_cards: ItemList = %DeckCards
@onready var deck_add_card: Button = %DeckAddCard
@onready var deck_remove_card: Button = %DeckRemoveCard
@onready var deck_move_up: Button = %DeckMoveUp
@onready var deck_move_down: Button = %DeckMoveDown
@onready var deck_save: Button = %DeckSave

var card_records: Array[Dictionary] = []
var current_card: Card
var current_card_path: String = ""

var card_registry_records: Array[Dictionary] = []
var current_card_registry: CardRegistry
var current_card_registry_path: String = ""
var current_card_registry_entries: Array[Dictionary] = []
var current_card_registry_index: int = -1

var encounter_registry_records: Array[Dictionary] = []
var current_encounter_registry: EncounterRegistry
var current_encounter_registry_path: String = ""
var current_encounter_entries: Array[EncounterDefinition] = []
var current_encounter_index: int = -1

var deck_records: Array[Dictionary] = []
var current_deck: CardPile
var current_deck_path: String = ""

var pick_target: PickTarget = PickTarget.NONE
var save_target: String = ""
var is_dirty: bool = false
var block_dirty: bool = false


func _ready() -> void:
	_wire_signals()
	_wire_dirty_signals()
	_populate_enum_options(card_type, Enums.CardType)
	_populate_enum_options(card_target, Enums.TargetType)
	_populate_enum_options(card_rarity, Enums.CardRarity)
	_populate_enum_options(registry_rarity, Enums.CardRarity, true)
	_populate_card_filters()
	_set_status("Ready")
	_clear_dirty()
	_refresh_all_lists()


func _wire_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	reload_button.pressed.connect(_refresh_all_lists)
	card_search.text_changed.connect(func(_t): _rebuild_card_list())
	card_rarity_filter.item_selected.connect(func(_i): _rebuild_card_list())
	card_list.item_selected.connect(_on_card_selected)
	card_save_button.pressed.connect(_on_card_save_pressed)
	card_save_as_button.pressed.connect(_on_card_save_as_pressed)
	card_new_button.pressed.connect(_on_card_new_pressed)
	card_refresh_button.pressed.connect(_refresh_cards)
	card_reload_button.pressed.connect(_reload_current_card)
	browse_card_art.pressed.connect(func(): _open_picker(PickTarget.CARD_ART, "res://assets", ["*.png", "*.webp", "*.jpg", "*.jpeg"]))
	browse_card_sound.pressed.connect(func(): _open_picker(PickTarget.CARD_SOUND, "res://assets", ["*.wav", "*.ogg"]))
	browse_card_visual.pressed.connect(func(): _open_picker(PickTarget.CARD_VISUAL, "res://", ["*.tscn", "*.tres"]))
	browse_card_projectile.pressed.connect(func(): _open_picker(PickTarget.CARD_PROJECTILE, "res://", ["*.tscn", "*.tres"]))

	card_registry_list.item_selected.connect(_on_card_registry_selected)
	card_registry_refresh.pressed.connect(_refresh_card_registries)
	card_registry_entry_list.item_selected.connect(_on_card_registry_entry_selected)
	card_registry_add_entry.pressed.connect(_add_card_registry_entry)
	card_registry_remove_entry.pressed.connect(_remove_card_registry_entry)
	card_registry_apply_entry.pressed.connect(_apply_card_registry_entry_form)
	card_registry_save.pressed.connect(_save_card_registry)
	registry_pick_card.pressed.connect(func(): _open_picker(PickTarget.REGISTRY_CARD, CARD_DIR, ["*.tres"]))

	encounter_registry_list.item_selected.connect(_on_encounter_registry_selected)
	encounter_registry_refresh.pressed.connect(_refresh_encounter_registries)
	encounter_registry_entry_list.item_selected.connect(_on_encounter_entry_selected)
	encounter_registry_add_entry.pressed.connect(_add_encounter_entry)
	encounter_registry_remove_entry.pressed.connect(_remove_encounter_entry)
	encounter_registry_apply_entry.pressed.connect(_apply_encounter_entry_form)
	encounter_registry_save.pressed.connect(_save_encounter_registry)
	encounter_pick_stats.pressed.connect(func(): _open_picker(PickTarget.ENCOUNTER_STATS, BATTLE_STATS_DIR, ["*.tres"]))

	deck_list.item_selected.connect(_on_deck_selected)
	deck_refresh_button.pressed.connect(_refresh_decks)
	deck_add_card.pressed.connect(func(): _open_picker(PickTarget.DECK_CARD, CARD_DIR, ["*.tres"]))
	deck_remove_card.pressed.connect(_remove_deck_card)
	deck_move_up.pressed.connect(func(): _move_deck_card(-1))
	deck_move_down.pressed.connect(func(): _move_deck_card(1))
	deck_save.pressed.connect(_save_deck)

	resource_picker.file_selected.connect(_on_resource_picker_file_selected)
	save_dialog.file_selected.connect(_on_save_dialog_file_selected)


func _wire_dirty_signals() -> void:
	var card_text_fields: Array[LineEdit] = [card_id, card_name, card_tags, card_art_path, card_sound_path, card_visual_path, card_projectile_path]
	for field in card_text_fields:
		field.text_changed.connect(_on_card_form_changed)
	card_description.text_changed.connect(_on_card_form_changed)
	card_type.item_selected.connect(_on_card_form_changed)
	card_target.item_selected.connect(_on_card_form_changed)
	card_rarity.item_selected.connect(_on_card_form_changed)
	card_energy.value_changed.connect(_on_card_form_changed)
	card_exhaust.toggled.connect(_on_card_form_changed)

	var registry_text_fields: Array[LineEdit] = [registry_card_path, registry_class_id, registry_tags]
	for field in registry_text_fields:
		field.text_changed.connect(_on_registry_form_changed)
	registry_weight.value_changed.connect(_on_registry_form_changed)
	registry_rarity.item_selected.connect(_on_registry_form_changed)
	registry_unlocked.toggled.connect(_on_registry_form_changed)
	registry_allow_draft.toggled.connect(_on_registry_form_changed)

	var encounter_text_fields: Array[LineEdit] = [encounter_stats_path, encounter_tags]
	for field in encounter_text_fields:
		field.text_changed.connect(_on_encounter_form_changed)
	encounter_tier.value_changed.connect(_on_encounter_form_changed)
	encounter_weight.value_changed.connect(_on_encounter_form_changed)
	encounter_elite.toggled.connect(_on_encounter_form_changed)
	encounter_boss.toggled.connect(_on_encounter_form_changed)
	encounter_unlocked.toggled.connect(_on_encounter_form_changed)

func _refresh_all_lists() -> void:
	_refresh_cards()
	_refresh_card_registries()
	_refresh_encounter_registries()
	_refresh_decks()


# --- Cards -------------------------------------------------------------------

func _populate_card_filters() -> void:
	card_rarity_filter.clear()
	card_rarity_filter.add_item("All Rarities", -1)
	for rarity_name in Enums.CardRarity.keys():
		card_rarity_filter.add_item(rarity_name.capitalize(), Enums.CardRarity[rarity_name])
	card_rarity_filter.select(0)


func _refresh_cards() -> void:
	card_records.clear()
	var paths: Array[String] = _gather_resources(CARD_DIR, ["tres"])
	for path in paths:
		var res: Resource = load(path)
		if res is Card:
			var card: Card = res as Card
			card_records.append({
				"path": path,
				"name": card.name if card.name else path.get_file().get_basename(),
				"rarity": card.card_rarity,
				"type": card.card_type
			})
	_rebuild_card_list()


func _rebuild_card_list() -> void:
	card_list.clear()
	var query: String = card_search.text.strip_edges().to_lower()
	var rarity_filter: int = card_rarity_filter.get_selected_id()
	for i in card_records.size():
		var rec: Dictionary = card_records[i]
		var text: String = rec.get("name", "Card")
		var rarity_val: int = rec.get("rarity", -1)
		if rarity_filter != -1 and rarity_val != rarity_filter:
			continue
		if not query.is_empty() and text.to_lower().find(query) == -1:
			continue
		card_list.add_item(text)
		card_list.set_item_metadata(card_list.item_count - 1, rec.get("path", ""))
	if card_list.item_count > 0:
		card_list.select(0)
		_on_card_selected(0)


func _on_card_selected(idx: int) -> void:
	if idx < 0:
		return
	var path: String = card_list.get_item_metadata(idx)
	_load_card(path)


func _load_card(path: String) -> void:
	var res: Resource = load(path)
	if not (res is Card):
		_set_status("Selected file is not a Card resource.", true)
		return
	current_card_path = path
	current_card = (res as Card).duplicate(true)
	_populate_card_form(current_card)
	_clear_dirty()
	_set_status("Loaded card %s" % current_card.name)


func _populate_card_form(card: Card) -> void:
	block_dirty = true
	card_path.text = current_card_path
	card_id.text = card.id
	card_name.text = card.name
	_select_option_value(card_type, int(card.card_type))
	_select_option_value(card_target, int(card.target_type))
	_select_option_value(card_rarity, int(card.card_rarity))
	card_energy.value = card.energy_cost
	card_exhaust.button_pressed = card.exhaust
	card_tags.text = ",".join(card.tags)
	card_description.text = card.description
	card_art_path.text = card.card_art.resource_path if card.card_art else ""
	card_sound_path.text = card.sound_fx.resource_path if card.sound_fx else ""
	card_visual_path.text = card.visual_fx.resource_path if card.visual_fx else ""
	card_projectile_path.text = card.projectile_fx.resource_path if card.projectile_fx else ""
	block_dirty = false
	_update_card_preview()


func _apply_card_form() -> void:
	if not current_card:
		return
	current_card.id = card_id.text.strip_edges()
	current_card.name = card_name.text.strip_edges()
	current_card.card_type = _get_option_value(card_type, current_card.card_type)
	current_card.target_type = _get_option_value(card_target, current_card.target_type)
	current_card.card_rarity = _get_option_value(card_rarity, current_card.card_rarity)
	current_card.energy_cost = int(card_energy.value)
	current_card.exhaust = card_exhaust.button_pressed
	current_card.tags = _parse_tags(card_tags.text)
	current_card.description = card_description.text
	current_card.card_art = _load_if_type(card_art_path.text, "Texture2D") as Texture2D
	current_card.sound_fx = _load_if_type(card_sound_path.text, "AudioStream") as AudioStream
	current_card.visual_fx = _load_if_type(card_visual_path.text, "PackedScene") as PackedScene
	current_card.projectile_fx = _load_if_type(card_projectile_path.text, "PackedScene") as PackedScene
	_update_card_preview()


func _on_card_save_pressed() -> void:
	_save_card(current_card_path)


func _on_card_save_as_pressed() -> void:
	save_target = "card"
	save_dialog.current_path = current_card_path if not current_card_path.is_empty() else CARD_DIR
	save_dialog.popup_centered_ratio(0.45)


func _save_card(path: String) -> void:
	if not current_card:
		_set_status("No card loaded to save.", true)
		return
	if path.is_empty():
		_set_status("Choose a save path for the card.", true)
		return
	_apply_card_form()
	var err: Error = ResourceSaver.save(current_card, path)
	if err != OK:
		_set_status("Could not save card (%s)." % err, true)
		return
	current_card_path = path
	card_path.text = path
	_set_status("Saved card to %s" % path)
	_clear_dirty()
	_refresh_cards()


func _on_card_new_pressed() -> void:
	current_card = Card.new()
	current_card_path = ""
	_populate_card_form(current_card)
	_mark_dirty()
	_set_status("New card stub created. Save to persist.")


func _reload_current_card() -> void:
	if current_card_path.is_empty():
		_set_status("No card path to reload.", true)
		return
	_load_card(current_card_path)


# --- Card Registry -----------------------------------------------------------

func _refresh_card_registries() -> void:
	card_registry_records.clear()
	var paths: Array[String] = _gather_resources(CARD_REGISTRY_DIR, ["tres"])
	for path in paths:
		var res: Resource = load(path)
		if res is CardRegistry:
			card_registry_records.append({"path": path, "label": path.get_file().get_basename()})
	card_registry_list.clear()
	for rec in card_registry_records:
		card_registry_list.add_item(rec.get("label", "Registry"))
		card_registry_list.set_item_metadata(card_registry_list.item_count - 1, rec.get("path", ""))
	if card_registry_list.item_count > 0:
		card_registry_list.select(0)
		_on_card_registry_selected(0)
	else:
		current_card_registry = null
		current_card_registry_entries.clear()


func _on_card_registry_selected(idx: int) -> void:
	if idx < 0:
		return
	var path: String = card_registry_list.get_item_metadata(idx)
	var res: Resource = load(path)
	if not (res is CardRegistry):
		_set_status("Selected file is not a CardRegistry.", true)
		return
	current_card_registry_path = path
	current_card_registry = res as CardRegistry
	card_registry_path.text = path
	current_card_registry_entries = current_card_registry.entries.duplicate(true)
	current_card_registry_index = -1
	_rebuild_card_registry_entries()
	_clear_dirty()
	_set_status("Loaded card registry.")


func _rebuild_card_registry_entries() -> void:
	card_registry_entry_list.clear()
	for i in current_card_registry_entries.size():
		var entry: Dictionary = current_card_registry_entries[i]
		var label: String = _entry_card_label(entry)
		var weight: float = entry.get("weight", 1.0)
		card_registry_entry_list.add_item("%s  (w:%s)" % [label, weight])
		card_registry_entry_list.set_item_metadata(i, i)
	if card_registry_entry_list.item_count > 0:
		card_registry_entry_list.select(0)
		_on_card_registry_entry_selected(0)


func _entry_card_label(entry: Dictionary) -> String:
	if entry.has("card") and entry.get("card") is Card:
		var c: Card = entry.get("card") as Card
		if c.name:
			return c.name
	if entry.has("card") and entry.get("card") is Resource:
		return (entry.get("card") as Resource).resource_path.get_file().get_basename()
	if entry.has("path"):
		return (entry.get("path") as String).get_file().get_basename()
	return "Card"


func _on_card_registry_entry_selected(idx: int) -> void:
	if idx < 0 or idx >= current_card_registry_entries.size():
		return
	current_card_registry_index = idx
	var entry: Dictionary = current_card_registry_entries[idx]
	block_dirty = true
	registry_card_path.text = ""
	if entry.has("card") and entry.get("card") is Resource:
		registry_card_path.text = (entry.get("card") as Resource).resource_path
	registry_class_id.text = entry.get("class_id", "")
	registry_weight.value = float(entry.get("weight", 1.0))
	var rarity_val: Variant = entry.get("rarity", -1)
	if rarity_val is Enums.CardRarity:
		rarity_val = int(rarity_val)
	_select_option_value(registry_rarity, rarity_val)
	registry_tags.text = ",".join(entry.get("tags", []))
	registry_unlocked.button_pressed = entry.get("unlocked", true)
	registry_allow_draft.button_pressed = entry.get("allow_draft", true)
	block_dirty = false


func _apply_card_registry_entry_form() -> void:
	if current_card_registry_index < 0 or current_card_registry_index >= current_card_registry_entries.size():
		return
	var entry: Dictionary = current_card_registry_entries[current_card_registry_index]
	var card_res: Card = _load_if_type(registry_card_path.text, "Card") as Card
	if card_res:
		entry["card"] = card_res
	entry["class_id"] = registry_class_id.text.strip_edges()
	entry["weight"] = float(registry_weight.value)
	entry["rarity"] = _get_option_value(registry_rarity, entry.get("rarity", -1))
	entry["tags"] = _parse_tags(registry_tags.text)
	entry["unlocked"] = registry_unlocked.button_pressed
	entry["allow_draft"] = registry_allow_draft.button_pressed
	current_card_registry_entries[current_card_registry_index] = entry
	_rebuild_card_registry_entries()
	card_registry_entry_list.select(current_card_registry_index)
	_set_status("Entry updated.")
	_mark_dirty()


func _add_card_registry_entry() -> void:
	var entry: Dictionary = {
		"card": null,
		"weight": 1.0,
		"class_id": "",
		"rarity": -1,
		"tags": [],
		"unlocked": true,
		"allow_draft": true
	}
	current_card_registry_entries.append(entry)
	_rebuild_card_registry_entries()
	card_registry_entry_list.select(current_card_registry_entries.size() - 1)
	_on_card_registry_entry_selected(current_card_registry_entries.size() - 1)
	_mark_dirty()


func _remove_card_registry_entry() -> void:
	if current_card_registry_index < 0 or current_card_registry_index >= current_card_registry_entries.size():
		return
	current_card_registry_entries.remove_at(current_card_registry_index)
	current_card_registry_index = -1
	_rebuild_card_registry_entries()
	_mark_dirty()


func _save_card_registry() -> void:
	if not current_card_registry:
		_set_status("No card registry loaded.", true)
		return
	_apply_card_registry_entry_form()
	current_card_registry.entries = current_card_registry_entries.duplicate(true)
	var err: Error = ResourceSaver.save(current_card_registry, current_card_registry_path)
	if err != OK:
		_set_status("Could not save registry (%s)." % err, true)
		return
	_set_status("Saved card registry.")
	_clear_dirty()
	_refresh_card_registries()


# --- Encounter Registry ------------------------------------------------------

func _refresh_encounter_registries() -> void:
	encounter_registry_records.clear()
	var paths: Array[String] = _gather_resources(CARD_REGISTRY_DIR, ["tres"])
	for path in paths:
		var res: Resource = load(path)
		if res is EncounterRegistry:
			encounter_registry_records.append({"path": path, "label": path.get_file().get_basename()})
	encounter_registry_list.clear()
	for rec in encounter_registry_records:
		encounter_registry_list.add_item(rec.get("label", "Encounter Registry"))
		encounter_registry_list.set_item_metadata(encounter_registry_list.item_count - 1, rec.get("path", ""))
	if encounter_registry_list.item_count > 0:
		encounter_registry_list.select(0)
		_on_encounter_registry_selected(0)
	else:
		current_encounter_registry = null
		current_encounter_entries.clear()


func _on_encounter_registry_selected(idx: int) -> void:
	if idx < 0:
		return
	var path: String = encounter_registry_list.get_item_metadata(idx)
	var res: Resource = load(path)
	if not (res is EncounterRegistry):
		_set_status("Selected file is not an EncounterRegistry.", true)
		return
	current_encounter_registry_path = path
	current_encounter_registry = res as EncounterRegistry
	encounter_registry_path.text = path
	current_encounter_entries = current_encounter_registry.encounters.duplicate(true)
	current_encounter_index = -1
	_rebuild_encounter_entries()
	_clear_dirty()
	_set_status("Loaded encounter registry.")


func _rebuild_encounter_entries() -> void:
	encounter_registry_entry_list.clear()
	for i in current_encounter_entries.size():
		var entry := current_encounter_entries[i]
		var label: String = entry.encounter_name
		var tier: int = entry.battle_tier
		encounter_registry_entry_list.add_item("%s (tier %s)" % [label, tier])
		encounter_registry_entry_list.set_item_metadata(i, i)
	if encounter_registry_entry_list.item_count > 0:
		encounter_registry_entry_list.select(0)
		_on_encounter_entry_selected(0)


func _on_encounter_entry_selected(idx: int) -> void:
	if idx < 0 or idx >= current_encounter_entries.size():
		return
	current_encounter_index = idx
	var entry := current_encounter_entries[idx]
	block_dirty = true
	encounter_stats_path.text = ""
	encounter_stats_path.text = entry.resource_path
	encounter_tier.value = entry.battle_tier
	encounter_weight.value = entry.weight
	encounter_tags.text = ",".join(entry.tags)
	encounter_elite.button_pressed = entry.is_elite
	encounter_boss.button_pressed = entry.category == EncounterDefinition.Category.BOSS
	encounter_unlocked.button_pressed = entry.unlocked
	block_dirty = false


func _apply_encounter_entry_form() -> void:
	if current_encounter_index < 0 or current_encounter_index >= current_encounter_entries.size():
		return
	var entry := current_encounter_entries[current_encounter_index]
	var stats_res: EncounterDefinition = _load_if_type(encounter_stats_path.text, "EncounterDefinition") as EncounterDefinition
	if stats_res:
		entry = stats_res
	entry.battle_tier = int(encounter_tier.value)
	entry.weight = float(encounter_weight.value)
	entry.tags = _parse_tags(encounter_tags.text)
	if encounter_boss.button_pressed:
		entry.category = EncounterDefinition.Category.BOSS
	elif encounter_elite.button_pressed:
		entry.category = EncounterDefinition.Category.ELITE
	elif entry.category != EncounterDefinition.Category.SPECIAL:
		entry.category = EncounterDefinition.Category.NORMAL
	entry.unlocked = encounter_unlocked.button_pressed
	current_encounter_entries[current_encounter_index] = entry
	_rebuild_encounter_entries()
	encounter_registry_entry_list.select(current_encounter_index)
	_set_status("Encounter entry updated.")
	_mark_dirty()


func _add_encounter_entry() -> void:
	var entry := EncounterDefinition.new()
	entry.encounter_name = "Choose an authored encounter resource"
	current_encounter_entries.append(entry)
	_rebuild_encounter_entries()
	encounter_registry_entry_list.select(current_encounter_entries.size() - 1)
	_on_encounter_entry_selected(current_encounter_entries.size() - 1)
	_mark_dirty()


func _remove_encounter_entry() -> void:
	if current_encounter_index < 0 or current_encounter_index >= current_encounter_entries.size():
		return
	current_encounter_entries.remove_at(current_encounter_index)
	current_encounter_index = -1
	_rebuild_encounter_entries()
	_mark_dirty()


func _save_encounter_registry() -> void:
	if not current_encounter_registry:
		_set_status("No encounter registry loaded.", true)
		return
	_apply_encounter_entry_form()
	# Registry membership references standalone authored definitions. Metadata lives
	# on those resources and must be saved there, rather than embedded as a copy.
	var encounter_ids: Array[String] = []
	for definition in current_encounter_entries:
		if definition.resource_path.is_empty() or definition.encounter_id.is_empty() or not definition.enemies:
			_set_status("Choose a saved encounter with a stable ID and composition before saving.", true)
			return
		if encounter_ids.has(definition.encounter_id):
			_set_status("Encounter IDs must be unique.", true)
			return
		encounter_ids.append(definition.encounter_id)
	for definition in current_encounter_entries:
		var definition_error := ResourceSaver.save(definition, definition.resource_path)
		if definition_error != OK:
			_set_status("Could not save encounter (%s)." % definition_error, true)
			return
	current_encounter_registry.encounters = current_encounter_entries.duplicate(true)
	var err: Error = ResourceSaver.save(current_encounter_registry, current_encounter_registry_path)
	if err != OK:
		_set_status("Could not save encounter registry (%s)." % err, true)
		return
	_set_status("Saved encounter registry.")
	_clear_dirty()
	_refresh_encounter_registries()


# --- Decks -------------------------------------------------------------------

func _refresh_decks() -> void:
	deck_records.clear()
	var paths: Array[String] = _gather_resources(CARD_PILES_DIR, ["tres"])
	for path in paths:
		var res: Resource = load(path)
		if res is CardPile:
			deck_records.append({"path": path, "label": path.get_file().get_basename()})
	deck_list.clear()
	for rec in deck_records:
		deck_list.add_item(rec.get("label", "Deck"))
		deck_list.set_item_metadata(deck_list.item_count - 1, rec.get("path", ""))
	if deck_list.item_count > 0:
		deck_list.select(0)
		_on_deck_selected(0)


func _on_deck_selected(idx: int) -> void:
	if idx < 0:
		return
	var path: String = deck_list.get_item_metadata(idx)
	var res: Resource = load(path)
	if not (res is CardPile):
		_set_status("Selected file is not a CardPile.", true)
		return
	current_deck = res as CardPile
	current_deck_path = path
	deck_path.text = path
	_rebuild_deck_cards()
	_clear_dirty()
	_set_status("Loaded deck.")


func _rebuild_deck_cards() -> void:
	deck_cards.clear()
	if not current_deck:
		return
	for i in current_deck.cards.size():
		var card: Card = current_deck.cards[i]
		var label: String = card.name if card and card.name else "Card %s" % i
		deck_cards.add_item(label)
		deck_cards.set_item_metadata(i, i)


func _add_card_to_deck(card_res: Card) -> void:
	if not current_deck or not card_res:
		return
	current_deck.cards.append(card_res)
	_rebuild_deck_cards()
	deck_cards.select(current_deck.cards.size() - 1)
	_set_status("Added card to deck.")
	_mark_dirty()


func _remove_deck_card() -> void:
	if not current_deck or deck_cards.get_selected_items().is_empty():
		return
	var idx: int = deck_cards.get_selected_items()[0]
	current_deck.cards.remove_at(idx)
	_rebuild_deck_cards()
	_mark_dirty()


func _move_deck_card(delta: int) -> void:
	if not current_deck or deck_cards.get_selected_items().is_empty():
		return
	var idx: int = deck_cards.get_selected_items()[0]
	var new_idx: int = clamp(idx + delta, 0, current_deck.cards.size() - 1)
	if idx == new_idx:
		return
	var tmp: Card = current_deck.cards[idx]
	current_deck.cards[idx] = current_deck.cards[new_idx]
	current_deck.cards[new_idx] = tmp
	_rebuild_deck_cards()
	deck_cards.select(new_idx)
	_mark_dirty()


func _save_deck() -> void:
	if not current_deck:
		_set_status("No deck loaded.", true)
		return
	if current_deck_path.is_empty():
		_set_status("Select a deck to save.", true)
		return
	var err: Error = ResourceSaver.save(current_deck, current_deck_path)
	if err != OK:
		_set_status("Could not save deck (%s)." % err, true)
		return
	_set_status("Saved deck.")
	_clear_dirty()
	_refresh_decks()


# --- Pickers and Helpers -----------------------------------------------------

func _on_back_pressed() -> void:
	if Engine.has_singleton("SoundManager") and Engine.has_singleton("AudioLibrary"):
		SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_card_form_changed(_value = null) -> void:
	if block_dirty:
		return
	_apply_card_form()
	_mark_dirty()


func _on_registry_form_changed(_value = null) -> void:
	if block_dirty:
		return
	_mark_dirty()


func _on_encounter_form_changed(_value = null) -> void:
	if block_dirty:
		return
	_mark_dirty()


func _update_card_preview() -> void:
	if not card_preview:
		return
	card_preview.playable = false
	card_preview.card = current_card


func _mark_dirty() -> void:
	if block_dirty:
		return
	is_dirty = true
	_update_dirty_label()


func _clear_dirty() -> void:
	is_dirty = false
	_update_dirty_label()


func _update_dirty_label() -> void:
	if not dirty_label:
		return
	dirty_label.text = "Unsaved" if is_dirty else "Saved"
	dirty_label.theme_type_variation = &"EditorUnsaved" if is_dirty else &"EditorSaved"

func _open_picker(which: PickTarget, start_dir: String, filters: Array[String], file_mode: FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE) -> void:
	pick_target = which
	resource_picker.file_mode = file_mode
	resource_picker.filters = filters
	resource_picker.current_dir = start_dir
	resource_picker.popup_centered_ratio(0.5)


func _on_resource_picker_file_selected(path: String) -> void:
	match pick_target:
		PickTarget.REGISTRY_CARD:
			registry_card_path.text = path
		PickTarget.ENCOUNTER_STATS:
			encounter_stats_path.text = path
		PickTarget.DECK_CARD:
			var card_res: Card = _load_if_type(path, "Card") as Card
			if card_res:
				_add_card_to_deck(card_res)
		PickTarget.CARD_ART:
			card_art_path.text = path
		PickTarget.CARD_SOUND:
			card_sound_path.text = path
		PickTarget.CARD_VISUAL:
			card_visual_path.text = path
		PickTarget.CARD_PROJECTILE:
			card_projectile_path.text = path
	pick_target = PickTarget.NONE


func _on_save_dialog_file_selected(path: String) -> void:
	match save_target:
		"card":
			_save_card(path)
		_:
			pass
	save_target = ""


func _set_status(message: String, is_error: bool = false) -> void:
	status_label.text = message
	status_label.theme_type_variation = &"EditorError" if is_error else &"EditorSaved"


func _gather_resources(base_path: String, extensions: Array[String]) -> Array[String]:
	var results: Array[String] = []
	var dir: DirAccess = DirAccess.open(base_path)
	if not dir:
		return results
	dir.list_dir_begin()
	var res_name: String = dir.get_next()
	while res_name != "":
		if res_name.begins_with("."):
			res_name = dir.get_next()
			continue
		var full_path: String = base_path.path_join(res_name)
		if dir.current_is_dir():
			results += _gather_resources(full_path, extensions)
		elif extensions.has(res_name.get_extension()):
			results.append(full_path)
		res_name = dir.get_next()
	dir.list_dir_end()
	results.sort()
	return results


func _parse_tags(text: String) -> Array[String]:
	var tags: Array[String] = []
	for raw in text.split(",", false):
		var t: String = raw.strip_edges()
		if not t.is_empty():
			tags.append(t)
	return tags


func _populate_enum_options(button: OptionButton, enum_dict: Dictionary, include_blank: bool = false) -> void:
	button.clear()
	if include_blank:
		button.add_item("Use Card Value", -1)
	for enum_name in enum_dict.keys():
		button.add_item(enum_name.capitalize(), enum_dict[enum_name])


func _select_option_value(button: OptionButton, value: int) -> void:
	for i in button.item_count:
		if button.get_item_id(i) == value:
			button.select(i)
			return
	if button.item_count > 0:
		button.select(0)


func _get_option_value(button: OptionButton, fallback) -> Variant:
	if button.item_count == 0:
		return fallback
	return button.get_selected_id()


func _load_if_type(path: String, type_name: String) -> Resource:
	if path.is_empty():
		return null
	var res: Resource = load(path)
	if not res:
		return null
	if type_name.is_empty():
		return res
	if res is Object and (res as Object).is_class(type_name):
		return res
	if res.get_class() == type_name:
		return res
	return null
