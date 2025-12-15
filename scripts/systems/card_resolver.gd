extends RefCounted
class_name CardResolver

class ResolveContext:
	var card: Card
	var targets: Array[Node] = []
	var player_stats: PlayerStats
	var tilemap: ProcGenTilemap
	var fx_layer: Node
	var map_camera: Node2D
	var player: Player

	func get_player_targets() -> Array[Node]:
		if player:
			return [player]
		if tilemap:
			var players: Array[Node] = tilemap.get_tree().get_nodes_in_group("player")
			return players
		return []


func resolve(
	card: Card,
	targets: Array[Node],
	player_stats: PlayerStats,
	player_modifiers: ModifierHandler,
	effect_configs: Array[CardEffectConfig]
) -> void:
	if effect_configs.is_empty():
		print("[CardResolver] No effect configs supplied for %s; skipping." % (card.id if card else "unknown card"))
		return

	print(
		"[CardResolver] Resolving %s with %s config(s) against %s target(s)"
		% [
			card.id if card else "unknown card",
			effect_configs.size(),
			targets.size()
		]
	)
	var context := _build_context(card, targets, player_stats)
	for config in effect_configs:
		if not config:
			print("[CardResolver] Skipping null CardEffectConfig for %s" % (card.id if card else "unknown card"))
			continue
		await _resolve_effect(config, context, player_modifiers)


func _build_context(card: Card, targets: Array[Node], player_stats: PlayerStats) -> ResolveContext:
	var context := ResolveContext.new()
	context.card = card
	context.targets = targets.duplicate()
	context.player_stats = player_stats
	var sample_target := _get_first_valid_target(targets)
	if sample_target and sample_target.get_tree():
		var tree := sample_target.get_tree()
		context.tilemap = tree.get_first_node_in_group("map_layer") as ProcGenTilemap
		context.fx_layer = tree.get_first_node_in_group("fx_layer")
		context.map_camera = tree.get_first_node_in_group("map_camera") as Node2D
		context.player = tree.get_first_node_in_group("player") as Player
	return context


func _resolve_effect(
	config: CardEffectConfig, context: ResolveContext, player_modifiers: ModifierHandler
) -> void:
	match config.effect_type:
		CardEffectConfig.EffectType.DAMAGE:
			await _resolve_damage(config, context, player_modifiers)
		CardEffectConfig.EffectType.BLOCK:
			_resolve_block(config, context, player_modifiers)
		CardEffectConfig.EffectType.MOVE:
			_resolve_move(config, context)
		CardEffectConfig.EffectType.GATHER:
			_resolve_gather(config, context)


func _resolve_damage(
	config: CardEffectConfig, context: ResolveContext, player_modifiers: ModifierHandler
) -> void:
	var targets := _filter_damage_targets(_get_targets_for_config(config, context), context)
	if targets.is_empty():
		print("[CardResolver] Damage effect skipped; no valid targets for %s" % (context.card.id if context.card else "unknown card"))
		return

	var effect := DamageEffect.new()
	effect.amount = config.get_effect_amount(player_modifiers)
	effect.receiver_modifier_type = config.receiver_modifier_type
	effect.direct = config.direct_damage
	effect.sound_fx = _choose_sound(config, context)
	if config.attach_visual_to_effect:
		effect.visual_fx = _choose_visual(config, context)

	var profile := config.impact_profile
	if not profile:
		profile = ImpactProfile.for_damage(max(effect.amount, 0))
	effect.impact_profile = profile

	print(
		"[CardResolver] Damage effect for %s -> amount: %s, targets: %s"
		% [
			context.card.id if context.card else "unknown card",
			effect.amount,
			targets.size()
		]
	)
	await _play_projectile_if_needed(config, targets[0], context)
	effect.execute(targets)
	_apply_camera_impact(profile, context, config)


func _resolve_block(
	config: CardEffectConfig, context: ResolveContext, player_modifiers: ModifierHandler
) -> void:
	var targets := _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var effect := BlockEffect.new()
	effect.amount = config.get_effect_amount(player_modifiers)
	effect.sound_fx = _choose_sound(config, context)
	if config.attach_visual_to_effect:
		effect.visual_fx = _choose_visual(config, context)
	effect.execute(targets)


func _resolve_move(config: CardEffectConfig, context: ResolveContext) -> void:
	var tile_target := _find_tile_target(context.targets)
	if not tile_target:
		return

	var player_targets := context.get_player_targets()
	if player_targets.is_empty():
		return

	var effect := MoveEffect.new()
	effect.tilemap_target = tile_target
	effect.sound_fx = _choose_sound(config, context)
	effect.execute(player_targets)


func _resolve_gather(config: CardEffectConfig, context: ResolveContext) -> void:
	var tile_target := _find_tile_target(context.targets)
	if not tile_target or not tile_target.tilemap:
		return

	var tilemap := tile_target.tilemap
	var tile_position := tile_target.tile_position
	var amount := tilemap.get_resource_count(tile_position)
	if config.consume_resources_on_gather:
		tilemap.set_resource_count(tile_position, 0)

	var player_targets := context.get_player_targets()
	if player_targets.is_empty():
		return

	var effect := GatherEffect.new()
	effect.amount = amount
	effect.tile_target_position = tilemap.base_layer.map_to_local(tile_position)
	effect.sound_fx = _choose_sound(config, context)
	effect.visual_fx = _choose_visual(config, context)
	effect.execute(player_targets)


func _get_targets_for_config(
	config: CardEffectConfig, context: ResolveContext
) -> Array[Node]:
	if config.should_use_player_targets():
		return context.get_player_targets()
	return context.targets


func _filter_damage_targets(targets: Array[Node], context: ResolveContext) -> Array[Node]:
	if targets.is_empty():
		return targets
	var filtered: Array[Node] = []
	for target in targets:
		if target is Enemy or target is Player:
			filtered.append(target)
	# If no valid actors were supplied but we can find an enemy via context, fall back to the first enemy in the scene.
	if filtered.is_empty() and context.tilemap:
		for enemy: Enemy in context.tilemap.get_tree().get_nodes_in_group("enemy"):
			if enemy:
				filtered.append(enemy)
				break
	return filtered


func _choose_sound(config: CardEffectConfig, context: ResolveContext) -> AudioStream:
	if config.sound_fx:
		return config.sound_fx
	if context.card:
		return context.card.sound_fx
	return null


func _choose_visual(config: CardEffectConfig, context: ResolveContext) -> PackedScene:
	if config.visual_fx:
		return config.visual_fx
	if context.card:
		return context.card.visual_fx
	return null


func _choose_projectile_scene(config: CardEffectConfig, context: ResolveContext) -> PackedScene:
	if config.projectile_fx:
		return config.projectile_fx
	if context.card:
		return context.card.projectile_fx
	return null


func _choose_projectile_visual(config: CardEffectConfig, context: ResolveContext) -> PackedScene:
	if config.projectile_visual_fx:
		return config.projectile_visual_fx
	if config.visual_fx:
		return config.visual_fx
	if context.card:
		return context.card.visual_fx
	return null


func _play_projectile_if_needed(
	config: CardEffectConfig, target: Node, context: ResolveContext
) -> void:
	var projectile_scene := _choose_projectile_scene(config, context)
	if not projectile_scene or not target:
		return
	var projectile := projectile_scene.instantiate() as ProjectileFX
	if not projectile:
		return

	var projectile_visual := _choose_projectile_visual(config, context)
	if projectile_visual:
		projectile.visual_fx = projectile_visual.instantiate() as VisualFX

	var parent: Node = context.fx_layer if context.fx_layer else target.get_tree().current_scene
	parent.add_child(projectile)
	projectile.execute(target)
	await projectile.complete


func _apply_camera_impact(
	profile: ImpactProfile, context: ResolveContext, config: CardEffectConfig
) -> void:
	if not context.map_camera:
		return
	var shake_strength := profile.shake_strength
	var shake_duration := profile.shake_duration
	if config.camera_shake_strength >= 0.0:
		shake_strength = config.camera_shake_strength
		shake_duration = config.camera_shake_duration
	Utils.shake(context.map_camera, shake_strength, shake_duration)


func _find_tile_target(targets: Array[Node]) -> TilemapTarget:
	for target in targets:
		if target is TilemapTarget:
			return target
	return null


func _get_first_valid_target(targets: Array[Node]) -> Node:
	for target in targets:
		if target:
			return target
	return null
