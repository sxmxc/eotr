extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@export var impact_scene: PackedScene

func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free.call_deferred()
		return
	if get_parent() is Node2D and get_parent().has_node("ImpactAnchor") and position.is_zero_approx():
		position = get_parent().get_node("ImpactAnchor").position
	if impact_scene:
		var impact := impact_scene.instantiate() as VisualFX
		add_child(impact)
		impact.execute()
	gpu_particles_2d.finished.connect(queue_free, CONNECT_ONE_SHOT)
	gpu_particles_2d.restart()
	# GPU completion is unavailable with a headless rendering server.
	var deadline := create_tween()
	deadline.tween_interval(gpu_particles_2d.lifetime / maxf(gpu_particles_2d.speed_scale, 0.01) + 0.15)
	deadline.finished.connect(queue_free)
