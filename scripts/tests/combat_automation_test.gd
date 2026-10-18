extends Node

const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
const Interface = preload("res://scripts/autowalker/core/gameplay_interface.gd")
var failures := 0

class CountingAction extends EnemyAction:
	var calls := 0

	func is_eligible() -> bool:
		return true

	func perform_action() -> void:
		calls += 1

	func update_intent_text() -> void:
		pass

func _ready() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	_test_projectile_ownership()
	RNG.instance.seed = 42
	var relics := RELICS.instantiate() as RelicHandler
	add_child(relics)
	var world := WORLD.instantiate() as GameWorld
	add_child(world)
	world.player_stats = load("res://resources/data/stats/player/riftwalker_starting_stats.tres").create_instance()
	world.run_stats = RunStats.new()
	world.battle_stats = load("res://resources/data/battles/tier_1_channelers_bulwark.tres").duplicate(true)
	world.relics = relics
	world.start_world()
	await get_tree().create_timer(0.2).timeout
	var api := Interface.new()
	api.world = world
	var ready_deadline := Time.get_ticks_msec() + 2000
	while not api.ready_for_action() and Time.get_ticks_msec() < ready_deadline:
		await get_tree().process_frame
	check(api.ready_for_action(), "Hand/turn resolves to a legal action boundary")
	await _test_enemy_turn_cancellation(world)
	await _test_instability_costs(world, relics)
	await _test_feedback_circuit(world, relics)
	var actions: Array[Dictionary] = api.legal_actions()
	check(not actions.is_empty() and actions.back().kind == "end_turn", "Enumerates real legal actions")
	var stale: Dictionary = {}
	for action in actions:
		if action.kind == "play_card" and action.cost > 0:
			stale = action
			break
	if not stale.is_empty():
		var energy := world.player_stats.energy
		world.player_stats.energy = 0
		check(not await api.execute(stale), "Live cost revalidation rejects stale play")
		world.player_stats.energy = energy
	var hand := world.player_handler.player_hand
	var hand_before := hand.get_child_count()
	hand.add_card(load("res://resources/data/cards/riftwalker/sever_anchor.tres").duplicate())
	for action in api.legal_actions():
		if action.kind == "play_card" and action.card == "sever_anchor" and action.obelisk:
			var energy_before := world.player_stats.energy
			var discarded_before := world.player_stats.discard.cards.size()
			check(await api.execute(action), "Custom card executes through authoritative interface")
			check(world.player_stats.energy == energy_before - int(action.cost) + 1, "Sever Anchor pays its cost and grants the existing first Obelisk hit bonus")
			check(world.player_stats.discard.cards.size() == discarded_before + 1, "Custom card emits one pile commit")
			check(hand.get_child_count() == hand_before, "Played card leaves hand before presentation completes")
			break
	var obelisk := get_tree().get_first_node_in_group("obelisk") as Obelisk
	check(obelisk != null, "Encounter contains active Obelisk")
	if obelisk:
		obelisk.stats.health = 0
		check(not obelisk.spawn_random_enemy(), "Dead Obelisk cannot summon")
		Events.enemy_died.emit(obelisk)
		obelisk.do_death()
	await get_tree().create_timer(0.15).timeout
	check(not world.battle_over_handled and world.battle_state.battle_active, "Obelisk destruction with surviving hostiles does not win")
	var enemy := world.enemy_handler.get_child(0) as Enemy
	var attack := load("res://scenes/enemy/bat/bat_enemy_attack_action.gd").new() as EnemyAction
	attack.enemy = enemy
	attack.target = world.player
	enemy.add_child(attack)
	var old_pos := world.tilemap.player_position
	world.tilemap.player_position = Vector2i(-999, -999)
	check(not attack.is_eligible(), "Melee cannot attack across the board")
	world.tilemap.player_position = old_pos
	attack.queue_free()
	for node in world.enemy_handler.get_children():
		if node is MovingEnemy:
			check(not node.set_movement_target(world.tilemap.player_position), "Movement rejects occupied player hex")
			check(node._find_path(node.current_tile_position, node.current_tile_position).size() == 1, "No-op path cannot create movement oscillation")
		if node is Enemy:
			node.take_damage(9999, Enums.ModifierType.NO_MODIFIER, true)
	await get_tree().create_timer(0.2).timeout
	check(world.victory_committed and world.battle_over_handled, "Elimination wins after damage/death resolution")
	world.check_victory()
	check(world.victory_committed, "Victory guard remains committed")
	world.queue_free()
	relics.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	await Utils.stop_audio_for_shutdown()
	for audio: Node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		check(not (audio as AudioStreamPlayer).playing and (audio as AudioStreamPlayer).stream == null,
			"Shutdown releases pooled audio streams before the audio server stops")
	print("Combat automation tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)

func _test_enemy_turn_cancellation(world: GameWorld) -> void:
	var handler := world.enemy_handler
	var enemy := handler.get_child(0) as Enemy
	var previous_action := enemy.current_action
	var action := CountingAction.new()
	enemy.add_child(action)
	enemy.current_action = action
	var previous_block := enemy.stats.block
	enemy.stats.block = 17
	world.battle_state.phase = BattleStateController.Phase.ENEMY_TURN
	handler.start_turn()
	world.battle_state.end_battle()
	check(handler.active_enemy == null, "Ending battle cancels its active enemy")
	check(enemy.phantom_camera_2d.priority == 0, "Cancellation releases the enemy camera")
	await get_tree().process_frame
	await get_tree().process_frame
	check(enemy.stats.block == 17 and action.calls == 0, "Battle ending during camera wait prevents turn effects")
	handler.cancel_turn()
	enemy.stats.block = previous_block
	world.battle_state.start_battle()
	enemy.current_action = action

	handler.active_enemy = enemy
	handler._on_enemy_statuses_applied(Enums.StatusType.START_OF_TURN, enemy)
	handler.cancel_turn()
	handler.active_enemy = enemy
	await get_tree().process_frame
	await get_tree().process_frame
	check(action.calls == 0, "Old start-status callback cannot act in a restarted activation of the same enemy")
	handler._on_enemy_statuses_applied(Enums.StatusType.START_OF_TURN, enemy)
	await get_tree().process_frame
	await get_tree().process_frame
	check(action.calls == 1, "Current start-status callback still executes one action")

	world.player.pending_effects += 1
	handler._on_enemy_action_completed(enemy)
	await get_tree().process_frame
	handler.cancel_turn()
	handler.active_enemy = enemy
	world.player.pending_effects -= 1
	await get_tree().process_frame
	await get_tree().process_frame
	check(handler.active_enemy == enemy, "Old action completion cannot end a restarted activation")
	handler.cancel_turn()

	var completed := {"count": 0}
	var on_completed := func(): completed.count += 1
	Events.enemy_turn_ended.connect(on_completed)
	handler.active_enemy = enemy
	handler.acting_enemies.assign([enemy])
	handler._on_enemy_statuses_applied(Enums.StatusType.END_OF_TURN, enemy)
	handler.cancel_turn()
	await get_tree().create_timer(EnemyHandler.SPOTLIGHT_POST_DELAY + 0.1).timeout
	check(completed.count == 0, "Cancelled pacing timer cannot emit an extra enemy turn end")
	Events.enemy_turn_ended.disconnect(on_completed)
	world.battle_state.phase = BattleStateController.Phase.ENEMY_TURN
	handler.active_enemy = enemy
	handler.acting_enemies.assign([enemy])
	Events.enemy_action_completed.emit(enemy)
	await get_tree().create_timer(EnemyHandler.SPOTLIGHT_POST_DELAY + 0.1).timeout
	check(world.battle_state.phase == BattleStateController.Phase.PLAYER_TURN and world.current_round == 2,
		"Current action completion and pacing advance to the next player round")
	var ready_deadline := Time.get_ticks_msec() + 2000
	while not world.player_handler.hand_ready and Time.get_ticks_msec() < ready_deadline:
		await get_tree().process_frame
	check(world.player_handler.hand_ready, "Normal enemy completion draws the next hand")
	enemy.current_action = previous_action
	action.queue_free()

func _test_feedback_circuit(world: GameWorld, relics: RelicHandler) -> void:
	var circuit := preload("res://resources/data/relics/feedback_circuit.tres").duplicate()
	var map_connections := Events.map_exited.get_connections().size()
	var card_connections := Events.card_played.get_connections().size()
	var hand_connections := Events.player_hand_drawn.get_connections().size()
	var turn_connections := Events.player_turn_started.get_connections().size()
	var discard_before := world.player_stats.discard.cards.duplicate()
	var blocks: Dictionary = {}
	for enemy: Enemy in world.enemy_handler.get_children():
		blocks[enemy] = enemy.stats.block
		enemy.stats.block = 100
	relics.add_relic(circuit)
	var skill := Card.new()
	skill.card_type = Enums.CardType.SKILL
	Events.card_played.emit(skill.duplicate())
	Events.card_played.emit(skill.duplicate())
	check(circuit.skills_this_turn == 2, "Feedback Circuit counts two skills")
	var draw := DrawEffect.new()
	draw.amount = 1
	draw.execute([world.player])
	while not world.player_handler.hand_ready:
		await get_tree().process_frame
	check(circuit.skills_this_turn == 2, "Extra card draws preserve this turn's Feedback Circuit progress")
	Events.card_played.emit(skill.duplicate())
	await get_tree().create_timer(0.2).timeout
	for enemy: Enemy in blocks:
		check(enemy.stats.block == 95, "Third skill after drawing triggers exactly five Feedback Circuit damage")
	check(circuit.skills_this_turn == 0, "Feedback Circuit resets after its proc")
	Events.card_played.emit(skill.duplicate())
	world.player_handler.start_turn()
	check(circuit.skills_this_turn == 0, "Feedback Circuit resets at turn start before the hand finishes drawing")
	while not world.player_handler.hand_ready:
		await get_tree().process_frame
	Events.card_played.emit(skill.duplicate())
	Events.card_played.emit(skill.duplicate())
	var ui := relics.relics.get_child(relics.relics.get_child_count() - 1) as RelicUI
	ui.free()
	check(Events.map_exited.get_connections().size() == map_connections, "Removing Feedback Circuit releases its map subscription")
	check(Events.card_played.get_connections().size() == card_connections, "Removing Feedback Circuit releases its card subscription")
	check(Events.player_hand_drawn.get_connections().size() == hand_connections, "Removing Feedback Circuit releases its draw subscription")
	check(Events.player_turn_started.get_connections().size() == turn_connections, "Removing Feedback Circuit releases its turn subscription")
	check(circuit.relic_ui == null, "Removed Feedback Circuit releases its UI reference")
	relics.add_relic(circuit)
	Events.card_played.emit(skill.duplicate())
	check(circuit.skills_this_turn == 1, "Reacquired Feedback Circuit starts fresh with one subscription")
	ui = relics.relics.get_child(relics.relics.get_child_count() - 1) as RelicUI
	ui.free()
	world.player_stats.discard.cards.assign(discard_before)
	for enemy: Enemy in blocks:
		enemy.stats.block = blocks[enemy]

func _test_instability_costs(world: GameWorld, relics: RelicHandler) -> void:
	var emulator := preload("res://resources/data/relics/instability_emulator.tres").duplicate()
	var energy := world.player_stats.energy
	var rng_state := RNG.instance.state
	var costs: Dictionary = {}
	for ui: CardUI in world.player_handler.player_hand.get_cards():
		costs[ui] = ui.card.energy_cost
	relics.add_relic(emulator)
	world.player_stats.energy = 0
	var saw_free_card := false
	var saw_paid_card := false
	for previous_cost: int in [10, 0]:
		for ui: CardUI in costs:
			ui.card.energy_cost = previous_cost
			ui._on_char_stats_changed()
		Events.player_hand_drawn.emit()
		if previous_cost == 0 and DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--capture-ui"):
			await get_tree().create_timer(0.25).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://relic-costs.png")
		for ui: CardUI in costs:
			saw_free_card = saw_free_card or ui.card.energy_cost == 0
			saw_paid_card = saw_paid_card or ui.card.energy_cost > 0
			check(ui.playable == world.player_stats.can_play_card(ui.card), "Instability Emulator refreshes affordability after changing a card's cost")
			if ui.card.energy_cost == 0:
				ui._on_mouse_entered()
				var press := InputEventMouseButton.new()
				press.button_index = MOUSE_BUTTON_LEFT
				press.pressed = true
				ui._on_gui_input(press)
				check(ui.card_state_machine.current_state.state == CardState.State.CLICKED, "Randomized free card can be selected with the mouse")
				var release := InputEventMouseButton.new()
				release.button_index = MOUSE_BUTTON_LEFT
				ui._input(release)
				ui._on_mouse_exited()
	check(saw_free_card and saw_paid_card, "Cost randomization exercised both free and unaffordable cards")
	var ui := relics.relics.get_child(relics.relics.get_child_count() - 1) as RelicUI
	ui.free()
	for card_ui: CardUI in costs:
		card_ui.card.energy_cost = costs[card_ui]
	world.player_stats.energy = energy
	RNG.instance.state = rng_state

func _test_projectile_ownership() -> void:
	var projectile := ProjectileFX.new()
	var impact := preload("res://ui/fx/explosion_fx.tscn").instantiate() as VisualFX
	projectile.visual_fx = impact
	projectile.free()
	check(not is_instance_valid(impact), "Skipped projectile frees its unattached impact particles")
	var target := Node2D.new()
	projectile = ProjectileFX.new()
	impact = VisualFX.new()
	projectile.visual_fx = impact
	target.add_child(impact)
	projectile.free()
	check(is_instance_valid(impact), "Projectile teardown preserves an impact already owned by its target")
	target.free()
	var config := CardEffectConfig.new()
	config.projectile_fx = preload("res://ui/fx/fireball_projectile_fx.tscn")
	config.projectile_visual_fx = preload("res://ui/fx/explosion_fx.tscn")
	var orphan_count := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	check(CardFxRunner.new()._spawn_projectile(config, null, null) == null,
		"Projectile creation without a valid parent fails safely")
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphan_count,
		"Failed projectile creation does not orphan its projectile or impact")
