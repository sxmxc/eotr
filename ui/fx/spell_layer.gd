extends AnimatedSprite2D
## An authored scene layer. Timing and transforms are independent of gameplay.
@export_range(0.0, 0.95) var begins := 0.0
@export_range(0.05, 1.0) var ends := 1.0
@export var drift := Vector2.ZERO
@export var final_scale := Vector2.ONE
@export var turn := 0.0
@export var first_frame := 0
@export var last_frame := 7
@export var reverse_frames := false
var rest_position: Vector2
var rest_scale: Vector2
var rest_rotation: float

func _ready() -> void:
	stop()
	rest_position = position
	rest_scale = scale
	rest_rotation = rotation

func sample(progress: float) -> void:
	visible = progress >= begins and progress < ends
	if not visible:
		return
	var t := clampf((progress - begins) / maxf(ends - begins, 0.01), 0.0, 1.0)
	var frame_t := 1.0 - t if reverse_frames else t
	frame = clampi(int(lerpf(float(first_frame), float(last_frame) + 0.99, pow(frame_t, 0.75))), 0, sprite_frames.get_frame_count(animation) - 1)
	position = rest_position + drift * (1.0 - pow(1.0 - t, 2.0))
	scale = rest_scale * Vector2.ONE.lerp(final_scale, t)
	rotation = rest_rotation + turn * t
	modulate.a = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.76, 1.0, t))
