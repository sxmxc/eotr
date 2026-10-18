extends VisualFX
class_name PhaseTraceFX

@export var texture: Texture2D
var texture_offset := Vector2.ZERO


func execute() -> void:
	$Sprite2D.texture = texture
	$Sprite2D.offset = texture_offset
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(queue_free)
