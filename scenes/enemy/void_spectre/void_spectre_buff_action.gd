extends EnemyAction

const STRENGTH_STATUS = preload("res://resources/data/statuses/strength.tres")

@export var stacks_per_action := 2

var hp_threshold := 25
var usages := 0


func is_performable() -> bool:
	var hp_under_threshold := enemy.stats.health <= hp_threshold
	if usages == 0 or (usages == 1 and hp_under_threshold):
		usages += 1
		return true
	return false


func perform_action() -> void:
	if not enemy or not target:
		return

	var status_effect := StatusEffect.new()
	var strength := STRENGTH_STATUS.duplicate()
	strength.stacks = stacks_per_action
	status_effect.status = strength
	status_effect.execute([enemy])

	#SoundManager.play_sound_random_pitch(sound)

	Events.enemy_action_completed.emit(enemy)
