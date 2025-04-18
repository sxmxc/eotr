extends EnemyAction

@export var block := 15
@export var hp_threshold := 6
@export var visual_fx_scene: PackedScene

var already_used := false


func is_performable() -> bool:
	if not enemy or already_used:
		return false
	var world_message = WorldMessageData.new("%s hardens its body!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var is_low := enemy.stats.health <= hp_threshold
	already_used = is_low
	
	return is_low


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var block_effect := BlockEffect.new()
	block_effect.amount = block
	block_effect.sound_fx = sound
	block_effect.visual_fx = visual_fx_scene
	block_effect.execute([enemy])
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
