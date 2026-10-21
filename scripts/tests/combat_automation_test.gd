extends Node

const WORLD = preload("res://scenes/game_world/game_world.tscn")
const RELICS = preload("res://scenes/relic_handler/relic_handler.tscn")
const Interface = preload("res://scripts/autowalker/core/gameplay_interface.gd")
var failures := 0

class CountingStatus extends Status:
	var calls := 0

	func apply_status(_target: Node) -> void:
		calls += 1
		status_applied.emit(self)

class CountingRelic extends Relic:
	var calls := 0
	var on_activate: Callable

	func activate_relic(_owner: RelicUI) -> void:
		calls += 1
		if on_activate.is_valid():
			on_activate.call()

class CountingAction extends EnemyAction:
	var calls := 0

	func is_eligible() -> bool:
		return true

	func perform_action() -> void:
		calls += 1

	func update_intent_text() -> void:
		pass

func _test_combatant_wards(world: GameWorld) -> void:
	world.tilemap.hide_fog()
	var enemy := world.enemy_handler.get_child(0) as Enemy
	var refs: Array[WeakRef] = []
	var original_blocks: Array[int] = [world.player.stats.block, enemy.stats.block]
	for combatant: Node2D in [world.player, enemy]:
		var before: int = combatant.stats.block
		var block := BlockEffect.new()
		block.amount = 4
		block.visual_fx = preload("res://ui/fx/eldritch_barrier_signature.tscn")
		block.execute([combatant])
		check(combatant.stats.block == before + 4, "Ward grants block to both combatant types")
		var fx := combatant.get_node("EldritchBarrierFX")
		refs.append(weakref(fx))
	await get_tree().create_timer(0.22).timeout
	if DisplayServer.get_name() != "headless":
		for ref: WeakRef in refs:
			var fx = ref.get_ref()
			check(fx != null and fx.is_visible_in_tree(), "Combatant ward survives into visible playback")
			if fx:
				check(fx.position == fx.get_parent().get_node("ImpactAnchor").position, "Ward follows combatant impact anchor")
				check(fx.get_node("Illustration").frame > 0, "Combatant ward illustration advances")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://combatant-wards.png")
	await get_tree().create_timer(0.7).timeout
	for ref: WeakRef in refs:
		check(ref.get_ref() == null, "Combatant ward cleans up after playback")
	world.player.stats.block = original_blocks[0]
	enemy.stats.block = original_blocks[1]


func _test_visual_lifetimes(world: GameWorld) -> void:
	var frame := Node2D.new()
	frame.position = Vector2(37, -19)
	frame.scale = Vector2(1.4, 1.4)
	frame.rotation = 0.3
	add_child(frame)
	var projectile_scene := load("res://ui/fx/overload_projectile_fx.tscn") as PackedScene
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
		image.save_png("user://overhaul-vfx-overlap.png")
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
			shot.save_png("user://overhaul-fx-%s.png" % family)
		await get_tree().create_timer(0.45).timeout
	for family: String in ["electric_arc_projectile", "fireball_projectile", "fireball_small_projectile", "obelisk_projectile"]:
		var projectile := load("res://ui/fx/%s_fx.tscn" % family).instantiate() as ProjectileFX
		world.add_child(projectile)
		projectile.execute(target, world.player)
		transient_refs.append(weakref(projectile))
		if DisplayServer.get_name() != "headless":
			await get_tree().create_timer(0.06).timeout
			if family == "electric_arc_projectile":
				check(is_instance_valid(projectile), "Energy bolt survives through its travel window")
				if is_instance_valid(projectile):
					check(projectile.get_node("AnimatedSprite2D").visible, "Energy bolt has an authored visible body during travel")
			await RenderingServer.frame_post_draw
			var shot := get_viewport().get_texture().get_image()
			if get_viewport().use_hdr_2d:
				for y in shot.get_height():
					for x in shot.get_width():
						shot.set_pixel(x, y, shot.get_pixel(x, y).linear_to_srgb())
			shot.convert(Image.FORMAT_RGBA8)
			shot.save_png("user://overhaul-fx-%s.png" % family)
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


func _test_terrain_breakup(world: GameWorld) -> void:
	var board := world.tilemap
	var depth := board.get_node("TerrainDepth")
	var revealed: Dictionary = board.fog_state.duplicate()
	board.fog_state.clear()
	depth._rebuild()
	check(depth.cells.is_empty(), "Fog hides skirts belonging to unrevealed terrain")
	board.fog_state.assign(revealed)
	board.hide_fog()
	board.target_highlight_layer._collapse_changed(1)
	await get_tree().process_frame
	var rng_before := RNG.instance.state
	var cells_before := board.base_layer.get_used_cells().size()
	# Sample actual artwork on an unoccupied visible cell. This fixture simulates
	# erasure, while production shrink_map remains covered by real AutoWalker turns.
	var cell: Vector2i
	for candidate: Vector2i in board.base_layer.get_used_cells():
		if board.is_tile_valid(candidate):
			cell = candidate
			break
	var atlas_coords := board.base_layer.get_cell_atlas_coords(cell)
	var atlas := AtlasTexture.new()
	atlas.atlas = (board.base_layer.tile_set.get_source(0) as TileSetAtlasSource).texture
	atlas.region = Rect2(Vector2(atlas_coords) * 64, Vector2(64, 64))
	var fragment := load("res://scenes/game_world/tile_sprite.tscn").instantiate() as TileSprite
	fragment.texture = atlas
	fragment.position = board.base_layer.map_to_local(cell)
	board.base_layer.add_child(fragment)
	var reference: WeakRef = weakref(fragment)
	fragment.swirl_out()
	check(board.base_layer.get_used_cells().size() == cells_before, "Breakup cannot invalidate a gameplay tile")
	if DisplayServer.get_name() != "headless":
		check(fragment.has_node("Shard4") and not fragment.has_node("Shard5"), "Terrain separates into five irregular textured pieces")
	board.base_layer.erase_cell(cell)
	board.presentation_changed.emit()
	await get_tree().create_timer(0.22).timeout
	check(board.base_layer.get_cell_source_id(cell) == -1, "Cell invalidation removes its artwork immediately")
	if DisplayServer.get_name() != "headless":
		check(reference.get_ref() != null, "Cosmetic debris outlives immediate cell invalidation")
	await _capture_battle("user://terrain-collapse.png")
	await get_tree().create_timer(0.6).timeout
	check(reference.get_ref() == null, "All breakup geometry releases within 0.82 seconds")
	check(RNG.instance.state == rng_before, "Terrain presentation does not consume gameplay RNG")
	board.base_layer.set_cell(cell, 0, atlas_coords)
	board.presentation_changed.emit()
	await get_tree().process_frame
	await _capture_battle("user://terrain-stable.png")
	# Real successive shrinks must erase cells without leaving extra geometry.
	# Clear entities only in this disposable fixture so collapse cannot end the run.
	for enemy in world.enemy_handler.get_children():
		enemy.remove_from_group("enemy")
	board.player_position = Vector2i(-999, -999)
	for shrink in 2:
		var previous_cells := board.base_layer.get_used_cells()
		await board.shrink_map(1)
		await get_tree().process_frame
		check(board.base_layer.get_used_cells().size() < previous_cells.size(), "Shrink %s removes terrain cells" % (shrink + 1))
		for owner_cell: Vector2i in depth.cells:
			check(board.base_layer.get_cell_source_id(owner_cell) != -1, "Every stone skirt belongs to a surviving tile")
		for tile: Vector2i in previous_cells:
			if not board.tile_map_data.has(tile):
				check(board.base_layer.get_cell_source_id(tile) == -1, "Collapsed terrain has no remaining tile artwork")
	await get_tree().create_timer(0.9).timeout
	await _capture_battle("user://terrain-shrunk.png")

func _test_all_signature_lifetimes(world: GameWorld) -> void:
	var directory := DirAccess.open("res://ui/fx")
	var refs: Array[WeakRef] = []
	var count := 0
	for file in directory.get_files():
		if not file.ends_with("_signature.tscn"):
			continue
		var fx := load("res://ui/fx/" + file).instantiate() as VisualFX
		world.player.add_child(fx)
		fx.execute()
		refs.append(weakref(fx))
		count += 1
		# Crowded burst: exercise materials/lifetimes together, not in 25 runs.
	await get_tree().create_timer(1.2).timeout
	for reference in refs:
		check(reference.get_ref() == null, "Every ability signature releases after overlapping playback")
	print("Validated ability signature lifetimes: ", count)

func _test_projectile_motion(world: GameWorld) -> void:
	var frame := Node2D.new()
	frame.rotation = 0.3
	frame.scale = Vector2(1.4, 1.4)
	world.add_child(frame)
	var bolt := load("res://ui/fx/electric_arc_projectile_fx.tscn").instantiate() as ProjectileFX
	frame.add_child(bolt)
	var source := world.player.get_node("SpellOrigin") as Node2D
	var target := world.tilemap.obelisk.get_node("ImpactAnchor") as Node2D
	var completed: Array[bool] = [false]
	bolt.complete.connect(func(): completed[0] = true)
	bolt.execute(world.tilemap.obelisk, world.player)
	check(bolt.global_position.is_equal_approx(source.global_position), "Moving bolt releases at the true world SpellOrigin")
	check(absf(angle_difference(bolt.global_rotation, (target.global_position - source.global_position).angle())) < 0.001, "Moving bolt orientation respects transformed parents")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not completed[0] and bolt.global_position.distance_to(source.global_position) > 0.1, "Energy body moves before impact; completion is tied to arrival")
	await get_tree().create_timer(0.4).timeout
	check(completed[0] and not is_instance_valid(bolt), "Fast projectile completes and frees its wake within 0.4 seconds")
	frame.queue_free()

func _test_projectile_cancellation(world: GameWorld) -> void:
	var projectile := load("res://ui/fx/fireball_projectile_fx.tscn").instantiate() as ProjectileFX
	var impact := load("res://ui/fx/jab_signature.tscn").instantiate() as VisualFX
	projectile.visual_fx = impact
	var reference: WeakRef = weakref(impact)
	world.add_child(projectile)
	# Cancellation before arrival must free the otherwise detached impact.
	projectile.free()
	check(reference.get_ref() == null, "Cancelled flight owns and releases its unattached impact")

func _ready() -> void:
	GameSettings.show_tutorial = false
	TelemetryManager.suspended = true
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _test_battlefield_presentation(world: GameWorld) -> void:
	var resolving_intent := Intent.new()
	resolving_intent.tooltip_text = "Attack for %s"
	resolving_intent.current_text = "%s"
	check(resolving_intent.get_display_text() == "Attack" and not resolving_intent.get_description().contains("%s"), "Resolving intent never exposes a formatting placeholder")
	resolving_intent.current_text = "6"
	check(resolving_intent.get_display_text() == "6" and resolving_intent.get_description().contains("6"), "Resolved intent preserves its actual amount")
	var board := world.tilemap
	check(board.base_layer.tile_set.tile_size == Vector2i(64, 64), "Battle uses 64px hex geometry")
	check(board.fog_layer.tile_set.tile_size == board.base_layer.tile_set.tile_size, "Fog shares board geometry")
	check(board.highlight_layer.tile_set.tile_size == board.base_layer.tile_set.tile_size, "Movement highlights share board geometry")
	if DisplayServer.get_name() != "headless":
		board.hide_fog()
		var overlay := board.target_highlight_layer
		var highlighted_cells: Array[Vector2i] = [board.player_position]
		overlay.show_target_highlights(highlighted_cells)
		check(overlay.active_target_highlights.size() == 1, "Target overlay includes an occupied legal hex")
		if overlay.active_target_highlights.size() == 1:
			var highlight: Sprite2D = overlay.active_target_highlights[0]
			check(highlight.global_position.is_equal_approx(board.cell_to_world(board.player_position)), "Target mask center matches the authoritative TileMap world center")
			check(highlight.texture.get_size() == Vector2(64, 64) and highlight.scale == Vector2.ONE, "Target mask uses exact canonical tile dimensions without compensating scale")
			highlight.material.set_shader_parameter("HighlightColor", Color(0.29, 0.75, 0.67, 1))
		await _capture_battle("user://target-alignment.png")
		overlay.clear_target_highlights()
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
		shot.save_png("user://battlefield.png")

func _capture_battle(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
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
		await _capture_battle("user://battlefield-harvest.png")
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
	await _capture_battle("user://battlefield-spell.png")
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
	await _capture_battle("user://spell-identities.png")
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

func _observe_card_play(card_ui: CardUI, result: Dictionary) -> void:
	await card_ui.play()
	result.completed = true

func _test_ruin_feedback(world: GameWorld) -> void:
	var board := world.tilemap
	var cell := board.player_position
	var old_type := board.tile_map_data[cell].type
	var old_effects := board.ruin_tile_effects.duplicate()
	var old_block := world.player_stats.block
	var messages: Array[String] = []
	var on_message := func(data: WorldMessageData): messages.append(data.message)
	Events.world_message_requested.connect(on_message)
	board.tile_map_data[cell].type = Enums.TileType.ANCIENT_RUIN
	board.ruin_tile_effects.assign([load("res://resources/data/tile_effects/block_tile_effect.tres")])
	board.apply_tile_effects()
	board.apply_tile_effects()
	check(world.player_stats.block == old_block + 20, "Repeated ruin entry preserves both block grants")
	check(messages.size() == 2 and messages[0].begins_with("Ancient Ruin: "), "Each ruin activation identifies its outcome")
	var echoes: Array[WeakRef] = []
	for child in board.target_highlight_layer.get_children():
		if child.scene_file_path == "res://ui/world_ui/ruin_activation.tscn":
			echoes.append(weakref(child))
	check(echoes.size() == 2, "Overlapping ruin activations own separate presentation instances")
	board.ruin_tile_effects.assign([load("res://resources/data/tile_effects/empty_tile_effect.tres")])
	board.apply_tile_effects()
	check(world.player_stats.block == old_block + 20 and messages.back().contains("nothing happens"), "Empty ruins report activation without granting a reward")
	await get_tree().create_timer(0.65).timeout
	for echo: WeakRef in echoes:
		check(echo.get_ref() == null, "Ruin echo releases after playback")
	Events.world_message_requested.disconnect(on_message)
	board.tile_map_data[cell].type = old_type
	board.ruin_tile_effects.assign(old_effects)
	world.player_stats.block = old_block

func _test_lethal_ruin_move(world: GameWorld) -> void:
	var hand := world.player_handler.player_hand
	var move_card := load("res://resources/data/cards/riftwalker/phase_step.tres").duplicate(true) as Card
	hand.add_card(move_card)
	var card_ui := hand.get_cards().back() as CardUI
	var destination := world.tilemap.player_position
	for cell: Vector2i in move_card.get_valid_targets(card_ui, world.player.modifier_handler):
		if world.tilemap.is_tile_valid(cell):
			destination = cell
			break
	check(destination != world.tilemap.player_position, "Lethal ruin regression has a legal move destination")
	world.tilemap.tile_map_data[destination].type = Enums.TileType.ANCIENT_RUIN
	var ruin_damage := load("res://resources/data/tile_effects/damage_tile_effect.tres").duplicate(true) as RuinTileEffect
	ruin_damage.set("base_amount", 999)
	world.tilemap.ruin_tile_effects.assign([ruin_damage])
	world.player_stats.health = 1
	world.player_stats.block = 0
	var target := TilemapTarget.new(destination, world.tilemap)
	world.add_child(target)
	card_ui.targets.assign([target])
	var on_death := func():
		# Keep the UI alive but detached, matching scene teardown during resolution.
		if is_instance_valid(card_ui) and card_ui.is_inside_tree():
			card_ui.get_parent().remove_child(card_ui)
	Events.player_died.connect(on_death)
	var result := {"completed": false}
	_observe_card_play(card_ui, result)
	await get_tree().create_timer(0.8).timeout
	check(world.player_stats.health <= 0 and world.battle_over_handled, "Moving onto the ruin produces the real lethal tile effect")
	check(not card_ui.is_inside_tree(), "Death cleanup detaches the resolving card UI")
	check(result.completed and not world.player_handler.resolving_action, "Lethal movement exits card resolution and releases the action lock")
	Events.player_died.disconnect(on_death)
	card_ui.free()
	target.queue_free()

func _test_mana_well_presentation(world: GameWorld) -> void:
	var board := world.tilemap
	var occupied := board.player_position
	var empty := occupied
	var best_distance := INF
	for cell: Vector2i in board.tile_map_data:
		if cell != occupied and board.is_tile_valid(cell):
			var distance := board.cell_to_world(cell).distance_to(world.player.global_position)
			if distance < best_distance:
				empty = cell
				best_distance = distance
	check(empty != occupied, "Mana well review has an unoccupied comparison tile")
	var occupied_type := board.tile_map_data[occupied].type
	var empty_type := board.tile_map_data[empty].type
	var energy := world.player_stats.energy
	board.tile_map_data[occupied].type = Enums.TileType.MANA_WELL
	board.tile_map_data[empty].type = Enums.TileType.MANA_WELL
	board.hide_fog()
	board.presentation_changed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var overlay := board.target_highlight_layer
	check(overlay.mana_wells.has(occupied) and overlay.mana_wells.has(empty), "Mana well visuals cover occupied and empty wells")
	check(overlay.mana_wells[occupied].visible and overlay.mana_wells[empty].visible, "Revealed mana wells remain visible under the player")
	check(world.player_stats.energy == energy, "Cosmetic mana well refresh cannot grant energy")
	if DisplayServer.get_name() != "headless":
		world.world_camera.frame_battle()
		await get_tree().create_timer(1.2).timeout
		await _capture_battle("user://mana-wells.png")
	board.fog_state.erase(empty)
	board.presentation_changed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(not overlay.mana_wells[empty].visible, "Mana well visuals cannot reveal fogged terrain")
	board.tile_map_data[occupied].type = occupied_type
	board.tile_map_data[empty].type = empty_type
	board.hide_fog()
	board.presentation_changed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	if empty_type != Enums.TileType.MANA_WELL:
		check(not overlay.mana_wells.has(empty), "Changing terrain removes obsolete mana well visuals")

func _test_board_badges(world: GameWorld) -> void:
	var board := world.tilemap
	board.hide_fog()
	world.world_camera.frame_battle(true)
	await get_tree().create_timer(1.2).timeout
	var enemy := world.enemy_handler.get_child(0) as Enemy
	var badges := enemy.get_node("UnitBadges")
	await get_tree().process_frame
	check(badges.intent_panel.visible and badges.intent_icon.texture != null, "Board shows the enemy's current intent icon")
	check(badges.intent_label.text == enemy.current_action.intent.get_display_text(), "Board intent uses the announced action and amount")
	var duration_status := load("res://resources/data/statuses/burned.tres").duplicate(true) as Status
	duration_status.duration = 3
	enemy.status_handler.add_status(duration_status)
	var intensity_status := Status.new()
	intensity_status.id = "badge_test"
	intensity_status.stack_type = Enums.StatusStackType.INTENSITY
	intensity_status.stacks = 2
	intensity_status.icon = load("res://assets/rift/ui/strength.svg")
	intensity_status.tooltip = "Status display fixture"
	enemy.status_handler.add_status(intensity_status)
	await get_tree().process_frame
	await get_tree().process_frame
	check(badges.chips.has(duration_status) and badges.chips.has(intensity_status), "Board mirrors duration and intensity statuses")
	check(badges.chips[duration_status].count.text == "3" and badges.chips[intensity_status].count.text == "2", "Board distinguishes remaining turns and stack counts")
	intensity_status.stacks = 5
	check(badges.chips[intensity_status].count.text == "5", "Board status counts update when the live resource changes")
	var initial_block := enemy.stats.block
	enemy.stats.block = 7
	await get_tree().process_frame
	check(badges.block_panel.visible and badges.block_label.text == "7", "Board exposes current block separately from planned block")
	if DisplayServer.get_name() != "headless":
		await _capture_battle("user://board-intents-statuses.png")
	duration_status.duration = 0
	intensity_status.stacks = 0
	await get_tree().process_frame
	await get_tree().process_frame
	check(not badges.chips.has(duration_status) and not badges.chips.has(intensity_status), "Expired and depleted statuses disappear from board badges")
	enemy.stats.block = initial_block
	board.fog_state.erase(enemy.current_tile_position)
	await get_tree().physics_frame
	await get_tree().process_frame
	check(not enemy.visible and not badges.is_visible_in_tree(), "Fog hides unit badges with the enemy")
	board.hide_fog()

func _test_camera_follow(world: GameWorld) -> void:
	var camera = world.world_camera
	var board := world.tilemap
	var origin := board.player_position
	var destination := origin
	for cell: Vector2i in board.tile_map_data:
		if cell != origin and board.is_tile_valid(cell):
			destination = cell
			break
	check(destination != origin, "Camera regression has a movement destination")
	camera.frame_battle(true)
	camera._start_pan()
	board.center_marker.global_position += Vector2(120, -80)
	camera.aiming = true
	# Phase Step uses the board movement path while card aiming may still be active.
	board.move_player(destination, false)
	check(not camera.manual and not camera.overview and not camera.dragging, "Movement releases free look even during card resolution")
	check(camera.follow_target == world.player and camera.follow_mode == PhantomCamera2D.FollowMode.SIMPLE, "Movement delegates player tracking to Phantom Camera")
	camera.aiming = false
	await get_tree().create_timer(0.5).timeout
	camera._start_pan()
	check(camera.follow_target == board.center_marker and camera.manual, "Free look can be used again after following the player")
	board.teleport_player(origin)
	check(camera.follow_target == world.player and not camera.manual and not camera.dragging, "Teleport returns free look to native player follow")
	await get_tree().create_timer(1.2).timeout
	if DisplayServer.get_name() != "headless":
		var projected: Vector2 = world.map_camera.get_canvas_transform() * world.player.global_position
		check(projected.distance_to(camera.combat_rect().get_center()) < 8.0, "Native camera follows the teleported player into the HUD safe area")
	camera.frame_battle()

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
	var original_type := board.tile_map_data[origin].type
	board.tile_map_data[origin].type = Enums.TileType.RIFT_GATE
	# Enter through normal movement, exercising overlapping walk/phase animations.
	board.move_player(origin)
	var gate_destination := board.player_position
	await get_tree().create_timer(0.65).timeout
	check(gate_destination != origin, "Entering a gate activates another free gate")
	check(board.world_to_cell(world.player.global_position) == gate_destination, "Gate arrival survives the movement animation")
	board.tile_map_data[origin].type = original_type
	var facing_card := Card.new()
	facing_card.target_type = Enums.TargetType.SINGLE_ENEMY
	var facing_target := Node2D.new()
	add_child(facing_target)
	facing_target.global_position = world.player.global_position + Vector2(-100, 0)
	await facing_card.resolve_effects([facing_target], world.player_stats, world.player.modifier_handler)
	check(world.player.sprite_2d.flip_h, "Targeted cast faces a target to the left")
	facing_target.global_position = world.player.global_position + Vector2(100, 0)
	await facing_card.resolve_effects([facing_target], world.player_stats, world.player.modifier_handler)
	check(not world.player.sprite_2d.flip_h, "Targeted cast faces a target to the right")
	facing_card.target_type = Enums.TargetType.SINGLE_TILE
	var tile_target := TilemapTarget.new(origin, board)
	await facing_card.resolve_effects([tile_target], world.player_stats, world.player.modifier_handler)
	tile_target.free()
	var direction := board.cell_to_world(origin).x - world.player.global_position.x
	if not is_zero_approx(direction):
		check(world.player.sprite_2d.flip_h == (direction < 0.0), "Tile-targeted cast faces the chosen tile")
	facing_target.queue_free()
	board.teleport_player(destination)
	await get_tree().create_timer(0.3).timeout
	check(board.player_position == destination and board.world_to_cell(world.player.global_position) == destination, "Teleport feedback preserves the authoritative destination")
	check(board.tile_map_data.size() == tile_count, "Gate activation does not change terrain occupancy")
	board.teleport_player(origin)
	await get_tree().create_timer(0.3).timeout
	for cell: Vector2i in board.target_highlight_layer.gates:
		check(board.target_highlight_layer.gates[cell].visible == not board.is_tile_behind_fog(cell), "Rift gate effects respect fog visibility")
	var overlay := board.target_highlight_layer
	if not overlay.gates.is_empty():
		var gate_cell: Vector2i = overlay.gates.keys()[0]
		board.tile_map_data[gate_cell].type = Enums.TileType.RESOURCE
		board.presentation_changed.emit()
		await get_tree().process_frame
		check(not overlay.gates.has(gate_cell), "Changing a surviving gate tile removes its obsolete visual")
		board.tile_map_data[gate_cell].type = Enums.TileType.RIFT_GATE
		board.presentation_changed.emit()

func _review_utility_motion(world: GameWorld) -> void:
	var board := world.tilemap
	board.hide_fog()
	world.world_camera.frame_battle()
	await get_tree().create_timer(0.7).timeout
	var origin: Vector2i = board.player_position
	var destination := origin
	for cell: Vector2i in board.base_layer.get_surrounding_cells(origin):
		if board.is_tile_valid(cell) and board.get_tile_data(cell).type == Enums.TileType.RESOURCE:
			destination = cell
			break
	check(destination != origin, "Utility fixture has a legal resource-tile step")
	if destination == origin:
		return
	var card := load("res://resources/data/cards/riftwalker/phase_step.tres") as Card
	var tile_target := TilemapTarget.new(destination, board)
	add_child(tile_target)
	var rng_state := RNG.instance.state
	print("MOTION phase_step frame=", Engine.get_process_frames())
	await card.resolve_effects([tile_target], world.player_stats, world.player.modifier_handler)
	check(board.player_position == destination, "Phase visuals preserve immediate authoritative move commit")
	await get_tree().create_timer(0.085).timeout
	check(RNG.instance.state == rng_state, "Phasing presentation consumes no gameplay RNG before existing move-completion AI replanning")
	var phase := world.player.get_node_or_null("PhaseStepFX")
	check(world.player.sprite_2d.self_modulate.a < 0.15, "Actual player illustration phases out during movement")
	if phase:
		var echo := phase.get_node("EarlyEcho") as Sprite2D
		check(echo.visible and echo.texture == world.player.sprite_2d.texture, "Phase Step samples the actual illustrated player")
		check(echo.global_position.distance_to(world.player.sprite_2d.global_position) > 0.1, "Afterimage remains behind on the actual movement path")
	else:
		check(false, "Phase Step owns its movement feedback")
	await get_tree().create_timer(0.5).timeout
	check(is_equal_approx(world.player.sprite_2d.self_modulate.a, 1.0), "Player phases back in at the destination")
	check(board.world_to_cell(world.player.global_position) == destination and world.player.pending_effects == 0, "Move finishes at the unchanged destination and timing boundary")
	check(not is_instance_valid(phase), "Phase afterimages release their owner")
	tile_target.queue_free()
	for id: String in ["eldritch_barrier", "nano_shield"]:
		print("MOTION ", id, " frame=", Engine.get_process_frames())
		var shield := load("res://ui/fx/%s_signature.tscn" % id).instantiate() as VisualFX
		world.player.add_child(shield)
		shield.execute()
		await get_tree().create_timer(0.22).timeout
		for child in shield.get_children():
			if child is AnimatedSprite2D:
				check(child.self_modulate.a <= 0.42, "Shield plates remain translucent throughout playback")
		await get_tree().create_timer(0.7).timeout
	# Interrupted presentation must never leave the real player invisible.
	tile_target = TilemapTarget.new(origin, board)
	add_child(tile_target)
	await card.resolve_effects([tile_target], world.player_stats, world.player.modifier_handler)
	await get_tree().create_timer(0.07).timeout
	phase = world.player.get_node_or_null("PhaseStepFX")
	if phase:
		phase.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_equal_approx(world.player.sprite_2d.self_modulate.a, 1.0), "Cancelled phasing restores the original sprite opacity")
	await get_tree().create_timer(0.3).timeout
	tile_target.queue_free()

func _review_combat_motion(world: GameWorld) -> void:
	world.tilemap.hide_fog()
	var target := world.tilemap.obelisk
	# Durable fixture only; exercise actual resolver/impact/status consumers.
	target.stats.max_health = 1000
	target.stats.health = 1000
	target.stats.block = 0
	world.player_stats.health = 20
	for enemy: Enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.stats.max_health = 1000
		enemy.stats.health = 1000
	for id: String in ["arcane_bolt", "arcane_blast", "chrono_jab", "phase_slash", "overload_shot", "sever_anchor", "void_shard", "arcane_flame", "corroding_shot", "corrosion_wave", "void_surge", "mana_leech", "eldritch_barrier", "nano_shield", "mana_surge", "focus", "rift_knowledge", "void_fracture"]:
		print("MOTION ", id, " frame=", Engine.get_process_frames())
		var card := load("res://resources/data/cards/riftwalker/%s.tres" % id) as Card
		card._sync_effect_configs()
		card.last_energy_cost = 4
		var targets: Array[Node] = [target]
		if not card.is_single_targeted():
			targets = card._get_targets(targets)
		await card.resolve_effects(targets, world.player_stats, world.player.modifier_handler)
		await get_tree().create_timer(0.65).timeout
	await _test_all_signature_lifetimes(world)
	print("MOTION collapse frame=", Engine.get_process_frames())
	# Keep fixture actors off the destroyed outer ring without changing shrink code.
	for enemy in world.enemy_handler.get_children():
		enemy.remove_from_group("enemy")
	world.tilemap.player_position = Vector2i(-999, -999)
	await world.tilemap.shrink_map(1)
	await get_tree().create_timer(0.9).timeout

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
	if OS.get_cmdline_user_args().has("--attack-cancellation-only"):
		await _test_status_cancellation(world)
		await _test_attack_tween_cancellation(world)
		await _test_movement_cancellation(world)
		await _test_player_shutdown(world, relics)
		world.queue_free()
		relics.queue_free()
		await get_tree().process_frame
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--card-lifecycle-only"):
		await _test_ruin_feedback(world)
		await _test_lethal_ruin_move(world)
		world.queue_free()
		relics.queue_free()
		await get_tree().process_frame
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--mana-wells-only"):
		await _test_mana_well_presentation(world)
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--utility-review"):
		await _test_combatant_wards(world)
		await _review_utility_motion(world)
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--motion-review"):
		await _review_combat_motion(world)
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	if OS.get_cmdline_user_args().has("--terrain-only"):
		await get_tree().create_timer(1.0).timeout
		await _capture_battle("user://terrain-fog.png")
	await _test_battlefield_presentation(world)
	if OS.get_cmdline_user_args().has("--terrain-only"):
		await _test_terrain_breakup(world)
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	await _test_harvest_state(world)
	await _test_camera_follow(world)
	await _test_board_badges(world)
	if OS.get_cmdline_user_args().has("--battlefield-only"):
		await _test_gate_presentation(world)
		if DisplayServer.get_name() != "headless":
			await _test_projectile_motion(world)
			await _test_spell_readability(world)
			await _test_all_signature_lifetimes(world)
		print("Combat automation tests: %d failures" % failures)
		await Utils.stop_audio_for_shutdown()
		get_tree().quit(1 if failures else 0)
		return
	await _test_combatant_wards(world)
	await _test_visual_lifetimes(world)
	await _test_projectile_cancellation(world)
	await _test_enemy_turn_cancellation(world)
	await _test_status_cancellation(world)
	await _test_attack_tween_cancellation(world)
	await _test_movement_cancellation(world)
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
	var registry: EncounterRegistry = load("res://resources/data/registries/encounter_registry_legacy.tres")
	check(registry.encounters.size() == 27, "All existing and twenty new authored encounters are registered")
	var ids: Array[String] = []
	var new_profiles: Dictionary = {}
	for definition in registry.encounters:
		check(not definition.encounter_id.is_empty() and not ids.has(definition.encounter_id), "Stable encounter IDs are unique")
		ids.append(definition.encounter_id)
		var composition := definition.enemies.instantiate()
		var obelisks := 0
		for child in composition.get_children():
			check(child is Enemy and child.stats != null and (child.stats.ai != null or child is RiftBoss), "Authored enemy has stats and standard or signature AI")
			if child is Obelisk:
				obelisks += 1
			if child is Enemy and child.stats.tactics:
				new_profiles[child.stats.enemy_name] = true
		check(obelisks == 1 or (definition.category == EncounterDefinition.Category.BOSS and obelisks == 0), "Legacy normal encounters retain their Obelisk; bosses may replace it")
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

func _test_attack_tween_cancellation(world: GameWorld) -> void:
	var handler := world.enemy_handler
	var enemy := handler.get_child(0) as Enemy
	var previous_action := enemy.current_action
	var previous_block := world.player.stats.block
	var previous_draw := world.player.stats.draw_pile.cards.duplicate()
	var completed := {"count": 0}
	var on_completed := func(actor: Enemy):
		if actor == enemy:
			completed.count += 1
	Events.enemy_action_completed.connect(on_completed)
	for script_path in ["res://scenes/enemy/horror/horror_attack_action.gd", "res://scenes/enemy/void_spectre/void_spectre_attack_action.gd"]:
		var action: EnemyAction = load(script_path).new()
		action.enemy = enemy
		action.target = world.player
		action.intent = Intent.new()
		action.intent.base_text = "%s"
		enemy.enemy_action_picker.add_child(action)
		enemy.current_action = action
		world.player.stats.block = 999
		var draw_count := world.player.stats.draw_pile.cards.size()
		var start := enemy.sprite_2d.position
		completed.count = 0
		handler.active_enemy = enemy
		action.perform_action()
		action.lunge_tween.pause()
		action.lunge_tween.custom_step(Utils.presentation_duration(0.4) * 0.5)
		handler.cancel_turn()
		await get_tree().create_timer(1.4).timeout
		check(world.player.stats.block == 999, "Cancelled real attack cannot deliver delayed damage")
		check(world.player.stats.draw_pile.cards.size() == draw_count, "Cancelled Spectre cannot add Void Residue")
		check(completed.count == 0, "Cancelled attack cannot complete a later activation")
		check(enemy.sprite_2d.position.is_equal_approx(start), "Cancelled lunge restores its starting position")
		completed.count = 0
		action.perform_action()
		await get_tree().create_timer(1.4).timeout
		check(world.player.stats.block < 999, "Uninterrupted real attack still deals damage")
		check(completed.count == 1, "Uninterrupted attack completes exactly once")
		check(world.player.stats.draw_pile.cards.size() == draw_count + (1 if script_path.contains("spectre") else 0), "Only uninterrupted Spectre adds one Void Residue")
		if script_path.contains("horror"):
			world.player.stats.block = 999
			completed.count = 0
			handler.active_enemy = enemy
			action.perform_action()
			action.lunge_tween.pause()
			action.lunge_tween.custom_step(Utils.presentation_duration(0.4) + Utils.presentation_duration(0.35) * 0.5)
			handler.cancel_turn()
			await get_tree().create_timer(1.4).timeout
			check(world.player.stats.block == 995, "Cancellation between Horror hits preserves the first hit and stops the second")
			check(completed.count == 0, "Partially resolved attack cannot emit completion after cancellation")
		enemy.current_action = previous_action
		action.queue_free()
	Events.enemy_action_completed.disconnect(on_completed)
	world.player.stats.block = previous_block
	world.player.stats.draw_pile.cards.assign(previous_draw)

func _test_movement_cancellation(world: GameWorld) -> void:
	var mover: MovingEnemy
	for child in world.enemy_handler.get_children():
		if child is MovingEnemy:
			mover = child
			break
	check(mover != null, "Movement regression has a real moving enemy")
	if mover == null:
		return
	var original_action := mover.current_action
	var origin := mover.current_tile_position
	var original_scale := mover.sprite_2d.scale
	var destination := MovingEnemy.INVALID_TILE
	for cell in world.tilemap.tile_map_data:
		if cell != origin and mover.can_move_to_tile(cell):
			destination = cell
			break
	check(destination != MovingEnemy.INVALID_TILE, "Movement cancellation has a legal destination")
	if destination != MovingEnemy.INVALID_TILE:
		check(mover.set_movement_target(destination), "Real movement starts before cancellation")
		if mover.move_tween:
			mover.move_tween.pause()
			mover.move_tween.custom_step(Utils.presentation_duration(mover.move_duration * 0.75))
		world.enemy_handler.active_enemy = mover
		world.enemy_handler.cancel_turn()
		await get_tree().process_frame
		check(mover.current_tile_position == origin, "Cancelled real movement rejects its deferred/tween destination")
		check(mover.position.is_equal_approx(world.tilemap.base_layer.map_to_local(origin) + Vector2(0, 1)), "Cancelled real movement restores committed board position")
		check(mover.sprite_2d.scale.is_equal_approx(original_scale), "Interrupted movement restores its original scale")
		check(mover.set_movement_target(destination), "Movement can restart after cancellation")
		await get_tree().create_timer(0.6).timeout
		check(mover.current_tile_position == destination and not mover.is_moving, "New movement commits its own destination")
		mover._notify_move_finished(origin)
	var completions := {"count": 0}
	var on_completed := func(actor: Enemy):
		if actor == mover:
			completions.count += 1
	Events.enemy_action_completed.connect(on_completed)
	for path in ["blob/blob_move_action.gd", "horror/horror_move_action.gd", "bat/bat_enemy_move_action.gd", "wasp/wasp_enemy_move_action.gd", "void_spectre/void_spectre_move_action.gd", "escape_collapse_action.gd"]:
		var action: EnemyAction = load("res://scenes/enemy/" + path).new()
		action.enemy = mover
		action.target = world.player
		action.intent = Intent.new()
		action.intent.base_text = "%s"
		mover.enemy_action_picker.add_child(action)
		mover.current_action = action
		completions.count = 0
		world.enemy_handler.active_enemy = mover
		action.perform_action()
		if mover.move_tween and mover.is_moving:
			mover.move_tween.pause()
			mover.move_tween.custom_step(Utils.presentation_duration(mover.move_duration * 0.75))
		world.enemy_handler.cancel_turn()
		await get_tree().create_timer(0.85).timeout
		check(mover.current_tile_position == origin, "Cancelled %s cannot commit a destination" % path)
		check(not mover.is_moving, "Cancelled %s leaves no active movement" % path)
		check(mover.sprite_2d.scale.is_equal_approx(original_scale), "Cancelled movement restores sprite scale")
		check(completions.count == 0, "Cancelled %s cannot finish a later turn" % path)
		# Reuse the same action to reject stale work across activations.
		action.perform_action()
		await get_tree().create_timer(1.6).timeout
		check(completions.count == 1, "Uninterrupted %s completes once" % path)
		mover.cancel_movement()
		mover._notify_move_finished(origin)
		mover.current_action = original_action
		action.queue_free()
	# A completion already in its pacing delay must also be invalidated.
	var waiting := EnemyAction.new()
	mover.enemy_action_picker.add_child(waiting)
	waiting.enemy = mover
	completions.count = 0
	waiting.complete_movement_action(waiting.action_generation, 0.1)
	world.enemy_handler.active_enemy = mover
	world.enemy_handler.cancel_turn()
	await get_tree().create_timer(0.2).timeout
	check(completions.count == 0, "Cancelled movement pacing cannot emit a stale completion")
	waiting.queue_free()
	Events.enemy_action_completed.disconnect(on_completed)


func _test_status_cancellation(world: GameWorld) -> void:
	var handler := world.enemy_handler
	var enemy := handler.get_child(0) as Enemy
	var original := enemy.status_handler
	var statuses := StatusHandler.new()
	enemy.add_child(statuses)
	statuses.status_owner = enemy
	enemy.status_handler = statuses
	var completed := {"count": 0}
	statuses.statuses_applied.connect(func(_type): completed.count += 1)
	var first := CountingStatus.new()
	first.id = "cancel_first"
	first.type = Enums.StatusType.START_OF_TURN
	first.can_expire = true
	first.duration = 5
	var second := first.duplicate() as CountingStatus
	second.id = "cancel_second"
	statuses.add_status(first)
	statuses.add_status(second)
	handler.active_enemy = enemy
	statuses.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
	handler.cancel_turn()
	await get_tree().create_timer(0.7).timeout
	check(first.calls == 0 and second.calls == 0, "Cancellation before playback prevents queued status effects")
	check(completed.count == 0, "Cancelled status batch cannot signal completion")
	first.calls = 0
	second.calls = 0
	first.duration = 5
	second.duration = 5
	handler.active_enemy = enemy
	# Headless pacing can run the whole batch in one frame. Cancel at the
	# actual effect boundary instead of racing the renderer's frame rate.
	first.status_applied.connect(func(_status): handler.cancel_turn(), CONNECT_ONE_SHOT)
	statuses.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
	await get_tree().create_timer(0.7).timeout
	check(first.calls == 1 and first.duration == 4, "Cancellation preserves an already applied status and its expiration")
	check(second.calls == 0 and second.duration == 5, "Cancellation preserves unapplied status duration")
	check(completed.count == 0, "Partial cancellation cannot complete a later activation")
	statuses.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
	await get_tree().create_timer(0.7).timeout
	check(first.calls == 2 and second.calls == 1 and completed.count == 1, "A fresh status batch works after cancellation")
	enemy.status_handler = original
	statuses.queue_free()
	await get_tree().process_frame


func _test_enemy_turn_cancellation(world: GameWorld) -> void:
	# This fixture resumes the same hand after an artificial battle restart.
	var hand_disabled: Dictionary = {}
	for card: CardUI in world.player_handler.player_hand.get_cards():
		hand_disabled[card] = card.disabled
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
	for card: CardUI in hand_disabled:
		if is_instance_valid(card):
			card.disabled = hand_disabled[card]

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
			get_viewport().get_texture().get_image().save_png("user://relic-costs.png")
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


func _test_player_shutdown(world: GameWorld, relics: RelicHandler) -> void:
	var handler := world.player_handler
	var statuses := world.player.status_handler
	var status := CountingStatus.new()
	status.id = "shutdown_status"
	status.type = Enums.StatusType.START_OF_TURN
	statuses.add_status(status)
	statuses.apply_statuses_by_type(Enums.StatusType.START_OF_TURN)
	handler.draw_cards(2)
	var hand_count := handler.player_hand.get_cards().size()
	world.battle_state.end_battle()
	await get_tree().create_timer(1.2).timeout
	check(status.calls == 0, "Battle shutdown cancels pending player statuses")
	check(handler.player_hand.get_cards().size() == hand_count and not handler.hand_ready, "Battle shutdown cancels draws and hand completion")

	var first := CountingRelic.new()
	first.id = "shutdown_first"
	first.type = Enums.RelicType.START_OF_TURN
	var second := CountingRelic.new()
	second.id = "shutdown_second"
	second.type = first.type
	relics.add_relic(first)
	relics.add_relic(second)
	var completed := {"count": 0}
	var count_completion := func(_type): completed.count += 1
	relics.relics_activated.connect(count_completion)
	first.on_activate = world.battle_state.end_battle
	relics.activate_relics_by_type(first.type)
	await get_tree().create_timer(1.2).timeout
	check(first.calls == 1 and second.calls == 0, "Shutdown preserves committed relic and cancels remaining relics")
	check(completed.count == 0 and status.calls == 0, "Cancelled relic batch cannot restart player statuses")
	first.on_activate = Callable()
	# Victory starts this batch after shutting down turn work.
	relics.relics_activated.disconnect(world._on_relics_activated)
	first.type = Enums.RelicType.END_OF_COMBAT
	second.type = first.type
	relics.activate_relics_by_type(first.type)
	await get_tree().create_timer(1.2).timeout
	check(first.calls == 2 and second.calls == 1 and completed.count == 1, "End-of-combat relics can activate after shutdown")
	relics.relics_activated.disconnect(count_completion)
	relics.relics_activated.connect(world._on_relics_activated)
	for ui: RelicUI in relics._get_all_relic_ui_nodes():
		if ui.relic == first or ui.relic == second:
			ui.queue_free()
	for ui: StatusUI in statuses.get_children():
		if ui.status == status:
			ui.queue_free()
	await get_tree().process_frame
