extends EnemyAction

@export var block := 14
@export var hp_threshold := 8
@export var visual_fx_scene: PackedScene

var already_used := false


func is_performable() -> bool:
	if not enemy or already_used:
		return false
	var is_low := enemy.stats.health <= hp_threshold

	return is_low


func perform_action() -> void:
	if not enemy or not target:
		return
	already_used = true
	
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx_scene
	block_effect.execute([enemy])
	var world_message = WorldMessageData.new("%s hardens its body!" % enemy.stats.enemy_name)
	if not enemy.tilemap.is_tile_behind_fog(enemy.current_tile_position):
		Events.world_message_requested.emit(world_message)
	get_tree().create_timer(Utils.presentation_duration(0.6), false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	intent.current_text = intent.base_text % str(block)
