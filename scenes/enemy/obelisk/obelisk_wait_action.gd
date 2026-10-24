extends EnemyAction

func perform_action() -> void:
	if not enemy or not target:
		return
	get_tree().create_timer(Utils.presentation_duration(.3)).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)

func is_performable() -> bool:
	return true
