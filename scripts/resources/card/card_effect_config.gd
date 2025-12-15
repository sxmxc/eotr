extends Resource
class_name CardEffectConfig

enum EffectType { DAMAGE, BLOCK, MOVE, GATHER }
enum Targeting { CARD_TARGETS, PLAYER }

@export var effect_type: EffectType = EffectType.DAMAGE
@export var amount: int = 0
@export var receiver_modifier_type: Enums.ModifierType = Enums.ModifierType.DMG_TAKEN
@export var target: Targeting = Targeting.CARD_TARGETS
@export var projectile_fx: PackedScene
@export var projectile_visual_fx: PackedScene
@export var sound_fx: AudioStream
@export var visual_fx: PackedScene
var impact_profile: ImpactProfile
@export var direct_damage: bool = false
@export var attach_visual_to_effect: bool = true
@export var consume_resources_on_gather: bool = true
@export var camera_shake_strength: float = -1.0
@export var camera_shake_duration: float = 0.0


static func for_damage(base_amount: int) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.DAMAGE
	config.amount = base_amount
	return config


static func for_block(base_amount: int) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.BLOCK
	config.amount = base_amount
	return config


static func for_move() -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.MOVE
	config.target = Targeting.PLAYER
	return config


static func for_gather() -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.GATHER
	config.target = Targeting.PLAYER
	return config


func get_effect_amount(player_modifiers: ModifierHandler) -> int:
	match effect_type:
		EffectType.DAMAGE:
			if player_modifiers:
				return player_modifiers.get_modified_value(amount, Enums.ModifierType.DMG_DEALT)
			return amount
		EffectType.BLOCK:
			return amount
		_:
			return amount


func get_preview_amount(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> int:
	var value := get_effect_amount(player_modifiers)
	if effect_type == EffectType.DAMAGE and enemy_modifiers:
		value = enemy_modifiers.get_modified_value(value, Enums.ModifierType.DMG_TAKEN)
	return value


func should_use_player_targets() -> bool:
	return target == Targeting.PLAYER
