extends TileEffect
class_name GatherEffect

var amount := 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target or not target.run_stats:
			continue
		if target is Player:
			target.run_stats.resources += amount
			SoundManager.play_sound_random_pitch(sound_fx)
