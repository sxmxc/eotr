extends ProjectileFX

@onready var electric_arc_fx: ElectricArcFX = $ElectricArcFX

func execute(target, source = null) -> void:
	if not electric_arc_fx:
		force_complete_deferred()
		return
	electric_arc_fx.line_drawn.connect(_on_projectile_connect.bind(target), CONNECT_ONE_SHOT)
	electric_arc_fx.complete.connect(_on_arc_complete, CONNECT_ONE_SHOT)
	# If strike fails (e.g., missing projectile_start), fail open and still emit complete so card resolution continues.
	var strike_ok: bool = electric_arc_fx.strike(target, source as Node2D)
	if not strike_ok:
		force_complete_deferred()
		call_deferred("queue_free")


func _on_arc_complete() -> void:
	mark_complete()
	queue_free()


func _on_projectile_connect(target: Node = null) -> void:
	play_visual_on_target(target)
	force_complete_deferred()
