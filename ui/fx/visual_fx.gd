class_name VisualFX
extends Node2D

var source_actor: Node2D


static func play_on(target: Node2D, scene: PackedScene) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(target) or not scene:
		return
	var instance := scene.instantiate() as VisualFX
	target.add_child(instance)
	instance.execute()


func execute() -> void:
	pass
