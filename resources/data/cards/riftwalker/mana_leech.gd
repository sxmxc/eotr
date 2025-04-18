extends Card

const WEAKENED = preload("res://resources/data/statuses/weakened.tres")
const ENERGY_SOUND_FX = preload("res://assets/audio/spells/enchant.wav")
#const ENERGY_VISUAL_EFFECT = preload("res://ui/fx/token_shine_effect.tscn")

var energy_gained := 2


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var status_effect = StatusEffect.new()
	var energy_effect = EnergyEffect.new()
	var weakened := WEAKENED.duplicate()
	var curse_fx : VisualFX = visual_fx.instantiate()
	targets[0].add_child(curse_fx)
	status_effect.status = weakened
	status_effect.sound_fx = sound_fx
	status_effect.execute(targets)
	curse_fx.execute()
	energy_effect.amount = energy_gained
	energy_effect.sound_fx = ENERGY_SOUND_FX
	#energy_effect.visual_fx = ENERGY_VISUAL_EFFECT
	var player_array = targets[0].get_tree().get_nodes_in_group("player")
	energy_effect.execute(player_array)
