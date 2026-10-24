extends Node

const WORLD := preload("res://scenes/game_world/game_world.tscn")
const RELICS := preload("res://scenes/relic_handler/relic_handler.tscn")
var failures := 0
var world: GameWorld

func _ready() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for i in 180:
		if not is_instance_valid(world): return
		var pending := world.player.pending_effects
		for enemy: Enemy in world.enemy_handler.get_children(): pending += enemy.pending_damage
		if pending == 0: return
		await get_tree().process_frame
	check(false, "Effects settle within bounded frame budget")

func card(id: String) -> Card:
	return load("res://resources/data/cards/synthforged/%s.tres" % id).duplicate(true) as Card

func run() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	Utils.presentation_speed = 20.0
	RNG.instance.seed = 27
	var relics := RELICS.instantiate() as RelicHandler
	add_child(relics)
	world = WORLD.instantiate() as GameWorld
	add_child(world)
	world.player_stats = load("res://resources/data/stats/player/synthforged_starting_stats.tres").create_instance()
	world.run_stats = RunStats.new()
	world.battle_stats = load("res://resources/data/battles/tier_0_blobs.tres").duplicate(true)
	world.relics = relics
	relics.add_relic(world.player_stats.starting_relic.duplicate(true))
	world.start_world()
	for i in 240:
		if world.player_handler.hand_ready: break
		await get_tree().process_frame
	world.tilemap.hide_fog()
	await settle()
	check(world.player_stats.max_health == 35 and world.player_stats.deck.cards.size() == 11, "Synthforged starting stats and deck")
	var registry := load("res://resources/data/registries/card_registry_synthforged.tres") as CardRegistry
	check(registry.entries.size() == 36, "36 unique authored cards")
	check(world.player_stats.draftable_cards.cards.size() == 29, "29 non-starter draft identities")
	var ids: Dictionary[String, bool] = {}
	var rarity_counts := [0, 0, 0]
	for entry: Dictionary in registry.entries:
		var resource := entry.card as Card
		check(resource != null and not ids.has(resource.id), "Stable unique card identity")
		check(resource.card_art != null and resource.card_art.get_size() == Vector2(592, 396), "Imported canonical card illustration: " + resource.id)
		ids[resource.id] = true
		rarity_counts[resource.card_rarity] += 1
		resource._sync_effect_configs()
		check(resource.tags.has("expansion") or not resource.effect_configs.is_empty(), "Configured effects: " + resource.id)
	check(rarity_counts == [15, 14, 7], "Complete rarity distribution")
	check(RegistryData.card_registry.get_all_cards("Synthforged").size() == 44, "Merged registry retains neutral cards and Synthforged")
	await test_shared_pools()
	var authored := load("res://resources/data/cards/synthforged/pulse_rifle.tres") as Card
	var pile := CardPile.new()
	pile.cards.assign([authored, authored])
	var independent := pile.duplicate_cards()
	independent[0].effect_configs[0].amount = 99
	check(independent[1].effect_configs[0].amount == 6 and authored.effect_configs[0].amount == 6, "Authored effect resources remain isolated between deck copies")
	var legacy := SaveGame.new()
	legacy.current_deck = load("res://scripts/tests/fixtures/legacy_synthforged_deck.tres").duplicate(true)
	legacy._restore_legacy_synthforged_cards()
	check(legacy.current_deck.cards[0].effect_configs[0].amount == 6, "Legacy lazy card restores authored damage")
	check(legacy.current_deck.cards[1].get_script().resource_path.ends_with("phase_step.gd"), "Legacy movement restores its real behavior owner")
	check(legacy.current_deck.cards[1].energy_cost == 0 and legacy.current_deck.cards[1].exhaust, "Legacy recovery preserves saved cost and exhaust")
	check(legacy.current_deck.cards[2] is ConstructSummonCard and not legacy.current_deck.cards[2].effect_configs.is_empty(), "Legacy summon restores its deployment configuration")
	for turn in range(2, 9):
		world.player_handler.cancel_turn()
		world.player_handler.start_turn()
		check(world.player_stats.energy == (5 if turn % 4 == 0 else 3), "Overclock only on turn %d" % turn)
		world.player_handler.cancel_turn()
	world.player_handler.player_turn_count = 0
	world.player_handler.start_turn()
	check(world.player_stats.energy == 3, "Fresh battle counter does not inherit Overclock")
	world.player_handler.cancel_turn()
	world.player_stats.energy = 3
	world.player_handler.free_movement_refund_available = true
	world.player_handler._refund_movement_energy(card("vector_boost"))
	world.player_handler._on_obelisk_damage_taken(6)
	check(world.player_stats.energy == 3, "Riftwalker bonuses remain class exclusive")
	var enemy := world.enemy_handler.get_child(0) as Enemy
	enemy.stats.max_health = 1000
	enemy.stats.health = 1000
	enemy.stats.block = 0
	for i in 5: enemy.status_handler.add_status(AnalyzedStatus.new())
	check(AnalyzedStatus.count(enemy) == 3, "Analyze stacks cap at three")
	check(card("precision_shot").get_modified_description(world.player.modifier_handler, enemy.modifier_handler).contains("Deal 15"), "Precision Shot preview includes conditional and Analyze bonuses")
	check(card("rail_lance").get_modified_description(world.player.modifier_handler, enemy.modifier_handler).contains("Deal 24"), "Consumed Analyze preview matches actual damage")
	var effect := DamageEffect.new()
	effect.amount = 6
	effect.player_side_attack = true
	effect.execute([enemy])
	await settle()
	check(enemy.stats.health == 991, "Analyze boosts a direct player-side hit")
	effect.player_side_attack = false
	effect.execute([enemy])
	await settle()
	check(enemy.stats.health == 985, "Unmarked damage excludes Analyze")
	world.player_stats.energy = 100
	await card("rail_lance").play([enemy], world.player_stats, world.player.modifier_handler)
	await settle()
	check(enemy.stats.health == 961 and AnalyzedStatus.count(enemy) == 0, "Rail Lance consumes three stacks for 24 without double counting")
	var legal: Array[Vector2i] = []
	for cell in world.tilemap.get_surrounding_tiles_in_radius(world.tilemap.player_position, 2):
		if world.summons.can_deploy(cell): legal.append(cell)
	check(legal.size() >= 3, "Fixture has three legal deployment tiles")
	if legal.size() < 3:
		finish()
		return
	var definition := load("res://resources/data/constructs/sentry.tres") as ConstructDefinition
	var unit := world.summons.deploy(definition, legal[0])
	check(unit != null and not world.tilemap.is_tile_free(legal[0]), "Deployment registers authoritative occupancy")
	check(world.summons.deploy(definition, legal[0]) == null, "Occupied placement rejected")
	world.summons.deploy(definition, legal[1])
	world.summons.deploy(definition, legal[2])
	check(not world.summons.can_deploy(world.tilemap.player_position), "Summon cap and player occupancy reject deployment")
	unit.stats.block = 5
	world.summons.start_turn()
	check(unit.stats.block == 0, "Construct block resets at player start")
	await test_construct_modifiers(unit)
	unit.take_damage(5, Enums.ModifierType.NO_MODIFIER)
	await card("field_repairs").play([unit], world.player_stats, world.player.modifier_handler)
	check(unit.stats.health == 12, "Repairs clamp at maximum HP")
	var origin := unit.current_tile_position
	for cell in world.tilemap.base_layer.get_surrounding_cells(origin):
		if world.summons.legal_cell(cell):
			world.summons.relocate(unit, cell)
			check(world.tilemap.is_tile_free(origin) and not world.tilemap.is_tile_free(cell), "Relocation transfers occupancy")
			break
	var previous_health := enemy.stats.health
	enemy.current_tile_position = world.tilemap.base_layer.get_surrounding_cells(unit.current_tile_position)[0]
	enemy.global_position = world.tilemap.cell_to_world(enemy.current_tile_position)
	await unit.activate()
	await settle()
	check(enemy.stats.health < previous_health, "Construct activation resolves actual damage")
	world.player_stats.fabrication_discount = true
	check(card("deploy_sentry").get_energy_cost(world.player_stats) == 1, "Fabrication discounts summons")
	check(card("pulse_rifle").get_energy_cost(world.player_stats) == 1, "Fabrication does not discount attacks")
	var freed_cell := unit.current_tile_position
	unit.take_damage(999, Enums.ModifierType.NO_MODIFIER, true)
	check(world.tilemap.is_tile_free(freed_cell), "Construct death releases occupancy immediately")
	var fixture := SynthforgedCardFixture.new()
	var findings := await fixture.run(world)
	for finding in findings: check(false, finding)
	var expansion := ExpansionCardFixture.new()
	for finding in await expansion.run(world): check(false, finding)
	world.player_stats.player_class_name = "Riftwalker"
	var walker_cards := ExpansionCardFixture.new()
	for finding in await walker_cards.run(world): check(false, finding)
	world.player_stats.player_class_name = "Synthforged"
	await test_redeployment_and_enemy_targets()
	var lifecycle := SynthforgedLifecycleFixture.new()
	for finding in await lifecycle.run(world): check(false, finding)
	world.battle_state.end_battle()
	world.queue_free()
	await get_tree().process_frame
	relics.queue_free()
	await get_tree().create_timer(0.5).timeout
	await test_progression()
	await Utils.stop_audio_for_shutdown()
	finish()

func test_construct_modifiers(unit: Construct) -> void:
	var taken := unit.modifier_handler.get_modifier(Enums.ModifierType.DMG_TAKEN)
	var dealt := unit.modifier_handler.get_modifier(Enums.ModifierType.DMG_DEALT)
	check(taken != null and dealt != null, "Deployed constructs author both damage modifier slots")
	if not taken or not dealt:
		return
	var other := world.summons.living()[1]
	check(other.modifier_handler.get_modifier(Enums.ModifierType.DMG_TAKEN) != taken,
		"Construct instances own independent damage modifiers")
	var weakened: Status = preload("res://resources/data/statuses/weakened.tres").duplicate(true)
	weakened.duration = 1
	var effect := StatusEffect.new()
	effect.status = weakened
	effect.execute([unit])
	var health := unit.stats.health
	unit.take_damage(4, Enums.ModifierType.DMG_TAKEN)
	check(unit.stats.health == health - 6, "Weakened amplifies real construct damage by 50 percent")
	check(other.modifier_handler.get_modified_value(4, Enums.ModifierType.DMG_TAKEN) == 4,
		"Weakened does not affect another construct")
	unit.status_handler.apply_statuses_by_type(weakened.type)
	await unit.status_handler.statuses_applied
	check(taken.get_value("weakened") == null, "Construct Weakened expiry removes its modifier")
	health = unit.stats.health
	unit.take_damage(4, Enums.ModifierType.DMG_TAKEN)
	check(unit.stats.health == health - 4, "Construct damage returns to normal after expiry")
	effect.execute([unit])
	check(taken.get_modified_value(4) == 6, "Construct Weakened can be reapplied after expiry")
	unit.status_handler.remove_status("weakened")
	check(taken.get_modified_value(4) == 4, "Explicit construct status removal cleans the modifier")
	unit.stats.health = unit.stats.max_health


func test_redeployment_and_enemy_targets() -> void:
	world.summons.reset()
	await get_tree().process_frame
	var board := world.tilemap
	board.hide_fog()
	var unit: Construct
	for cell in board.get_surrounding_tiles_in_radius(board.player_position, 2):
		if world.summons.can_deploy(cell):
			unit = world.summons.deploy(load("res://resources/data/constructs/sentry.tres"), cell)
			break
	check(unit != null, "Interaction fixture supplies construct")
	if not unit: return
	var hand := world.player_handler.player_hand
	for old: CardUI in hand.get_cards(): hand.discard_card(old)
	world.player_handler.hand_ready = true
	world.player_stats.energy = 10
	hand.add_card(card("redeployment"))
	var ui := hand.get_cards().back() as CardUI
	await get_tree().process_frame
	var controller := world.card_interaction
	var machine := ui.card_state_machine
	machine._on_transition_requested(machine.current_state, CardState.State.CLICKED)
	machine._on_transition_requested(machine.current_state, CardState.State.AIMING)
	controller.select_target(ui, unit)
	controller._release(machine.current_state)
	check(controller.relocation_unit == unit and ui.targets.is_empty(), "First confirm selects construct without committing")
	controller._release(machine.current_state)
	check(controller.active_card == ui, "Release edge after source selection keeps destination aim open")
	var destination: TilemapTarget
	for cell in board.base_layer.get_surrounding_cells(unit.current_tile_position):
		if world.summons.legal_cell(cell):
			destination = TilemapTarget.new(cell, board)
			world.add_child(destination)
			break
	check(destination != null, "Redeployment fixture supplies adjacent destination")
	if destination:
		controller.select_target(ui, destination)
		check(ui.can_execute(ui.targets) and ui.targets.size() == 2, "Two-stage aim shares live authorization")
		controller.cancel_active()
		check(world.player_stats.energy == 10 and controller.relocation_unit == null, "Cancel clears both stages without cost")
		destination.queue_free()
	var hostile := preload("res://scenes/enemy/moving_enemy.tscn").instantiate() as MovingEnemy
	hostile.stats = load("res://scenes/enemy/blob/blob_enemy.tres")
	var spawn := Vector2i(-999, -999)
	for cell in board.base_layer.get_surrounding_cells(unit.current_tile_position):
		if board.is_tile_valid(cell) and board.is_tile_free(cell) and SummonHandler.distance(board, cell, board.player_position) > 1:
			spawn = cell
			break
	if spawn == Vector2i(-999, -999):
		hostile.free()
		check(false, "Enemy target fixture has legal spawn")
		return
	world.enemy_handler.add_enemy(hostile, spawn)
	hostile.enemy_action_picker.refresh_target()
	check(hostile.enemy_action_picker.target == unit, "Enemy selects nearer reachable construct")
	var attack: EnemyAction
	for action: EnemyAction in hostile.enemy_action_picker.get_children():
		if action.get_script().resource_path.ends_with("blob_attack_action.gd"): attack = action
	check(attack != null and attack.is_eligible(), "Melee attack range follows construct recipient")
	if attack:
		var health_before := world.player_stats.health
		attack.perform_action()
		var deadline := Time.get_ticks_msec() + 3000
		while unit.stats.health == unit.stats.max_health and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		check(unit.stats.health < unit.stats.max_health and world.player_stats.health == health_before, "Enemy damages construct without player hit or deck pollution")
		attack.cancel_action()
	unit.destroy()
	await get_tree().process_frame
	hostile.enemy_action_picker.refresh_target()
	check(hostile.enemy_action_picker.target == world.player, "Destroyed recipient retargets safely")
	world.enemy_handler.remove_child(hostile)
	hostile.queue_free()

func test_progression() -> void:
	for class_id: String in ["synthforged", "riftwalker"]:
		var run := preload("res://scenes/run/run.tscn").instantiate() as Run
		run.run_bootstrap = RunBootstrap.new()
		run.run_bootstrap.type = RunBootstrap.Type.NEW_RUN
		run.run_bootstrap.selected_player_class = load("res://resources/data/stats/player/%s_starting_stats.tres" % class_id)
		add_child(run)
		await get_tree().process_frame
		check(run.player_stats.player_class_name.to_lower() == class_id, "New run selects " + class_id)
		var class_cards := RegistryData.card_registry.get_all_cards(run.player_stats.player_class_name)
		run._on_shop_entered()
		await get_tree().process_frame
		var shop := run.current_view.get_child(0) as Shop
		check(shop.cards.get_child_count() == 3, "Shop supplies three class-eligible cards: " + class_id)
		for item: ShopCard in shop.cards.get_children():
			check(class_cards.any(func(candidate: Card): return candidate.id == item.card.id), "Shop never supplies the other class")
		var rewards := preload("res://scenes/battle_rewards/battle_rewards.tscn").instantiate() as BattleRewards
		add_child(rewards)
		rewards.player_stats = run.player_stats
		for rarity: Enums.CardRarity in [Enums.CardRarity.COMMON, Enums.CardRarity.UNCOMMON, Enums.CardRarity.RARE]:
			var picked := rewards._pick_card_reward(rarity, run.player_stats.draftable_cards.cards, [], run.player_stats.player_class_name)
			check(picked != null and class_cards.any(func(candidate: Card): return candidate.id == picked.id), "Reward eligibility across rarities: " + class_id)
		rewards.queue_free()
		if class_id == "synthforged": run.player_stats.deck.add_card(card("combat_network"))
		check(run._save_run(true), "Room checkpoint saves " + class_id)
		var expected_deck_size := run.player_stats.deck.cards.size()
		run.queue_free()
		await get_tree().process_frame
		var continued := preload("res://scenes/run/run.tscn").instantiate() as Run
		continued.run_bootstrap = RunBootstrap.new()
		continued.run_bootstrap.type = RunBootstrap.Type.CONTINUED_RUN
		add_child(continued)
		await get_tree().process_frame
		check(continued.player_stats.player_class_name.to_lower() == class_id and continued.player_stats.deck.cards.size() == expected_deck_size, "Save/resume preserves class and cards: " + class_id)
		check(continued.relic_handler.has_relic("overclock_core" if class_id == "synthforged" else "phase_key"), "Save/resume preserves starter relic")
		continued.queue_free()
		await get_tree().process_frame

func finish() -> void:
	print("Synthforged tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)

func test_shared_pools() -> void:
	var shared := load("res://resources/data/registries/card_registry_shared.tres") as CardRegistry
	check(shared.entries.size() == 6, "Six genuinely shared player identities")
	for class_id in ["Riftwalker", "Synthforged"]:
		var found: Array[Card] = []
		var seeded := RandomNumberGenerator.new()
		seeded.seed = 41
		for rarity: Enums.CardRarity in [Enums.CardRarity.COMMON, Enums.CardRarity.UNCOMMON, Enums.CardRarity.RARE]:
			for attempt in 80:
				var picked := RegistryData.card_registry.pick_random_card(rarity, found, class_id, [], true, seeded)
				if not picked: break
				check(picked.id not in ["void_residue", "void_slime", "void_shard"], "Negative/generated cards never enter drafts")
				found.append(picked)
		for entry: Dictionary in shared.entries:
			check(found.any(func(card: Card) -> bool: return card.id == entry.card.id), "Shared card accessible to " + class_id + ": " + entry.card.id)
		# Use the real reward and shop consumers with an explicit shared-only
		# registry to force the case without depending on a lucky random roll.
		var rewards := preload("res://scenes/battle_rewards/battle_rewards.tscn").instantiate() as BattleRewards
		rewards.card_registry = shared
		add_child(rewards)
		var reward := rewards._pick_card_reward(Enums.CardRarity.COMMON, [], [], class_id)
		check(reward != null and shared.entries.any(func(entry: Dictionary) -> bool: return entry.card.id == reward.id), "Real reward consumer accepts shared classless cards: " + class_id)
		rewards.queue_free()
		var shop := preload("res://scenes/shop/shop.tscn").instantiate() as Shop
		shop.card_registry = shared
		shop.player_stats = world.player_stats
		var original_class := world.player_stats.player_class_name
		world.player_stats.player_class_name = class_id
		shop.run_stats = world.run_stats
		add_child(shop)
		await get_tree().process_frame
		shop._generate_shop_cards()
		check(shop.cards.get_child_count() == 3, "Real shop supplies three shared cards: " + class_id)
		for item: ShopCard in shop.cards.get_children():
			check(shared.entries.any(func(entry: Dictionary) -> bool: return entry.card.id == item.card.id), "Shop uses shared eligibility: " + class_id)
		world.player_stats.player_class_name = original_class
		shop.queue_free()
		await get_tree().process_frame
