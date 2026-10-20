extends ProjectileFX
## One flight path for authored projectile bodies, short actual-motion wakes and impacts.
@export var speed: float = 1550.0
@export var wake_color := Color(0.3, 0.86, 0.92, 0.55)
@export var release_fx: PackedScene = preload("res://ui/fx/arcane_release_signature.tscn")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var start := Vector2.ZERO
var end := Vector2.ZERO
var target_ref: WeakRef
var flying := false
var elapsed := 0.0
var travel_duration := 0.1
var wake: Line2D

func execute(target: Node, source: Node = null) -> void:
	if DisplayServer.get_name() == "headless":
		force_complete_deferred()
		queue_free.call_deferred()
		return
	target_ref = weakref(target) if is_instance_valid(target) else null
	start = resolve_start(source)
	end = resolve_end(target, start)
	global_position = start
	global_rotation = (end - start).angle()
	travel_duration = clampf(start.distance_to(end) / maxf(speed, 1.0), 0.075, 0.26)
	if source is Node2D and release_fx:
		var anchor := source.get_node_or_null("SpellOrigin")
		if not anchor:
			anchor = source
		var release := release_fx.instantiate() as VisualFX
		anchor.add_child(release)
		release.execute()
	wake = Line2D.new()
	wake.top_level = true
	wake.width = 5.0
	wake.width_curve = preload("res://resources/vfx/projectile_wake.tres")
	wake.default_color = wake_color
	wake.antialiased = true
	wake.z_index = -1
	add_child(wake)
	wake.global_transform = Transform2D.IDENTITY
	wake.add_point(start)
	animated_sprite_2d.animation_finished.connect(_animation_finished)
	# The projectile body is fully formed at release; the muzzle owns anticipation.
	animated_sprite_2d.play(&"loop")
	flying = true

func _physics_process(delta: float) -> void:
	if not flying:
		return
	elapsed += delta
	var t := minf(elapsed / travel_duration, 1.0)
	global_position = start.lerp(end, pow(t, 1.12))
	wake.add_point(global_position)
	while wake.get_point_count() > 2 and wake.points[0].distance_to(global_position) > 54.0:
		wake.remove_point(0)
	if t >= 1.0:
		flying = false
		var target: Node = target_ref.get_ref() if target_ref else null
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			play_visual_on_target(target)
		animated_sprite_2d.hide()
		mark_complete()
		var tail := create_tween()
		tail.tween_property(wake, "modulate:a", 0.0, 0.09)
		tail.tween_callback(queue_free)

func _animation_finished() -> void:
	if flying:
		animated_sprite_2d.play(&"loop")
