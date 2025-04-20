extends Effect
class_name StatusEffect

var status : Status

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			SoundManager.play_sound_random_pitch(sound_fx)
			target.status_handler.add_status(status)
