extends VisualFX
## Follow the actual move. Only the illustration phases; board/collision timing stays authoritative.
var actor_ref: WeakRef
var original_alpha := 1.0
var phase_tween: Tween
var movement_started := false
var phase_finished := false

func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free.call_deferred()
		return
	var actor := get_parent() as Player
	var board := get_tree().get_first_node_in_group("map_layer") as ProcGenTilemap
	if not actor or not board:
		queue_free()
		return
	actor_ref = weakref(actor.sprite_2d)
	original_alpha = actor.sprite_2d.self_modulate.a
	# World-space snapshots must stay behind while the owning player moves.
	top_level = true
	global_transform = Transform2D.IDENTITY
	board.player_position_updated.connect(_movement_started, CONNECT_ONE_SHOT)
	var deadline := create_tween()
	deadline.tween_interval(Utils.presentation_duration(0.45))
	deadline.tween_callback(queue_free)

func _movement_started(_destination: Vector2) -> void:
	movement_started = true
	var sprite := actor_ref.get_ref() as Sprite2D
	if not is_instance_valid(sprite):
		queue_free()
		return
	phase_tween = create_tween()
	phase_tween.tween_property(sprite, "self_modulate:a", original_alpha * 0.04, Utils.presentation_duration(0.045)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	phase_tween.tween_interval(Utils.presentation_duration(0.075))
	phase_tween.tween_property(sprite, "self_modulate:a", original_alpha, Utils.presentation_duration(0.08)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	phase_tween.tween_callback(func(): phase_finished = true)
	var echoes := create_tween()
	echoes.tween_interval(Utils.presentation_duration(0.04))
	echoes.tween_callback(_snapshot.bind($EarlyEcho))
	echoes.tween_interval(Utils.presentation_duration(0.06))
	echoes.tween_callback(_snapshot.bind($LateEcho))

func _snapshot(echo: Sprite2D) -> void:
	var sprite := actor_ref.get_ref() as Sprite2D
	if not is_instance_valid(sprite):
		return
	echo.texture = sprite.texture
	echo.offset = sprite.offset
	echo.centered = sprite.centered
	echo.flip_h = sprite.flip_h
	echo.flip_v = sprite.flip_v
	echo.hframes = sprite.hframes
	echo.vframes = sprite.vframes
	echo.frame = sprite.frame
	echo.region_enabled = sprite.region_enabled
	echo.region_rect = sprite.region_rect
	echo.global_transform = sprite.global_transform
	echo.material = echo.material.duplicate()
	echo.show()
	var fade := create_tween()
	fade.tween_method(func(value: float): echo.material.set_shader_parameter("dissolve", value), 0.0, 1.0, Utils.presentation_duration(0.18))
	fade.tween_callback(echo.hide)

func _exit_tree() -> void:
	# A completed old echo must not reset opacity during a subsequent Phase Step.
	if not actor_ref or not movement_started or phase_finished:
		return
	var sprite := actor_ref.get_ref() as Sprite2D
	if is_instance_valid(sprite):
		sprite.self_modulate.a = original_alpha
