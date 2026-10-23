extends Card

const WEAKENED = preload("res://resources/data/statuses/weakened.tres")
const ENERGY_SOUND_FX = preload("res://assets/audio/spells/enchant.wav")
#const ENERGY_VISUAL_EFFECT = preload("res://ui/fx/token_shine_effect.tscn")

var energy_gained := 2

func _init() -> void:
	var weakened := WEAKENED.duplicate()
	var status_effect := CardEffectConfig.for_status(weakened)
	CardEffectConfigHelper.apply_card_defaults(self, status_effect, true)

	var energy_effect := CardEffectConfig.for_energy(energy_gained)
	energy_effect.sound_fx = ENERGY_SOUND_FX
	energy_effect.target = CardEffectConfig.Targeting.PLAYER

	effect_configs = [status_effect, energy_effect]


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass
