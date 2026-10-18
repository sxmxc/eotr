extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

func execute() -> void:
	gpu_particles_2d.finished.connect(queue_free, CONNECT_ONE_SHOT)
	gpu_particles_2d.restart()
