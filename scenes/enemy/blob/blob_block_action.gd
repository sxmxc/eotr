extends EnemyAction

@export var block := 6

func perform_action() -> void:
	if not enemy or not target: 
		return 
	print("Enemy blocks!")
	var world_message = WorldMessageData.new("%s blocks!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound_fx = sound
	block_effect.execute([enemy])
	
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
