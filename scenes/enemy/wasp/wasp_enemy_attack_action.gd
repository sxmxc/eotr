extends EnemyAction

func _init() -> void:
	target_range = 1

const POISONED = preload("res://resources/data/statuses/poisoned.tres")

@export var damage := 4
@export var curse_fx_scene : PackedScene
@export var status_duration := 2

func perform_action() -> void:
	if not enemy or not target:
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
	var status_effect = StatusEffect.new()
	var target_array: Array[Node] = [target]
	var poisoned := POISONED.duplicate()
	var curse_fx : VisualFX = curse_fx_scene.instantiate()
	target.add_child(curse_fx)
	poisoned.duration = status_duration
	status_effect.status = poisoned
	status_effect.sound_fx = sound
	damage_effect.amount = damage
	damage_effect.sound_fx = sound
	damage_effect.visual_fx = visual_fx
	
	intent.current_text = intent.base_text
	
	tween.tween_property(enemy.sprite_2d, "position", end, Utils.presentation_duration(0.4)).set_ease(Tween.EASE_IN)
	tween.tween_callback(
		func():
			damage_effect.execute(target_array)
			status_effect.execute(target_array)
			curse_fx.execute()
			)
	
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
	intent.current_text = intent.base_text % modified_dmg


func get_weight(decision_context: Dictionary = {}) -> float:
	return get_attack_weight(damage, 1, decision_context)
