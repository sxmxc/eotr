extends Resource
class_name BattleStats

@export_range(0,2) var battle_tier: int
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var resource_reward_min: int
@export var resource_reward_max: int
@export var enemies: PackedScene
@export var battle_field_width: int
@export var battle_field_height: int
@export var enemy_gold_reward: int : set = _set_enemy_gold_reward
@export var enemy_resource_reward: int : set = _set_enemy_resource_reward

var accumlated_weight: float = 0.0

func roll_gold_reward() -> int:
	return RNG.instance.randi_range(gold_reward_min, gold_reward_max)

func roll_resource_reward() -> int:
	return RNG.instance.randi_range(resource_reward_min, resource_reward_max)

func _set_enemy_gold_reward(amount: int) -> void:
	enemy_gold_reward = amount
	Events.enemy_gold_bounty_collected.emit(amount)
	
func _set_enemy_resource_reward(amount: int) -> void:
	enemy_resource_reward = amount
	Events.enemy_resource_bounty_collected.emit(amount)
