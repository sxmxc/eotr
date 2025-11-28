extends EnemyAction

@export var block: int = 45
@export var heal_cap: int = 30

const ARMORED = preload("res://resources/data/statuses/armored.tres")

func is_performable() -> bool:
	if enemy == null:
		return false
	var obelisk : Obelisk = get_tree().get_first_node_in_group("obelisk")
	if obelisk.stats.health < obelisk.stats.max_health:
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
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(obelisk.global_position) * 2

	tween.tween_property(enemy, "global_position", end, 0.4)
	tween.tween_callback(armored_status_effect.execute.bind([obelisk] as Array[Node]))
	tween.tween_callback(
		func():
			var missing: int = obelisk.stats.max_health - obelisk.stats.health
			var heal_amount: int = min(heal_cap, missing)
			if heal_amount > 0:
				obelisk.stats.heal(heal_amount)
	)
	tween.tween_interval(0.25)
	tween.tween_property(enemy, "global_position", start, 0.4)

	tween.finished.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)
