extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var gpu_particles_2d_3: GPUParticles2D = $GPUParticles2D3

func execute() -> void:
	var cam = get_tree().get_first_node_in_group("map_camera")
	Shaker.shake(cam,20)
	gpu_particles_2d_3.emitting = true
	gpu_particles_2d_3.finished.connect(queue_free)
