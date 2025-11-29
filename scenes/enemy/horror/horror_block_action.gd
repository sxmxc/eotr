extends EnemyAction

@export var block := 8

func perform_action():
	if not enemy or not target: 
		return
	var world_message = WorldMessageData.new("%s blocks!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx
	block_effect.execute([enemy])
	
	get_tree().create_timer(.3, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
	

func update_intent_text() -> void:
	intent.current_text = intent.base_text % str(block)
