extends EnemyAction

func _init() -> void:
	target_range = 1

const VOID_SLIME = preload("res://resources/data/cards/common/void_slime.tres")

@export var damage := 6

func perform_action() -> void:
	if not enemy or not target:
		return
	var player := target as Player
	if not player:
		return
	
	print("%s attacks!" % enemy.name)
	var world_message = WorldMessageData.new("%s attacks!" % enemy.name)
	Events.world_message_requested.emit(world_message)
	var tween := create_lunge_tween().set_trans(Tween.TRANS_QUINT)
	# Flying idle also writes Sprite2D.position; pause it for the authored lunge.
	var idle := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var resume_idle := idle != null and idle.is_playing()
	if resume_idle:
		idle.pause()
	var start := enemy.sprite_2d.position
	var end := start + enemy.to_local(target.global_position).normalized() * 5.0
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	
	intent.current_text = intent.base_text
	
	tween.tween_property(enemy.sprite_2d, "position", end, Utils.presentation_duration(0.4)).set_ease(Tween.EASE_IN)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_callback(player.stats.draw_pile.add_card.bind(VOID_SLIME.duplicate()))
	tween.tween_interval(Utils.presentation_duration(0.25))
	tween.tween_property(enemy.sprite_2d, "position", start, Utils.presentation_duration(0.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		if resume_idle and is_instance_valid(idle):
			idle.play()
	)
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


func get_weight(decision_context: Dictionary = {}) -> float:
	return get_attack_weight(damage, 1, decision_context)
