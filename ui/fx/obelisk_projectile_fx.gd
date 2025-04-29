extends ProjectileFX
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D
var start: Vector2
var end: Vector2
var speed: float = 100.0
var has_reached_target: bool = false
var is_initialized: bool = false


func execute(target, source = null) -> void:
	target.add_child(visual_fx)
	start = source.global_position
	end = target.global_position
		
	
	position = start
	print("blast striking: start %s end %s" % [start, end])
	phantom_camera_2d.priority = 100
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
	phantom_camera_2d.priority = 0
	queue_free()
