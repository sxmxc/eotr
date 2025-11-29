extends EnemyAction

@export var block := 10


func perform_action() -> void:
	if not enemy or not target:
		return

	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx
	block_effect.execute([enemy])

	get_tree().create_timer(0.3, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % str(block)
