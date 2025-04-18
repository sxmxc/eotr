extends NodeEffect
class_name BlockEffect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			target.stats.block += amount
			SoundManager.play_sound_random_pitch(sound_fx)
			if visual_fx != null:
				var visual_effect : VisualFX = visual_fx.instantiate()
				target.add_child(visual_effect)
				visual_effect.execute()
