extends EnemyAction

@export var damage := 8
@export_range(0, 8) var self_block := 2


func is_performable() -> bool:
	if not enemy or not target:
		return false
	var enemy_tile := enemy.tilemap.base_layer.local_to_map(enemy.position)
	var player_tile := enemy.tilemap.base_layer.local_to_map(target.position)
	var surrounding_tiles := enemy.tilemap.base_layer.get_surrounding_cells(player_tile)
	return surrounding_tiles.has(enemy_tile)


func perform_action() -> void:
	if not enemy or not target:
		return

	var world_message := WorldMessageData.new("%s swings a cleaving slam" % enemy.name)
	Events.world_message_requested.emit(world_message)

	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(target.global_position) * 2

	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	damage_effect.visual_fx = visual_fx

	intent.current_text = intent.base_text

	tween.tween_property(enemy, "global_position", end, 0.35)
	tween.tween_callback(
		func():
			damage_effect.execute(target_array)
			if self_block > 0:
				var block_effect := BlockEffect.new()
				block_effect.amount = self_block
				block_effect.sound_fx = sound
				block_effect.visual_fx = visual_fx
				block_effect.execute([enemy])
	)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.35)

	tween.finished.connect(func(): Events.enemy_action_completed.emit(enemy))


func update_intent_text() -> void:
	if !is_instance_valid(target):
		return
	var player := target as Player
	if not player:
		return

	var modified_dmg := player.modifier_handler.get_modified_value(damage, Enums.ModifierType.DMG_TAKEN)
	modified_dmg = enemy.modifier_handler.get_modified_value(modified_dmg, Enums.ModifierType.DMG_DEALT)
	intent.current_text = intent.base_text % modified_dmg
