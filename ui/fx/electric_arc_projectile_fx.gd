extends ProjectileFX

@onready var electric_arc_fx: ElectricArcFX = $ElectricArcFX
var _completed := false

func execute(target, _source = null) -> void:
	if not electric_arc_fx:
		_emit_complete_deferred()
		return
	electric_arc_fx.line_drawn.connect(_on_projectile_connect.bind(target), CONNECT_ONE_SHOT)
	electric_arc_fx.complete.connect(_emit_complete, CONNECT_ONE_SHOT)
	# If strike fails (e.g., missing projectile_start), fail open and still emit complete so card resolution continues.
	var strike_ok: bool = electric_arc_fx.strike(target)
	if not strike_ok:
		_emit_complete_deferred()


func _on_projectile_connect(target: Node = null) -> void:
	if visual_fx and target:
		target.add_child(visual_fx)
		if visual_fx.has_method("execute"):
			visual_fx.execute()
	_emit_complete_deferred()


func _emit_complete_deferred() -> void:
	if _completed:
		return
	# Defer to ensure awaiters are connected before emitting.
	call_deferred("_emit_complete")


func _emit_complete() -> void:
	if _completed:
		return
	_completed = true
	print("[ProjectileFX] complete emitted")
	complete.emit()
