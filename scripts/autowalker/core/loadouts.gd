extends RefCounted

# Controlled, attainable test builds; these are not measured player averages.
const VERSION := 1
const EXTRA_CARDS := ["nano_shield", "phase_slash", "arcane_explosion", "focus",
	"void_fracture", "mana_leech", "rift_knowledge", "adrenaline_rush"]

static func apply(stats: PlayerStats, handler: RelicHandler, selection: String, tier: int, health_percent: int) -> Dictionary:
	var resolved := "tier_%d" % clampi(tier, 0, 2) if selection == "tier" else selection
	var additions := 0
	if resolved == "tier_1": additions = 4
	if resolved == "tier_2": additions = 8
	stats.deck = stats.deck.deep_duplicate()
	var synth := stats.player_class_name == "Synthforged"
	var extras := ["deploy_pike", "precision_shot", "wideband_scan", "field_repairs", "rail_lance", "fire_command", "deploy_siege_platform", "combat_network"] if synth else EXTRA_CARDS
	for index in additions:
		var card: Card = load("res://resources/data/cards/%s/%s.tres" % ["synthforged" if synth else "riftwalker", extras[index]])
		stats.deck.add_card(card.duplicate(true))
	# The old encounter harness omitted even the class's starting relic. Preserve
	# that setup only for legacy reports/replays and explicitly selected QA checks.
	if resolved != "legacy":
		handler.add_relic(stats.starting_relic.duplicate(true))
	if additions >= 4 and not synth:
		handler.add_relic(load("res://resources/data/relics/feedback_circuit.tres").duplicate(true))
	if additions >= 8 and not synth:
		handler.add_relic(load("res://resources/data/relics/temporal_conduit.tres").duplicate(true))
	stats.health = maxi(1, int(stats.max_health * health_percent / 100.0))
	var cards: Array = []
	for card: Card in stats.deck.cards:
		cards.append(card.id)
	var relic_ids: Array = []
	for relic: Relic in handler.get_all_relics():
		relic_ids.append(relic.id)
	var snapshot := {"loadout": resolved, "loadout_selection": selection, "loadout_version": VERSION,
		"initial_deck": cards, "initial_relics": relic_ids, "initial_health": stats.health,
		"max_health": stats.max_health, "max_energy": stats.max_energy, "cards_per_turn": stats.cards_per_turn,
		"health_percent": health_percent, "loadout_basis": "controlled_preset"}
	if synth: snapshot["player_class"] = "synthforged"
	snapshot["loadout_fingerprint"] = JSON.stringify(snapshot).sha256_text()
	return snapshot
