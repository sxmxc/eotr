class_name TextFX
extends Control

@export var text: String : set = _set_text
@export var scale_size: Vector2
@export var float_height: Vector2
@export var duration: float = 1

@onready var label: Label = %Label

func _set_text(what) -> void:
	if not is_node_ready():
		await ready
	text = what

func execute() -> void:
	label.text = text
	label.pivot_offset = label.size * 0.5
	var tween := create_tween()
	# Present the value before it dissipates; avoid a growing translucent smear.
	var resting_scale := label.scale
	tween.tween_property(label, "scale", resting_scale * 1.6, duration * 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", resting_scale * 1.2, duration * 0.13).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position", label.position + float_height * 0.4, duration * 0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration * 0.42).set_delay(duration * 0.36)
	tween.tween_callback(queue_free)
