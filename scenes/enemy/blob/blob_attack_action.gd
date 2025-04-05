extends EnemyAction

@export var damage := 7

func perform_action() -> void:
	if not enemy or not target:
		return
	print("Enemy attacks!")
	var world_message = WorldMessageData.new("%s attacks!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(target.global_position) * 2
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_interval(0.25)
	tween.tween_property(enemy,"global_position", start, 0.4)
	
	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
