extends EnemyAction

@export var damage := 8
@export_range(0, 8) var self_block := 2


func is_performable() -> bool:
	if not enemy or not target:
		return false
	var enemy_tile := enemy.tilemap.base_layer.local_to_map(enemy.position)
	var player_tile := enemy.tilemap.base_layer.local_to_map(target.position)
	var surrounding_tiles := enemy.tilemap.base_layer.get_surrounding_cells(player_tile)
	return surrounding_tiles.has(enemy_tile)


func perform_action() -> void:
	if not enemy or not target:
		return

	var world_message := WorldMessageData.new("%s swings a cleaving slam" % enemy.name)
	Events.world_message_requested.emit(world_message)

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	# Flying idle also writes Sprite2D.position; pause it for the authored lunge.
	var idle := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var resume_idle := idle != null and idle.is_playing()
	if resume_idle:
		idle.pause()
	var start := enemy.sprite_2d.position
	var end := start + enemy.to_local(target.global_position).normalized() * 5.0

	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	damage_effect.visual_fx = visual_fx

	intent.current_text = intent.base_text

	tween.tween_property(enemy.sprite_2d, "position", end, Utils.presentation_duration(0.35)).set_ease(Tween.EASE_IN)
	tween.tween_callback(
		func():
			damage_effect.execute(target_array)
			if self_block > 0:
				var block_effect := BlockEffect.new()
				block_effect.amount = self_block
				block_effect.sound_fx = sound
				block_effect.visual_fx = visual_fx
				block_effect.execute([enemy])
	)
	tween.tween_interval(Utils.presentation_duration(0.25))
	tween.tween_property(enemy.sprite_2d, "position", start, Utils.presentation_duration(0.35)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		if resume_idle and is_instance_valid(idle):
			idle.play()
	)
	tween.finished.connect(func(): Events.enemy_action_completed.emit(enemy))


func update_intent_text() -> void:
	if !is_instance_valid(target):
		return
	var player := target as Player
	if not player:
		return

	var modified_dmg := player.modifier_handler.get_modified_value(damage, Enums.ModifierType.DMG_TAKEN)
	modified_dmg = enemy.modifier_handler.get_modified_value(modified_dmg, Enums.ModifierType.DMG_DEALT)
	intent.current_text = intent.base_text % str(modified_dmg)
