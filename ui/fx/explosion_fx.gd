extends VisualFX

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

func execute() -> void:
	show()
	var cam = get_tree().get_first_node_in_group("map_camera")
	Shaker.shake(cam,20)
	gpu_particles_2d.emitting = true
	gpu_particles_2d.finished.connect(queue_free)
