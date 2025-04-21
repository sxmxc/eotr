class_name TextFX
extends Control

@export var text: String : set = _set_text
@export var scale_size: Vector2
@export var float_height: Vector2
@export var duration: float = 1

@onready var label: Label = %Label

func _set_text(what) -> void:
	if not ready:
		await ready
	text = what

func execute() -> void:
	label.text = text
	var tween = create_tween()
	tween.tween_property(label,"position", label.position + float_height, duration)
	tween.parallel().tween_property(label,"modulate", Color.TRANSPARENT, duration)
	tween.parallel().tween_property(label, "scale", scale_size, duration)
	tween.tween_callback(queue_free)
