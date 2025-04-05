extends NodeEffect
class_name DamageEffect

var amount := 0

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			target.take_damage(amount)
			SoundManager.play_sound_random_pitch(sound_fx)
