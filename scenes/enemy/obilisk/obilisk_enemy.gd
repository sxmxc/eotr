extends Enemy
class_name Obilisk

const MOVING_ENEMY_SCENE = preload("res://scenes/enemy/moving_enemy.tscn")

@export var spawn_pool : Array[EnemyStats]
@export var enemy_handler: EnemyHandler

func spawn_enemy(_enemy: Enemy) -> void:
	pass
	
func spawn_random_enemy() -> void:
	pass
