extends ProjectileFX
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var start: Vector2
var end: Vector2
var speed: float = 600.0
var has_reached_target: bool = false
var is_initialized: bool = false

func execute(target) -> void:
	target.add_child(visual_fx)
	var player : Player = get_tree().get_first_node_in_group("player") as Player
	var fx_layer : CanvasLayer = get_tree().get_first_node_in_group("fx_layer")
	start = player.get_global_transform_with_canvas().origin + fx_layer.get_final_transform().origin
	end = get_tree().get_first_node_in_group("projectile_start").get_global_mouse_position()
	position = start
	print("blast striking: start %s end %s" % [start, end])
	
	# Start animation sequence
	animated_sprite_2d.animation_finished.connect(_on_start_animation_finished)
	animated_sprite_2d.play("start")
	is_initialized = true
	
func _physics_process(delta: float) -> void:
	if !is_initialized or has_reached_target:
		return
		
	var target_pos = end
	look_at(target_pos)
	
	# Move toward target
	var direction = (end - position).normalized()
	var distance_to_target = position.distance_to(end)
	var move_distance = speed * delta
	
	if move_distance >= distance_to_target:
		# We've reached the target
		position = end
		_on_projectile_reached_target()
	else:
		position += direction * move_distance

func _on_start_animation_finished():
	# Disconnect the previous signal
	animated_sprite_2d.animation_finished.disconnect(_on_start_animation_finished)
	
	# Connect the end animation signal and play loop animation
	animated_sprite_2d.play("loop")

func _on_projectile_reached_target():
	if has_reached_target:
		return
		
	has_reached_target = true
	
	# Stop movement and play end animation
	animated_sprite_2d.animation_finished.connect(_on_end_animation_finished)
	animated_sprite_2d.play("end")
	visual_fx.execute()
	complete.emit()

func _on_end_animation_finished():
	# Clean up
	animated_sprite_2d.animation_finished.disconnect(_on_end_animation_finished)
	
	# Here you might want to free the projectile or handle other cleanup
	queue_free()
