extends RefCounted
class_name CardResolver

# Drives declarative card effects defined via CardEffectConfig instances.
# Keep this focused on orchestration; individual Effect nodes handle gameplay logic.
class ResolveContext:
	var card: Card
	var targets: Array[Node] = []
	var player_stats: PlayerStats
	var player_modifiers: ModifierHandler
	var tilemap: ProcGenTilemap
	var fx_layer: CanvasLayer
	var map_camera: Node2D
	var player: Player

	func get_player_targets() -> Array[Node]:
		var result: Array[Node] = []
		if player:
			result.append(player)

		var tree: SceneTree = null
		if player:
			tree = player.get_tree()
		elif not targets.is_empty():
			var first: Node = targets[0]
			if first:
				tree = first.get_tree()
		elif tilemap:
			tree = tilemap.get_tree()

		if tree:
			for node in tree.get_nodes_in_group("player"):
				if node is Player and not result.has(node):
					result.append(node)
		return result

var _fx_runner: CardFxRunner


func resolve(
	card: Card,
	targets: Array[Node],
	player_stats: PlayerStats,
	player_modifiers: ModifierHandler,
	effect_configs: Array[CardEffectConfig]
) -> void:
	if effect_configs.is_empty():
		return

	var resolved_targets: Array[Node] = []
	if targets:
		resolved_targets.append_array(targets)
	var context := _build_context(card, resolved_targets, player_stats, player_modifiers)
	_fx_runner = CardFxRunner.new()
	print(
		"[CardResolver] Resolving %s with %s config(s) against %s target(s)"
		% [card.id if card else "card", effect_configs.size(), resolved_targets.size()]
	)

	for config in effect_configs:
		if not config:
			continue
		await _resolve_effect(config, context)


func _build_context(
	card: Card,
	targets: Array[Node],
	player_stats: PlayerStats,
	player_modifiers: ModifierHandler
) -> ResolveContext:
	var context := ResolveContext.new()
	context.card = card
	if targets:
		context.targets.append_array(targets)
	context.player_stats = player_stats
	context.player_modifiers = player_modifiers

	var first_target: Node = _get_first_valid_target(context.targets)
	if first_target is TilemapTarget:
		context.tilemap = (first_target as TilemapTarget).tilemap

	var tree: SceneTree = _get_scene_tree(context)
	if tree:
		if not context.tilemap:
			context.tilemap = tree.get_first_node_in_group("map_layer") as ProcGenTilemap
		context.fx_layer = tree.get_first_node_in_group("fx_layer") as CanvasLayer
		context.map_camera = tree.get_first_node_in_group("map_camera") as Node2D
		context.player = tree.get_first_node_in_group("player") as Player
		if not context.player_stats and context.player and context.player.stats:
			context.player_stats = context.player.stats

	return context


func _resolve_effect(config: CardEffectConfig, context: ResolveContext) -> void:
	match config.effect_type:
		CardEffectConfig.EffectType.DAMAGE:
			await _resolve_damage(config, context)
		CardEffectConfig.EffectType.MULTI_DAMAGE:
			await _resolve_multi_damage(config, context)
		CardEffectConfig.EffectType.BLOCK:
			await _resolve_block(config, context)
		CardEffectConfig.EffectType.MOVE:
			await _resolve_move(config, context)
		CardEffectConfig.EffectType.GATHER:
			await _resolve_gather(config, context)
		CardEffectConfig.EffectType.ENERGY:
			await _resolve_energy(config, context)
		CardEffectConfig.EffectType.DRAW:
			await _resolve_draw(config, context)
		CardEffectConfig.EffectType.STATUS:
			await _resolve_status(config, context)
		_:
			pass


func _resolve_damage(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _filter_damage_targets(_get_targets_for_config(config, context))
	if targets.is_empty():
		return

	var amount: int = config.get_effect_amount(context.player_modifiers)
	print(
		"[CardResolver] Damage effect for %s -> amount: %s, targets: %s"
		% [context.card.id if context.card else "card", amount, targets.size()]
	)
	if config.projectile_fx:
		print(
			"[CardResolver] Projectile planned for %s using %s (mode=%s)"
			% [
				context.card.id if context.card else "card",
				config.projectile_fx,
				config.projectile_mode
			]
		)

	var effect := DamageEffect.new()
	effect.amount = amount
	effect.receiver_modifier_type = config.receiver_modifier_type
	effect.direct = config.direct_damage
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = (
		_select_visual(config, context.card) if config.attach_visual_to_effect else null
	)
	effect.impact_profile = config.impact_profile

	await _maybe_play_pre_fx(config, context, targets)
	effect.execute(targets)

	var profile: ImpactProfile = config.impact_profile
	if not profile:
		profile = ImpactProfile.for_damage(amount)
	_apply_camera_impact(profile, config, context)


func _resolve_multi_damage(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _filter_damage_targets(_get_targets_for_config(config, context))
	if targets.is_empty():
		return

	var amount: int = config.get_effect_amount(context.player_modifiers)
	var hits: int = max(config.hits, 1)
	var effect := DamageEffect.new()
	effect.amount = amount
	effect.receiver_modifier_type = config.receiver_modifier_type
	effect.direct = config.direct_damage
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = (
		_select_visual(config, context.card) if config.attach_visual_to_effect else null
	)
	effect.impact_profile = config.impact_profile

	await _maybe_play_pre_fx(config, context, targets)

	var profile: ImpactProfile = config.impact_profile
	if not profile:
		profile = ImpactProfile.for_damage(amount)

	var tree: SceneTree = _get_scene_tree(context)
	for i in hits:
		effect.execute(targets)
		_apply_camera_impact(profile, config, context)
		if i < hits - 1 and config.hit_interval > 0.0 and tree:
			await tree.create_timer(config.hit_interval).timeout


func _resolve_block(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var effect := BlockEffect.new()
	effect.amount = config.get_effect_amount(context.player_modifiers)
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = (
		_select_visual(config, context.card) if config.attach_visual_to_effect else null
	)
	await _maybe_play_pre_fx(config, context, targets)
	effect.execute(targets)


func _resolve_move(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var tile_target := _find_tile_target(context.targets)
	if not tile_target:
		return

	var effect := MoveEffect.new()
	effect.tilemap_target = tile_target
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = (
		_select_visual(config, context.card) if config.attach_visual_to_effect else null
	)
	await _maybe_play_pre_fx(config, context, targets)
	effect.execute(targets)


func _resolve_gather(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var tile_target := _find_tile_target(context.targets)
	if not tile_target:
		return

	var effect := GatherEffect.new()
	var board := tile_target.tilemap
	effect.amount = board.get_resource_count(tile_target.tile_position)
	if effect.amount <= 0:
		return
	effect.tile_target_position = board.to_local(board.cell_to_world(tile_target.tile_position))
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = (
		_select_visual(config, context.card) if config.attach_visual_to_effect else null
	)
	await _maybe_play_pre_fx(config, context, targets)
	# Commit the finite deposit once, before cosmetic feedback can yield.
	board.set_resource_count(tile_target.tile_position, 0)
	effect.execute(targets)


func _resolve_energy(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var effect := EnergyEffect.new()
	effect.amount = config.get_effect_amount(context.player_modifiers)
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = _select_visual(config, context.card)
	await _maybe_play_pre_fx(config, context, targets)
	effect.execute(targets)


func _resolve_draw(config: CardEffectConfig, context: ResolveContext) -> void:
	var targets: Array[Node] = _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var effect := DrawEffect.new()
	effect.amount = config.get_effect_amount(context.player_modifiers)
	await _maybe_play_pre_fx(config, context, targets)
	effect.execute(targets)


func _resolve_status(config: CardEffectConfig, context: ResolveContext) -> void:
	if not config.status:
		return

	var targets: Array[Node] = _get_targets_for_config(config, context)
	if targets.is_empty():
		return

	var effect := StatusEffect.new()
	effect.status = config.status
	effect.sound_fx = _select_sound(config, context.card)
	effect.visual_fx = (
		_select_visual(config, context.card) if config.attach_visual_to_effect else null
	)
	await _maybe_play_pre_fx(config, context, targets)
	effect.execute(targets)


func _get_targets_for_config(config: CardEffectConfig, context: ResolveContext) -> Array[Node]:
	if config.should_use_player_targets():
		var player_targets: Array[Node] = context.get_player_targets()
		return player_targets
	return context.targets


func _filter_damage_targets(targets: Array[Node]) -> Array[Node]:
	var filtered: Array[Node] = []
	for target in targets:
		if target is Enemy or target is Player:
			filtered.append(target)
	return filtered


func _find_tile_target(targets: Array[Node]) -> TilemapTarget:
	for target in targets:
		if target is TilemapTarget:
			return target as TilemapTarget
	return null


func _select_sound(config: CardEffectConfig, card: Card) -> AudioStream:
	if config and config.sound_fx:
		return config.sound_fx
	if card:
		return card.sound_fx
	return null


func _select_visual(config: CardEffectConfig, card: Card) -> PackedScene:
	if config and config.visual_fx:
		return config.visual_fx
	if card:
		return card.visual_fx
	return null


func _apply_camera_impact(
	profile: ImpactProfile, config: CardEffectConfig, context: ResolveContext
) -> void:
	if not context or not context.map_camera:
		return

	var strength := 0.0
	var duration := 0.0
	if config and config.camera_shake_strength >= 0.0:
		strength = config.camera_shake_strength
		duration = config.camera_shake_duration
	elif profile:
		strength = profile.shake_strength
		duration = profile.shake_duration

	if strength <= 0.0:
		return
	Utils.shake(context.map_camera, strength, duration if duration > 0.0 else 0.2)


func _maybe_play_pre_fx(config: CardEffectConfig, context: ResolveContext, targets: Array[Node]) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _fx_runner:
		return
	if not config or not config.projectile_fx:
		return
	await _fx_runner.play_pre_effect_fx(config, context, targets)


func _get_scene_tree(context: ResolveContext) -> SceneTree:
	var sample: Node = _get_first_valid_target(context.targets)
	if sample and sample.get_tree():
		return sample.get_tree()
	if context.tilemap and context.tilemap.get_tree():
		return context.tilemap.get_tree()
	if context.player and context.player.get_tree():
		return context.player.get_tree()
	return null


func _get_first_valid_target(targets: Array[Node]) -> Node:
	for target in targets:
		if target:
			return target
	return null
