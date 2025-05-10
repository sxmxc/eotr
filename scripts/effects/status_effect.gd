extends Effect
class_name StatusEffect

var status : Status

func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			SoundManager.play_sound_random_pitch(sound_fx)
			if visual_fx:
				var fx : VisualFX = visual_fx.instantiate() as VisualFX
				target.add_child(fx)
				fx.execute()
			target.status_handler.add_status(status)
