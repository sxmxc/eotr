extends Node

const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
const Interface = preload("res://scripts/autowalker/core/gameplay_interface.gd")
var failures := 0

func _ready() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
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
	check(api.ready_for_action(), "Hand/turn resolves to a legal action boundary")
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
	print("Combat automation tests: %d failures" % failures)
	get_tree().quit(1 if failures else 0)
