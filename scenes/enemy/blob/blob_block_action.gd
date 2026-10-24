extends EnemyAction

@export var block := 8
@export var visual_fx_scene: PackedScene

func perform_action() -> void:
	if not enemy or not target: 
		return 
	print("%s blocks!" % enemy.stats.enemy_name)
	var world_message = WorldMessageData.new("%s blocks!" % enemy.stats.enemy_name)
	if not enemy.tilemap.is_tile_behind_fog(enemy.current_tile_position):
		Events.world_message_requested.emit(world_message)
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx_scene
	block_effect.execute([enemy])
	
	
	get_tree().create_timer(Utils.presentation_duration(0.6), false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % str(block)


func get_weight(decision_context: Dictionary = {}) -> float:
	return get_block_weight(block, decision_context)
