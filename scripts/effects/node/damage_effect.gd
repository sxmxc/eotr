extends NodeEffect
class_name DamageEffect

var amount := 0
var receiver_modifier_type := Enums.ModifierType.DMG_TAKEN


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			target.take_damage(amount, receiver_modifier_type)
			SoundManager.play_sound_random_pitch(sound_fx)
