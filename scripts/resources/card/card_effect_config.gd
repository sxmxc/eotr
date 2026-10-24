extends Resource
class_name CardEffectConfig

enum EffectType { DAMAGE, BLOCK, MOVE, GATHER, ENERGY, DRAW, STATUS, MULTI_DAMAGE, SUMMON, REPAIR, COMMAND, DISMANTLE, RELOCATE, FABRICATE }
enum Targeting { CARD_TARGETS, PLAYER, CONSTRUCTS, VISIBLE_ENEMIES, ADJACENT_ENEMIES }
enum ProjectileMode { AUTO, FIRST_TARGET_ONLY, EACH_TARGET_SEQUENTIAL, EACH_TARGET_PARALLEL }

@export var effect_type: EffectType = EffectType.DAMAGE
@export var amount: int = 0
@export var construct: ConstructDefinition
@export var consume_analyze: int = 0
@export var analyzed_bonus: int = 0
@export var receiver_modifier_type: Enums.ModifierType = Enums.ModifierType.DMG_TAKEN
@export var target: Targeting = Targeting.CARD_TARGETS
@export var projectile_fx: PackedScene
@export var projectile_visual_fx: PackedScene
@export var projectile_mode: ProjectileMode = ProjectileMode.AUTO
@export var projectile_spacing: float = 0.05
@export var projectile_timeout: float = 5.0
@export var sound_fx: AudioStream
@export var visual_fx: PackedScene
var impact_profile: ImpactProfile
@export var direct_damage: bool = false
@export var attach_visual_to_effect: bool = true
@export var consume_resources_on_gather: bool = true
@export var camera_shake_strength: float = -1.0
@export var camera_shake_duration: float = 0.0
# Status / multi-hit support
@export var status: Status
@export var hits: int = 1
@export var hit_interval: float = 0.0


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


static func for_energy(base_amount: int) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.ENERGY
	config.amount = base_amount
	config.target = Targeting.PLAYER
	return config


static func for_draw(base_amount: int) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.DRAW
	config.amount = base_amount
	config.target = Targeting.PLAYER
	return config


static func for_status(arg_status: Status) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.STATUS
	config.status = arg_status
	return config


static func for_multi_damage(base_amount: int, hit_count: int = 2, interval: float = 0.0) -> CardEffectConfig:
	var config := CardEffectConfig.new()
	config.effect_type = EffectType.MULTI_DAMAGE
	config.amount = base_amount
	config.hits = hit_count
	config.hit_interval = interval
	return config


func get_effect_amount(player_modifiers: ModifierHandler) -> int:
	match effect_type:
		EffectType.DAMAGE:
			if player_modifiers:
				return player_modifiers.get_modified_value(amount, Enums.ModifierType.DMG_DEALT)
			return amount
		EffectType.MULTI_DAMAGE:
			if player_modifiers:
				return player_modifiers.get_modified_value(amount, Enums.ModifierType.DMG_DEALT)
			return amount
		EffectType.BLOCK:
			return amount
		EffectType.ENERGY:
			return amount
		EffectType.DRAW:
			return amount
		_:
			return amount


func get_preview_amount(
	player_modifiers: ModifierHandler, enemy_modifiers: ModifierHandler
) -> int:
	var value := get_effect_amount(player_modifiers)
	if (effect_type == EffectType.DAMAGE or effect_type == EffectType.MULTI_DAMAGE) and enemy_modifiers:
		var stacks := AnalyzedStatus.count(enemy_modifiers.get_parent())
		value += stacks * consume_analyze if consume_analyze > 0 else stacks + (analyzed_bonus if stacks > 0 else 0)
		value = enemy_modifiers.get_modified_value(value, Enums.ModifierType.DMG_TAKEN)
	return value


func should_use_player_targets() -> bool:
	return target == Targeting.PLAYER
