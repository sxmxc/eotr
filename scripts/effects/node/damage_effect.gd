extends NodeEffect
class_name DamageEffect

const TEXT_FX = preload("res://ui/fx/text_fx.tscn")

var amount := 0
var receiver_modifier_type := Enums.ModifierType.DMG_TAKEN
var direct := false
var impact_profile: ImpactProfile


func execute(targets: Array[Node]) -> void:
	var resolved_profile := impact_profile
	if not resolved_profile:
		resolved_profile = ImpactProfile.for_damage(max(amount, 0))

	for target in targets:
		if not target:
			continue
		if target is Enemy or target is Player:
			var pre_health : int = target.stats.health if target and target.stats else null
			var pre_block : int = target.stats.block if target and target.stats else null

			SoundManager.play_sound_random_pitch(sound_fx)
			if visual_fx != null:
				var visual_effect : VisualFX = visual_fx.instantiate()
				target.add_child(visual_effect)
				visual_effect.execute()
			target.take_damage(amount, receiver_modifier_type, direct, resolved_profile)
			if pre_health != null:
				print(
					"[DamageEffect] %s took %s (mod type %s, direct=%s) | health %s -> %s, block %s -> %s"
					% [
						target.name,
						amount,
						receiver_modifier_type,
						direct,
						pre_health,
						target.stats.health,
						pre_block,
						target.stats.block
					]
				)
			
