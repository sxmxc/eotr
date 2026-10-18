extends VisualFX

@export var persistent := false
var _fade: Tween

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func execute() -> void:
	if DisplayServer.get_name() == "headless":
		if persistent:
			hide()
		else:
			queue_free.call_deferred()
		return
	show()
	if _fade and _fade.is_valid():
		_fade.kill()
	sprite.modulate.a = 1.0
	sprite.stop()
	sprite.frame = 0
	var finish: Callable = hide if persistent else queue_free
	if not sprite.animation_finished.is_connected(finish):
		sprite.animation_finished.connect(finish, CONNECT_ONE_SHOT)
	sprite.play(&"default")
	var duration := float(sprite.sprite_frames.get_frame_count(&"default")) / sprite.sprite_frames.get_animation_speed(&"default")
	_fade = create_tween()
	_fade.tween_interval(duration * 0.75)
	_fade.tween_property(sprite, "modulate:a", 0.0, duration * 0.25)
