class_name Obelisk
extends Enemy

const MOVING_ENEMY_SCENE = preload("res://scenes/enemy/moving_enemy.tscn")

@export var spawn_pool: Array[EnemyStats]
@export var enemy_handler: EnemyHandler


func spawn_enemy(_enemy: Enemy) -> void:
	pass


func spawn_random_enemy() -> void:
	var new_spawn = MOVING_ENEMY_SCENE.instantiate()
	var surrounding_cells = tilemap.get_surrounding_tiles_in_radius(current_tile_position, 2)
	var random_pos = surrounding_cells[RNG.instance.randi_range(0, surrounding_cells.size() - 1)]
	while !tilemap.is_tile_valid(random_pos):
		random_pos = surrounding_cells[RNG.instance.randi_range(0, surrounding_cells.size() - 1)]
	new_spawn.stats = RNG.array_pick_random(spawn_pool) as EnemyStats
	new_spawn.name = new_spawn.stats.enemy_name
	enemy_handler.add_enemy(new_spawn, random_pos)
	var world_message = WorldMessageData.new("Obelisk spawns a %s from the void" % new_spawn.stats.enemy_name)
	Events.world_message_requested.emit(world_message)

func do_death() -> void:
	Talo.stats.track("obelisks_destroyed")
	await get_tree().create_timer(.1).timeout
	queue_free()

func _on_area_2d_mouse_entered():
	super._on_area_2d_mouse_entered()
	
func _on_area_2d_mouse_exited():
	super._on_area_2d_mouse_exited()
