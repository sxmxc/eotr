extends Resource
class_name CardRegistry

@export var entries: Array[Dictionary] = []

var _rng: RandomNumberGenerator


func clear_entries() -> void:
	entries.clear()


func add_card(
	card: Card,
	tags: Array[String] = [],
	weight: float = 1.0,
	class_id: String = "",
	unlocked: bool = true,
	allow_draft: bool = true
) -> void:
	if not card:
		return

	var combined_tags := tags.duplicate()
	if card.tags.size() > 0:
		for tag in card.tags:
			if not combined_tags.has(tag):
				combined_tags.append(tag)
	if allow_draft == false and not combined_tags.has("no_draft"):
		combined_tags.append("no_draft")

	var entry := {
		"card": card,
		"rarity": card.card_rarity,
		"tags": combined_tags,
		"weight": weight,
		"class_id": class_id,
		"unlocked": unlocked,
		"allow_draft": allow_draft
	}
	entries.append(entry)


func build_from_card_pile(pile: CardPile, tags: Array[String] = [], class_id: String = "") -> void:
	if not pile:
		return

	for card: Card in pile.cards:
		add_card(card, tags, 1.0, class_id)


func _is_entry_draftable(entry: Dictionary) -> bool:
	if entry.get("allow_draft", true) == false:
		return false
	var entry_tags: Array = entry.get("tags", [])
	if entry_tags.has("no_draft"):
		return false
	return true


func get_all_cards(class_id: String = "") -> Array[Card]:
	var results: Array[Card] = []
	for entry: Dictionary in entries:
		var entry_class: String = entry.get("class_id", "")
		if not class_id.is_empty() and not entry_class.is_empty() and entry_class != class_id:
			continue
		var card: Card = entry.get("card", null)
		if card:
			results.append(card.duplicate(true))
	return results


func _matches_filters(
	entry: Dictionary,
	rarity: Enums.CardRarity,
	class_id: String,
	tags: Array[String],
	require_draftable: bool
) -> bool:
	if entry.get("unlocked", true) == false:
		return false
	if require_draftable and not _is_entry_draftable(entry):
		return false
	var entry_rarity: Variant = entry.get("rarity", null)
	if entry_rarity == null and entry.has("card") and entry.get("card") is Card:
		entry_rarity = (entry.get("card") as Card).card_rarity
	if entry_rarity != rarity:
		return false

	var entry_class: String = entry.get("class_id", "")
	if not class_id.is_empty() and not entry_class.is_empty() and entry_class != class_id:
		return false

	if tags.is_empty():
		return true

	var entry_tags: Array = entry.get("tags", [])
	for tag: String in tags:
		if not entry_tags.has(tag):
			return false
	return true


func pick_random_card(
	rarity: Enums.CardRarity,
	exclude_cards: Array[Card] = [],
	class_id: String = "",
	tags: Array[String] = [],
	require_draftable: bool = true,
	rng: RandomNumberGenerator = null
) -> Card:
	var candidates: Array[Dictionary] = []

	for entry: Dictionary in entries:
		if not _matches_filters(entry, rarity, class_id, tags, require_draftable):
			continue
		var card: Card = entry.get("card", null)
		if not card:
			continue
		if exclude_cards.has(card) or exclude_cards.any(func(excluded: Card): return excluded.id == card.id):
			continue
		candidates.append(entry)

	if candidates.is_empty():
		return null

	var total_weight := 0.0
	for entry: Dictionary in candidates:
		var entry_weight := float(entry.get("weight", 1.0))
		total_weight += entry_weight

	var used_rng := _get_rng(rng)
	var roll := used_rng.randf_range(0.0, total_weight)
	var accumulated := 0.0

	for entry: Dictionary in candidates:
		var entry_weight := float(entry.get("weight", 1.0))
		accumulated += entry_weight
		if roll <= accumulated:
			var picked: Card = entry.get("card", null)
			return picked.duplicate(true) if picked else null

	var fallback: Card = candidates.back().get("card", null)
	return fallback.duplicate(true) if fallback else null


func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng


func _get_rng(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if rng:
		return rng
	if _rng:
		return _rng
	return RNG.instance
