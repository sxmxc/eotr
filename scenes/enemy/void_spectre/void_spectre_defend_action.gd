extends EnemyAction

@export var block: int = 45
@export var heal_cap: int = 30

const ARMORED = preload("res://resources/data/statuses/armored.tres")

func is_performable() -> bool:
	if enemy == null:
		return false
	var obelisk : Obelisk = get_tree().get_first_node_in_group("obelisk")
	if is_instance_valid(obelisk) and not obelisk.is_dying and obelisk.stats.health > 0 and obelisk.stats.health < obelisk.stats.max_health:
		return true
	return false
	
func perform_action() -> void:
	if not enemy or not target:
		return
		
	var armored_status_effect : StatusEffect = StatusEffect.new()
	
	armored_status_effect.status = ARMORED.duplicate()
	armored_status_effect.status.stacks = block
	armored_status_effect.sound_fx = sound
	armored_status_effect.visual_fx = visual_fx
	
	var obelisk : Obelisk = get_tree().get_first_node_in_group("obelisk")
	if not is_instance_valid(obelisk) or obelisk.is_dying:
		Events.enemy_action_completed.emit(enemy)
		return
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	# Flying idle also writes Sprite2D.position; pause it for the authored lunge.
	var idle := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var resume_idle := idle != null and idle.is_playing()
	if resume_idle:
		idle.pause()
	var start := enemy.sprite_2d.position
	var end := start + enemy.to_local(obelisk.global_position).normalized() * 4.0

	tween.tween_property(enemy.sprite_2d, "position", end, Utils.presentation_duration(0.4)).set_ease(Tween.EASE_IN)
	tween.tween_callback(armored_status_effect.execute.bind([obelisk] as Array[Node]))
	tween.tween_callback(
		func():
			var missing: int = obelisk.stats.max_health - obelisk.stats.health
			var heal_amount: int = min(heal_cap, missing)
			if heal_amount > 0:
				obelisk.stats.heal(heal_amount)
				if DisplayServer.get_name() != "headless":
					var mend := preload("res://ui/fx/mend_signature.tscn").instantiate() as VisualFX
					obelisk.add_child(mend)
					mend.execute()
	)
	tween.tween_interval(Utils.presentation_duration(0.25))
	tween.tween_property(enemy.sprite_2d, "position", start, Utils.presentation_duration(0.4)).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		if resume_idle and is_instance_valid(idle):
			idle.play()
	)
	tween.finished.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	var summary := "%d/%d" % [block, heal_cap]
	intent.current_text = intent.base_text % summary
	intent.secondary_icon = preload("res://assets/rift/ui/health.svg")
	intent.secondary_text = str(heal_cap)
	intent.detail_text = "Gain %d block and heal up to %d HP" % [block, heal_cap]
