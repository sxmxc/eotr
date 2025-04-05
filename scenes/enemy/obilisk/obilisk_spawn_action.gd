extends EnemyAction

@export var spawn_turn_freq := 4


func is_performable() -> bool:
	print("Obilisk checking if it should spawn")
	if enemy.turn_ticker % spawn_turn_freq == 0:
		print("It should")
		return true
	else:
		print("Nope. Not yet")
		return false

func perform_action() -> void:
	if not enemy or not target:
		return
	print("Obilisk spawn not implemented yet")
	var world_message = WorldMessageData.new("Obilisk spawns a creature from the void")
	Events.world_message_requested.emit(world_message)
	get_tree().create_timer(.6).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
