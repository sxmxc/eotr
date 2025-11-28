extends VisualFX

@onready var particles: GPUParticles2D = $GPUParticles2D


func execute() -> void:
	particles.emitting = true
	particles.finished.connect(queue_free)
