extends RefCounted
class_name CardFxRunner

# Handles all pre-effect FX such as projectiles and beam-style arcs for a card effect.
# Keeps visual sequencing out of CardResolver and provides sane fallbacks/timeouts so
# resolution never stalls if an FX scene misbehaves.
class _WaitGroup:
	signal done
	var remaining := 0

	func track(projectile: ProjectileFX) -> void:
		if not projectile:
			return
		remaining += 1
		projectile.complete.connect(func():
			remaining -= 1
			if remaining <= 0:
				done.emit()
		, CONNECT_ONE_SHOT)

	func wait() -> void:
		if remaining <= 0:
			return
		await done


func play_pre_effect_fx(config: CardEffectConfig, context, targets: Array[Node]) -> void:
	if not config:
		return
	var tgt_count := targets.size()
	var card_id := ""
	if context and context.card:
		card_id = str(context.card.id)
	else:
		card_id = "unknown"
	print(
		"[CardFxRunner] pre-effect for card=%s projectile=%s mode=%s targets=%s"
		% [card_id, str(config.projectile_fx), str(config.projectile_mode), tgt_count]
	)
	await _play_projectiles(config, context, targets)


func _play_projectiles(config: CardEffectConfig, context, targets: Array[Node]) -> void:
	if not config.projectile_fx:
		return

	var valid_targets := _collect_fx_targets(targets)
	if valid_targets.is_empty():
		return

	var mode := _resolve_projectile_mode(config, valid_targets.size())
	match mode:
		CardEffectConfig.ProjectileMode.FIRST_TARGET_ONLY:
			await _fire_single(config, context, valid_targets[0])
		CardEffectConfig.ProjectileMode.EACH_TARGET_PARALLEL:
			await _fire_parallel(config, context, valid_targets)
		_:
			await _fire_sequential(config, context, valid_targets)


func _collect_fx_targets(targets: Array[Node]) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target is Node2D:
			result.append(target)
	return result


func _resolve_projectile_mode(
	config: CardEffectConfig, target_count: int
) -> CardEffectConfig.ProjectileMode:
	if config.projectile_mode == CardEffectConfig.ProjectileMode.AUTO:
		return (
			CardEffectConfig.ProjectileMode.EACH_TARGET_SEQUENTIAL
			if target_count > 1
			else CardEffectConfig.ProjectileMode.FIRST_TARGET_ONLY
		)
	return config.projectile_mode


func _fire_single(config: CardEffectConfig, context, target: Node2D) -> void:
	var projectile := _spawn_projectile(config, context, target)
	if not projectile:
		return
	projectile.execute(target, context.player)
	await projectile.complete


func _fire_sequential(config: CardEffectConfig, context, targets: Array[Node2D]) -> void:
	for i in targets.size():
		var projectile := _spawn_projectile(config, context, targets[i])
		if projectile:
			projectile.execute(targets[i], context.player)
			await projectile.complete
		if i < targets.size() - 1:
			await _wait(config.projectile_spacing, context, targets[i])


func _fire_parallel(config: CardEffectConfig, context, targets: Array[Node2D]) -> void:
	var active: Array[ProjectileFX] = []
	var wait_group := _WaitGroup.new()
	for target in targets:
		var projectile := _spawn_projectile(config, context, target)
		if not projectile:
			continue
		wait_group.track(projectile)
		projectile.execute(target, context.player)
		active.append(projectile)

	await wait_group.wait()


func _spawn_projectile(config: CardEffectConfig, context, target: Node2D) -> ProjectileFX:
	var projectile: ProjectileFX = config.projectile_fx.instantiate() as ProjectileFX
	if not projectile:
		print("[CardFxRunner] failed to instance projectile for card=%s" % [context.card.id if context and context.card else "unknown"])
		return null

	if config.projectile_visual_fx:
		projectile.visual_fx = config.projectile_visual_fx.instantiate() as VisualFX

	var parent := _resolve_parent(target, context)
	if not parent:
		print("[CardFxRunner] no parent for projectile; target=%s card=%s" % [target, context.card.id if context and context.card else "unknown"])
		projectile.free()
		return null

	parent.add_child(projectile)
	var parent_name: String = str(parent.name) if parent else "null"
	var target_name: String = str(target.name) if target else "null"
	var target_pos: String = str(target.global_position) if target else "n/a"
	print(
		"[CardFxRunner] spawned projectile=%s parent=%s target=%s pos=%s"
		% [projectile.name, parent_name, target_name, target_pos]
	)
	_apply_timeout(projectile, config.projectile_timeout, context, target)
	return projectile


func _resolve_parent(target: Node2D, context) -> Node:
	# Prefer a stable world parent so projectiles survive if the target frees mid-flight.
	if target and target.is_inside_tree() and target.get_tree() and target.get_tree().current_scene:
		return target.get_tree().current_scene
	if context and context.tilemap and context.tilemap is Node2D:
		return context.tilemap
	if context and context.fx_layer:
		return context.fx_layer
	if target and target.get_parent() and target.get_parent() is Node2D:
		return target.get_parent()
	return target if target else null


func _apply_timeout(projectile: ProjectileFX, timeout: float, context, sample: Node = null) -> void:
	if timeout <= 0.0:
		return
	var tree := _get_scene_tree(context, sample if sample else projectile)
	if not tree:
		return
	var timer := tree.create_timer(timeout)
	if timer:
		timer.timeout.connect(projectile.force_complete_deferred, CONNECT_ONE_SHOT)


func _wait(duration: float, context, sample: Node = null) -> void:
	if duration <= 0.0:
		return
	var tree := _get_scene_tree(context, sample)
	if tree:
		await tree.create_timer(duration).timeout


func _get_scene_tree(context, sample: Node = null) -> SceneTree:
	if sample and sample.get_tree():
		return sample.get_tree()
	if context:
		if context.tilemap and context.tilemap.get_tree():
			return context.tilemap.get_tree()
		if context.player and context.player.get_tree():
			return context.player.get_tree()
	return null
