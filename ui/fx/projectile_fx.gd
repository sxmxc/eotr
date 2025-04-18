class_name ProjectileFX
extends Node2D

signal complete

@export var visual_fx: VisualFX

func execute(_target: Node) -> void:
	complete.emit()
	pass
