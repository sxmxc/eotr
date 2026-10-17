extends Card

const ATTUNEMENT = preload("res://resources/data/statuses/attunement.tres")

@export var base_amount := 1

func _init() -> void:
	_sync_effect_configs()


func get_default_description() -> String:
	return description % base_amount


func get_modified_description(
	_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler
) -> String:
	return description % base_amount


func _sync_effect_configs() -> void:
	var attunement := ATTUNEMENT.duplicate()
	attunement.stacks = base_amount
	var status_effect := CardEffectConfig.for_status(attunement)
	status_effect.sound_fx = sound_fx
	status_effect.visual_fx = visual_fx
	status_effect.target = CardEffectConfig.Targeting.PLAYER
	effect_configs = [status_effect]
