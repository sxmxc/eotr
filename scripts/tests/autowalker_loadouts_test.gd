extends Node

const Loadouts = preload("res://scripts/autowalker/core/loadouts.gd")
var failures := 0

func _ready() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var template: PlayerStats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres")
	var prior := ""
	for tier in [0, 1, 2, 2]:
		var handler: RelicHandler = load("res://scenes/relic_handler/relic_handler.tscn").instantiate()
		add_child(handler)
		var stats: PlayerStats = template.create_instance()
		var snapshot := Loadouts.apply(stats, handler, "tier", tier, 75)
		check(stats.deck.cards.size() == 11 + tier * 4, "Tier deck size")
		check(handler.get_all_relics().size() == 1 + tier, "Tier relic count")
		check(stats.health == 26 and snapshot.initial_health == 26, "Starting health applied and recorded")
		for card: Card in stats.deck.cards.slice(11):
			check(template.draftable_cards.cards.any(func(candidate: Card): return candidate.id == card.id), "Added card is draftable")
		check(template.starting_deck.cards.size() == 11, "Presets leave starting resources intact")
		if tier == 2:
			check(prior.is_empty() or prior == snapshot.loadout_fingerprint, "Repeated preset has stable identity")
			prior = snapshot.loadout_fingerprint
		stats.deck.cards[0].energy_cost = 99
		check(template.starting_deck.cards[0].energy_cost != 99, "Simulation cards are isolated")
		handler.queue_free()
		await get_tree().process_frame
	print("AutoWalker loadout tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
