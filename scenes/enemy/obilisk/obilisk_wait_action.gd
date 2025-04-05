extends EnemyAction

func perform_action() -> void:
	if not enemy or not target:
		return
	var world_message = WorldMessageData.new("Obilisk waits")
	Events.world_message_requested.emit(world_message)	
	get_tree().create_timer(.6).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)

func is_performable() -> bool:
	return true
