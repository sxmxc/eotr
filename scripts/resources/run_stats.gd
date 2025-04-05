extends Resource
class_name RunStats

signal gold_changed
signal resources_changed

const STARTING_GOLD := 70
const STARTING_RESOURCES := 0
const BASE_CARD_REWARDS := 3
const BASE_COMMON_WEIGHT := 6.0
const BASE_UNCOMMON_WEIGHT := 3.7
const BASE_RARE_WEIGHT := 0.3

@export var gold := STARTING_GOLD : set = set_gold
@export var resources := STARTING_RESOURCES : set = set_resources
@export var card_rewards := BASE_CARD_REWARDS
@export_range(0.0, 10.0) var common_weight := BASE_COMMON_WEIGHT
@export_range(0.0, 10.0) var uncommon_weight := BASE_UNCOMMON_WEIGHT 
@export_range(0.0, 10.0) var rare_weight := BASE_RARE_WEIGHT 


func set_gold(value : int) -> void:
	gold = value
	gold_changed.emit()
	
func set_resources(value: int) -> void:
	resources = value
	resources_changed.emit()

func reset_weights() -> void:
	common_weight = BASE_COMMON_WEIGHT
	uncommon_weight = BASE_UNCOMMON_WEIGHT
	rare_weight = BASE_RARE_WEIGHT
