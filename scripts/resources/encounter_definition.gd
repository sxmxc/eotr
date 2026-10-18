extends Resource
class_name EncounterDefinition

enum VictoryObjective { ELIMINATE_HOSTILES, DESTROY_OBELISK }
@export var victory_objective: VictoryObjective = VictoryObjective.ELIMINATE_HOSTILES

@export_range(0,2) var battle_tier: int
@export_range(0.0, 10.0) var weight: float
var is_elite: bool:
	get:
		return category == Category.ELITE
@export var gold_reward_min: int
@export var gold_reward_max: int
@export var resource_reward_min: int
@export var resource_reward_max: int
@export var enemies: PackedScene
@export var battle_field_width: int
@export var battle_field_height: int
@export var enforce_start_tile_type: bool = false
@export var starting_tile_type: Enums.TileType = Enums.TileType.RESOURCE
@export var enemy_gold_reward: int : set = _set_enemy_gold_reward
@export var enemy_resource_reward: int : set = _set_enemy_resource_reward

enum Category { NORMAL, ELITE, BOSS, SPECIAL }
@export var encounter_id: String
@export var encounter_name: String
@export var category: Category = Category.NORMAL
@export var tags: Array[String] = ["act1"]
@export var unlocked := true
@export_range(0, 12) var minimum_player_distance := 2
@export_range(1, 8) var collapse_frequency := 3
# -1 keeps the existing constrained random shape selection.
@export_range(-1, 2) var arena_shape := -1
@export_range(0, 100) var corruption_weight := 20


func get_encounter_id() -> String:
	return encounter_id

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
