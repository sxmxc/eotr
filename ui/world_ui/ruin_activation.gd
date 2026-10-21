extends Node2D

@export var duration := 0.45
@export var rise := 5.0

func _ready() -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property($Columns, "position:y", -rise, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
