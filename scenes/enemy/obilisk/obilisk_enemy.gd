class_name Obilisk
extends Enemy

const MOVING_ENEMY_SCENE = preload("res://scenes/enemy/moving_enemy.tscn")

@export var spawn_pool: Array[EnemyStats]
@export var enemy_handler: EnemyHandler


func spawn_enemy(_enemy: Enemy) -> void:
	pass


func spawn_random_enemy() -> void:
	var new_spawn = MOVING_ENEMY_SCENE.instantiate()
	var random_idx = RNG.instance.randi_range(0, spawn_pool.size() - 1)
	var surrounding_cells = tilemap.base_layer.get_surrounding_cells(current_tile_position)
	var random_pos = surrounding_cells[RNG.instance.randi_range(0, surrounding_cells.size() - 1)]
	new_spawn.stats = spawn_pool[random_idx]
	enemy_handler.add_enemy(new_spawn, random_pos)
	var world_message = WorldMessageData.new("Obilisk spawns a creature from the void")
	Events.world_message_requested.emit(world_message)
