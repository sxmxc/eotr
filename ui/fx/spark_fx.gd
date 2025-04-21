extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var gpu_particles_2d_3: GPUParticles2D = $GPUParticles2D3

func execute() -> void:
	gpu_particles_2d_3.emitting = true
	gpu_particles_2d.finished.connect(queue_free)
