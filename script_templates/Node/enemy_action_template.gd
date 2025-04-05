# meta-name: Enemy Action
# meta-description: An action which can be performed by an enemy during its turn.
extends EnemyAction

func perform_action() -> void:
	if not enemy or not target: 
		return
		
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := start + start.direction_to(target.global_position) * 2
	
	SoundManager.play_sound_random_pitch(sound)
	
	Events.enemy_action_completed.emit(enemy)
