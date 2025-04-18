extends Node
class_name EnemyAction

enum Type {CONDITIONAL, CHANCE_BASED}

@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0
@export var sound: AudioStream

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D

func is_performable() -> bool:
	return false
	
func perform_action() -> void:
	pass
