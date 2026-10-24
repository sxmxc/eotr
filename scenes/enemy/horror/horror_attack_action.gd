extends EnemyAction

func _init() -> void:
	target_range = 1

@export var damage := 4

func perform_action():
	if not enemy or not target: 
		return
		
	var tween := create_lunge_tween().set_trans(Tween.TRANS_QUINT)
	# Flying idle also writes Sprite2D.position; pause it for the authored lunge.
	var idle := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var resume_idle := idle != null and idle.is_playing()
	if resume_idle:
		idle.pause()
	var start := enemy.sprite_2d.position
	var end := start + enemy.to_local(target.global_position).normalized() * 5.0
	var damage_effect = DamageEffect.new()
	damage_effect.source_actor = enemy
	damage_effect.visual_fx = visual_fx
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	
	intent.current_text = intent.base_text
	
	tween.tween_property(enemy.sprite_2d, "position", end, Utils.presentation_duration(0.4)).set_ease(Tween.EASE_IN)
	tween.tween_callback(damage_effect.execute.bind(target_array))
	tween.tween_interval(Utils.presentation_duration(0.35))
	tween.tween_callback(damage_effect.execute.bind(target_array))
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
	var player: Node2D = target
	if not player:
		return
	
	var modified_dmg: int = player.modifier_handler.get_modified_value(damage, Enums.ModifierType.DMG_TAKEN)
	var summary := "%d x2" % modified_dmg
	intent.current_text = intent.base_text % summary


func get_weight(decision_context: Dictionary = {}) -> float:
	return get_attack_weight(damage, 2, decision_context)
