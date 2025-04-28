class_name ProjectileFX
extends Node2D

signal complete

@export var visual_fx: VisualFX

func execute(_target: Node, _source : Node = null) -> void:
	complete.emit()
	pass
