extends ProjectileFX

@onready var electric_arc_fx: ElectricArcFX = $ElectricArcFX

func execute(target) -> void:
	electric_arc_fx.line_drawn.connect(_on_projectile_connect)
	target.add_child(visual_fx)
	electric_arc_fx.strike()
	
	
	
func _on_projectile_connect() -> void:
	visual_fx.execute()
	complete.emit()
	
