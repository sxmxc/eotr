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

func _test_visual_lifetimes(world: GameWorld) -> void:
	var frame := Node2D.new()
	frame.position = Vector2(37, -19)
	frame.scale = Vector2(1.4, 1.4)
	frame.rotation = 0.3
	add_child(frame)
	var projectile_scene := load("res://ui/fx/electric_arc_projectile_fx.tscn") as PackedScene
	var first := projectile_scene.instantiate() as ProjectileFX
	var second := projectile_scene.instantiate() as ProjectileFX
	frame.add_child(first)
	frame.add_child(second)
	var target := world.enemy_handler.get_child(0) as Enemy
	first.execute(target, world.player)
	second.execute(world.player, target)
	var arc_a := first.get_node("ElectricArcFX") as Line2D
	var arc_b := second.get_node("ElectricArcFX") as Line2D
	check(arc_a.material != arc_b.material, "Overlapping arcs own independent materials")
	check(arc_a.to_global(arc_a.points[0]).is_equal_approx(world.player.get_node("SpellOrigin").global_position), "Arc origin respects transformed parent")
	check(arc_b.to_global(arc_b.points[0]).is_equal_approx(target.get_node("SpellOrigin").global_position), "Enemy arc respects explicit source")
	arc_a.set_shader_value(0.6)
	check(is_equal_approx(float(arc_a.material.get_shader_parameter("transparency")), 0.6), "Arc fade writes the actual shader uniform")
	var shield := load("res://ui/fx/shield_shine_fx.tscn").instantiate() as VisualFX
	world.player.add_child(shield)
	shield.execute()
	var transients: Array[WeakRef] = []
	var nodes_before := get_tree().get_node_count()
	for i in range(16):
		var burst := load("res://ui/fx/spark_fx.tscn").instantiate() as VisualFX
		var anchor: Node2D = world.player if i % 2 == 0 else target
		anchor.add_child(burst)
		burst.execute()
		transients.append(weakref(burst))
	var wisp := load("res://ui/fx/summon_wisp_fx.tscn").instantiate() as VisualFX
	target.add_child(wisp)
	wisp.execute()
	transients.append(weakref(wisp))
	print("Visual overlap: 16 x 12 impact particles + 8 summon particles; temporary nodes=", get_tree().get_node_count() - nodes_before)
	if DisplayServer.get_name() != "headless":
		world.tilemap.hide_fog()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		if get_viewport().use_hdr_2d:
			for y in image.get_height():
				for x in image.get_width():
					image.set_pixel(x, y, image.get_pixel(x, y).linear_to_srgb())
		image.convert(Image.FORMAT_RGBA8)
		image.save_png("res://overhaul-vfx-overlap.png")
	await get_tree().create_timer(1.2).timeout
	for transient: WeakRef in transients:
		check(transient.get_ref() == null, "Overlapping particle effect is freed, including in headless mode")
	check(not is_instance_valid(first) and not is_instance_valid(second), "Completed arc wrappers are freed")
	check(not is_instance_valid(shield), "Completed shield shine root is freed")
	frame.queue_free()
	await _test_illustrated_families(world, target)


func _test_illustrated_families(world: GameWorld, target: Enemy) -> void:
	var transient_refs: Array[WeakRef] = []
	target.circle_indicator.show()
	for family: String in ["arrow_up", "burn", "curse", "flash", "smoke", "shield_shine", "claw_slash", "explosion", "ember_burst", "slash", "impact_decal"]:
		var fx := load("res://ui/fx/%s_fx.tscn" % family).instantiate() as VisualFX
		target.add_child(fx)
		fx.execute()
		transient_refs.append(weakref(fx))
		if DisplayServer.get_name() != "headless":
			await get_tree().create_timer(0.10).timeout
			var marker_width: float = target.circle_indicator.global_transform.get_scale().abs().x * target.circle_indicator.texture.get_width()
			check(marker_width <= float(world.tilemap.base_layer.tile_set.tile_size.x) * 1.125, "Animated target marker stays within one hex rather than expanding over neighbors")
			await RenderingServer.frame_post_draw
			var shot := get_viewport().get_texture().get_image()
			if get_viewport().use_hdr_2d:
				for y in shot.get_height():
					for x in shot.get_width():
						shot.set_pixel(x, y, shot.get_pixel(x, y).linear_to_srgb())
			shot.convert(Image.FORMAT_RGBA8)
			shot.save_png("res://overhaul-fx-%s.png" % family)
		await get_tree().create_timer(0.45).timeout
	for family: String in ["electric_arc_projectile", "fireball_projectile", "fireball_small_projectile", "obelisk_projectile"]:
		var projectile := load("res://ui/fx/%s_fx.tscn" % family).instantiate() as ProjectileFX
		world.add_child(projectile)
		projectile.execute(target, world.player)
		transient_refs.append(weakref(projectile))
		if DisplayServer.get_name() != "headless":
			await get_tree().create_timer(0.06).timeout
			if family == "electric_arc_projectile":
				check(is_instance_valid(projectile), "Arc survives long enough to display its inked strike")
				if is_instance_valid(projectile):
					var line: Line2D = projectile.get_node("ElectricArcFX")
					var fade := float(line.material.get_shader_parameter("transparency"))
					check(fade > 0.0 and fade < 1.0, "Arc fade interpolates continuously instead of stepping integer endpoints")
			await RenderingServer.frame_post_draw
			var shot := get_viewport().get_texture().get_image()
			if get_viewport().use_hdr_2d:
				for y in shot.get_height():
					for x in shot.get_width():
						shot.set_pixel(x, y, shot.get_pixel(x, y).linear_to_srgb())
			shot.convert(Image.FORMAT_RGBA8)
			shot.save_png("res://overhaul-fx-%s.png" % family)
		await get_tree().create_timer(1.6).timeout
	var ward := load("res://ui/fx/shield_shine_fx.tscn").instantiate() as VisualFX
	ward.set("persistent", true)
	world.player.add_child(ward)
	for replay in 2:
		ward.execute()
		await get_tree().create_timer(0.5).timeout
		check(is_instance_valid(ward) and not ward.visible, "Persistent ward hides after playback and can replay")
	ward.queue_free()
	target.circle_indicator.hide()
	await get_tree().create_timer(4.0).timeout
	for reference: WeakRef in transient_refs:
		check(reference.get_ref() == null, "Illustrated effect or projectile releases its root after playback")


func _ready() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _test_battlefield_presentation(world: GameWorld) -> void:
	var board := world.tilemap
	check(board.base_layer.tile_set.tile_size == Vector2i(64, 64), "Battle uses 64px hex geometry")
	check(board.fog_layer.tile_set.tile_size == board.base_layer.tile_set.tile_size, "Fog shares board geometry")
	check(board.highlight_layer.tile_set.tile_size == board.base_layer.tile_set.tile_size, "Movement highlights share board geometry")
	var previous_layer := TileMapLayer.new()
	previous_layer.tile_set = board.base_layer.tile_set.duplicate()
	previous_layer.tile_set.tile_size = Vector2i(32, 32)
	for cell: Vector2i in board.tile_map_data:
		check(board.world_to_cell(board.cell_to_world(cell)) == cell, "Cell/world conversion round trips")
		check(board.cube_to_offset(board.offset_to_cube(cell)) == cell, "Logical cube conversion unchanged")
		check(board.base_layer.get_surrounding_cells(cell) == previous_layer.get_surrounding_cells(cell), "Migration preserves existing adjacency")
	previous_layer.free()
	check(is_equal_approx(world.player.sprite_2d.scale.x, 0.175), "Player uses readable illustration scale")
	check(world.player.sprite_2d.material != null, "Player has a persistent silhouette shader")
	for unit: Node2D in [world.player, board.obelisk]:
		var sprite := unit.get_node("Sprite2D") as Sprite2D
		var image := sprite.texture.get_image()
		if image.is_compressed():
			image.decompress()
		var bottom := float(image.get_used_rect().end.y) - image.get_height() * 0.5
		var contact := sprite.to_global(Vector2(0, bottom) + sprite.offset)
		check(contact.distance_to(unit.global_position) < 0.1, "Art contact rests at the occupied hex center")
		check(unit.get_node("GroundPresence").global_position.is_equal_approx(unit.global_position), "Ground ring shares the logical tile center")
	await get_tree().physics_frame
	for unit: Node2D in [world.player, board.obelisk]:
		var query := PhysicsPointQueryParameters2D.new()
		query.position = unit.get_node("ImpactAnchor").global_position
		query.collision_mask = 8
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hits := unit.get_world_2d().direct_space_state.intersect_point(query)
		check(hits.any(func(hit: Dictionary): return hit.collider == unit.get_node("Area2D")), "Illustration picking covers the visible body anchor")
	var camera = world.world_camera
	camera.frame_battle(true)
	check(camera.zoom.x <= camera.fit_zoom() + 0.001, "Overview fits actual board into HUD safe area")
	var overview_zoom: float = camera.zoom.x
	camera.frame_battle()
	check(camera.zoom.x + 0.001 >= camera.TACTICAL_MIN and camera.zoom.x >= overview_zoom, "Tactical framing preserves readable entities")
	var center: Vector2 = board.center_marker.global_position
	camera.aiming = true
	camera.frame_battle(true)
	check(board.center_marker.global_position == center and not camera.overview, "Aiming prevents automatic reframing")
	camera.aiming = false
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	check((screen_center - camera.follow_offset * camera.zoom).is_equal_approx(camera.combat_rect().get_center()), "Camera centers within actual HUD safe area")
	check(camera.priority > world.player.phantom_camera_2d.priority, "Tactical Phantom Camera remains authoritative")
	if not OS.get_cmdline_user_args().has("--battlefield-only"):
		board.hide_fog()
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--battlefield-only"):
		await get_tree().create_timer(1.0).timeout
		var projected_center: Vector2 = world.map_camera.get_canvas_transform() * board.center_marker.global_position
		check(projected_center.distance_to(camera.combat_rect().get_center()) < 3.0, "Rendered camera centers the board in the HUD safe area")
		await RenderingServer.frame_post_draw
		var shot := get_viewport().get_texture().get_image()
		if get_viewport().use_hdr_2d:
			for y in shot.get_height():
				for x in shot.get_width():
					shot.set_pixel(x, y, shot.get_pixel(x, y).linear_to_srgb())
		shot.convert(Image.FORMAT_RGBA8)
		shot.save_png("res://battlefield.png")

func _capture_battle(path: String) -> void:
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	if get_viewport().use_hdr_2d:
		for y in shot.get_height():
			for x in shot.get_width():
				shot.set_pixel(x, y, shot.get_pixel(x, y).linear_to_srgb())
	shot.convert(Image.FORMAT_RGBA8)
	shot.save_png(path)

func _test_harvest_state(world: GameWorld) -> void:
	var board := world.tilemap
	var cell := board.player_position
	var data := board.get_tile_data(cell)
	var previous_type := data.type
	var previous_count := data.resource_count
	var previous_atlas := board.base_layer.get_cell_atlas_coords(cell)
	var resources := world.run_stats.resources
	data.type = Enums.TileType.RESOURCE
	board.set_resource_count(cell, 3)
	var target := TilemapTarget.new(cell, board)
	add_child(target)
	var card := load("res://resources/data/cards/riftwalker/echo_harvest.tres") as Card
	var resolver := CardResolver.new()
	await resolver.resolve(card, [target], world.player_stats, world.player.modifier_handler, card.effect_configs)
	check(world.run_stats.resources == resources + 3, "Harvest grants the actual deposit, not a zero config amount")
	check(board.get_resource_count(cell) == 0, "Harvest consumes the finite deposit")
	check(board.base_layer.get_cell_atlas_coords(cell) == board.RESOURCE_USED_ID, "Harvest changes to depleted terrain")
	await resolver.resolve(card, [target], world.player_stats, world.player.modifier_handler, card.effect_configs)
	check(world.run_stats.resources == resources + 3, "A depleted deposit cannot be harvested twice")
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--battlefield-only"):
		await get_tree().create_timer(0.08).timeout
		await _capture_battle("res://battlefield-harvest.png")
	data.type = previous_type
	board.set_resource_count(cell, previous_count)
	board.base_layer.set_cell(cell, 0, previous_atlas)
	world.run_stats.resources = resources
	Events.tile_selected.emit(data)
	target.queue_free()

func _test_spell_readability(world: GameWorld) -> void:
	await get_tree().create_timer(1.1).timeout
	var target := world.tilemap.obelisk
	var previous_block := target.stats.block
	var card := load("res://resources/data/cards/riftwalker/arcane_bolt.tres") as Card
	var resolver := CardResolver.new()
	resolver.resolve(card, [target], world.player_stats, world.player.modifier_handler, card.effect_configs)
	await get_tree().create_timer(0.12).timeout
	await _capture_battle("res://battlefield-spell.png")
	await get_tree().create_timer(0.8).timeout
	check(target.sprite_2d.material != null and target.sprite_2d.material.shader.resource_path.ends_with("unit_outline.gdshader"), "Hit flash preserves the silhouette shader")
	target.stats.block = previous_block
	await _test_spell_identities(world)

func _test_spell_identities(world: GameWorld) -> void:
	var fixture := Node2D.new()
	world.add_child(fixture)
	var samples: Array[String] = ["phase_slash", "arcane_explosion", "arcane_flame", "corrosion_wave", "void_surge", "nano_shield"]
	var names: Array[String] = ["PHASE CUT", "PRESSURE", "FLAME", "CORROSION", "VOID", "NANO WARD"]
	var inverse := world.map_camera.get_canvas_transform().affine_inverse()
	var rect: Rect2 = world.world_camera.combat_rect()
	var refs: Array[WeakRef] = []
	for i in samples.size():
		var anchor := Node2D.new()
		fixture.add_child(anchor)
		anchor.global_position = inverse * Vector2(rect.position.x + 105.0 + float(i) * (rect.size.x - 210.0) / 5.0, rect.get_center().y)
		anchor.scale = Vector2.ONE * 0.65
		var fx := load("res://ui/fx/%s_signature.tscn" % samples[i]).instantiate() as VisualFX
		fx.set("duration", 0.9)
		anchor.add_child(fx)
		fx.execute()
		refs.append(weakref(fx))
		var label := Label.new()
		label.theme = load("res://resources/themes/rift_ui.tres")
		label.theme_type_variation = &"BodySmall"
		label.text = names[i]
		label.z_index = 20
		label.position = Vector2(-50, -100)
		anchor.add_child(label)
	await get_tree().create_timer(0.34).timeout
	await _capture_battle("res://spell-identities.png")
	await get_tree().create_timer(0.8).timeout
	for reference in refs:
		check(reference.get_ref() == null, "Distinct spell signatures finish and release their nodes")
	fixture.queue_free()
	# Exercise the real card resolver for all three distinct projectile paths.
	for id: String in ["overload_shot", "sever_anchor", "void_shard"]:
		var card := load("res://resources/data/cards/riftwalker/%s.tres" % id) as Card
		card.last_energy_cost = 3
		await card.resolve_effects([world.tilemap.obelisk], world.player_stats, world.player.modifier_handler)
		await get_tree().create_timer(0.6).timeout

func _test_gate_presentation(world: GameWorld) -> void:
	var board := world.tilemap
	var origin := board.player_position
	var destination := origin
	for cell in board.get_tiles_of_type(Enums.TileType.RIFT_GATE):
		if board.is_tile_free(cell):
			destination = cell
			break
	if destination == origin:
		return
	var tile_count := board.tile_map_data.size()
	board.teleport_player(destination)
	await get_tree().create_timer(0.3).timeout
	check(board.player_position == destination and board.world_to_cell(world.player.global_position) == destination, "Teleport feedback preserves the authoritative destination")
	check(board.tile_map_data.size() == tile_count, "Gate activation does not change terrain occupancy")
	board.teleport_player(origin)
	await get_tree().create_timer(0.3).timeout
	for cell: Vector2i in board.target_highlight_layer.gates:
		check(board.target_highlight_layer.gates[cell].visible == not board.is_tile_behind_fog(cell), "Rift gate effects respect fog visibility")

func run() -> void:
	_test_authored_encounters()
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
	if OS.get_cmdline_user_args().has("--battlefield-only"):
		var hud = load("res://ui/run_ui/run_hud.tscn").instantiate()
		add_child(hud)
		hud.bind_run(world.player_stats, world.run_stats)
	await get_tree().create_timer(0.2).timeout
	var api := Interface.new()
	api.world = world
	var ready_deadline := Time.get_ticks_msec() + 2000
	while not api.ready_for_action() and Time.get_ticks_msec() < ready_deadline:
		await get_tree().process_frame
	check(api.ready_for_action(), "Hand/turn resolves to a legal action boundary")
	await _test_battlefield_presentation(world)
	await _test_harvest_state(world)
	if OS.get_cmdline_user_args().has("--battlefield-only"):
		await _test_gate_presentation(world)
		if DisplayServer.get_name() != "headless":
			await _test_spell_readability(world)
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	await _test_visual_lifetimes(world)
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

func _test_authored_encounters() -> void:
	# The isolated validation project does not link documentation. Load every card
	# through its actual Resource path rather than relying on a file existing.
	for folder in ["res://resources/data/cards/riftwalker", "res://resources/data/cards/common"]:
		for filename in DirAccess.get_files_at(folder):
			if filename.ends_with(".tres"):
				var card := load(folder.path_join(filename)) as Card
				check(card.card_art != null and card.card_art.resource_path == "res://assets/rift/cards/%s.webp" % filename.get_basename(), "Every loaded card binds its own illustration after its script")
				if card.card_art:
					check(card.card_art.get_width() == 592 and card.card_art.get_height() == 396, "Cards use a high resolution 3:2 illustration")
	var registry: EncounterRegistry = load("res://resources/data/registries/encounter_registry_act1.tres")
	check(registry.encounters.size() == 27, "All existing and twenty new authored encounters are registered")
	var ids: Array[String] = []
	var new_profiles: Dictionary = {}
	for definition in registry.encounters:
		check(not definition.encounter_id.is_empty() and not ids.has(definition.encounter_id), "Stable encounter IDs are unique")
		ids.append(definition.encounter_id)
		var composition := definition.enemies.instantiate()
		var obelisks := 0
		for child in composition.get_children():
			check(child is Enemy and child.stats != null and child.stats.ai != null, "Authored enemy has stats and AI")
			if child is Obelisk:
				obelisks += 1
			if child is Enemy and child.stats.tactics:
				new_profiles[child.stats.enemy_name] = true
		check(obelisks == 1, "Every encounter retains one active Obelisk")
		check(definition.victory_objective == EncounterDefinition.VictoryObjective.ELIMINATE_HOSTILES, "Default victory requires every hostile")
		composition.free()
	check(new_profiles.size() == 20, "Eight new bases and twelve variants appear in playable compositions")
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	var recent: Array[String] = []
	for i in 100:
		var normal := registry.select(0, [EncounterDefinition.Category.NORMAL], [], recent, "", rng)
		check(normal != null and normal.battle_tier == 0 and normal.category == EncounterDefinition.Category.NORMAL, "Tier/category eligibility is exact")
		check(not recent.has(normal.encounter_id), "Available alternatives prevent immediate repeats")
		recent = [normal.encounter_id]
		var boss := registry.select(2, [EncounterDefinition.Category.BOSS], [], [], "", rng)
		check(boss != null and boss.battle_tier == 2 and boss.category == EncounterDefinition.Category.BOSS, "Tier two authored boss pool is preserved")
	check(registry.select(9, [0]) == null, "Empty pools do not fall back to unrelated content")
	check(registry.select(0, [0], [], [], "tier_2_bulwark_channelers") == registry.find("tier_2_bulwark_channelers"), "Explicit node override selects an authored encounter")
	check(registry.select(0, [0], [], [], "missing") == null, "Unknown override fails explicitly")

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
