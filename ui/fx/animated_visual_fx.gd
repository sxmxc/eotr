extends VisualFX
## Scene-authored geometry and AnimationPlayer tracks own the presentation.

@export var source_ray: Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func execute() -> void:
	if DisplayServer.get_name() == "headless":
		queue_free.call_deferred()
		return
	var anchor := get_parent().get_node_or_null("ImpactAnchor") as Node2D
	if anchor:
		global_position = anchor.global_position
	if source_ray:
		var actor := source_actor
		if not is_instance_valid(actor):
			actor = get_tree().get_first_node_in_group("player") as Node2D
		source_ray.visible = is_instance_valid(actor) and actor != get_parent()
		if source_ray.visible:
			var origin := actor.get_node_or_null("SpellOrigin") as Node2D
			var offset := to_local(origin.global_position if origin else actor.global_position)
			source_ray.rotation = offset.angle()
			source_ray.scale.x = offset.length()
	animation_player.speed_scale = 1.0 / Utils.presentation_duration(1.0)
	animation_player.animation_finished.connect(func(_animation: StringName): queue_free(), CONNECT_ONE_SHOT)
	animation_player.play(&"play")
	animation_player.advance(0.0)
