extends EnemyAction

const VOID_SLIME = preload("res://resources/data/cards/common/void_slime.tres")

@export var damage := 7

func perform_action() -> void:
	if not enemy or not target:
		return
	var player := target as Player
	if not player:
		return
	
	print("%s attacks!" % enemy.name)
	var world_message = WorldMessageData.new("%s attacks!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(target.global_position) * 2
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	
	intent.current_text = intent.base_text
	
	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_callback(player.stats.draw_pile.add_card.bind(VOID_SLIME.duplicate()))
	tween.tween_interval(0.25)
	tween.tween_property(enemy,"global_position", start, 0.4)
	
	tween.finished.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
	
func update_intent_text() -> void:
	if !is_instance_valid(target):
		return
	var player := target as Player
	if not player:
		return
	
	var modified_dmg := player.modifier_handler.get_modified_value(damage, Enums.ModifierType.DMG_TAKEN)
	intent.current_text = intent.base_text % modified_dmg
