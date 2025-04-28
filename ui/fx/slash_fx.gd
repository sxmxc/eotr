extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

func execute() -> void:
	gpu_particles_2d.emitting = true
	
