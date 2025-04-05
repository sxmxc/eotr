extends NodeEffect
class_name EnergyEffect

var amount := 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Player:
			target.stats.energy += amount
			SoundManager.play_sound_random_pitch(sound_fx)
