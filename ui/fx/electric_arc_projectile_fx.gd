extends ProjectileFX

@onready var electric_arc_fx: ElectricArcFX = $ElectricArcFX

func execute(target, _source = null) -> void:
	if not electric_arc_fx:
		force_complete_deferred()
		return
	electric_arc_fx.line_drawn.connect(_on_projectile_connect.bind(target), CONNECT_ONE_SHOT)
	electric_arc_fx.complete.connect(mark_complete, CONNECT_ONE_SHOT)
	# If strike fails (e.g., missing projectile_start), fail open and still emit complete so card resolution continues.
	var strike_ok: bool = electric_arc_fx.strike(target)
	if not strike_ok:
		force_complete_deferred()


func _on_projectile_connect(target: Node = null) -> void:
	play_visual_on_target(target)
	force_complete_deferred()
