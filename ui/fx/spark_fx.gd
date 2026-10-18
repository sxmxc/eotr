extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

func execute() -> void:
	gpu_particles_2d.finished.connect(queue_free, CONNECT_ONE_SHOT)
	gpu_particles_2d.restart()
	# GPU completion is unavailable with a headless rendering server.
	var deadline := create_tween()
	deadline.tween_interval(gpu_particles_2d.lifetime / maxf(gpu_particles_2d.speed_scale, 0.01) + 0.15)
	deadline.finished.connect(queue_free)
