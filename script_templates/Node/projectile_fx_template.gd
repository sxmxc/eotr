# meta-name: Projectile FX
# meta-description: A projectile FX that can be used by cards, abilities, etc..
class_name ProjectileFXTemplate
extends ProjectileFX

func execute(_target: Node, _source : Node = null) -> void:
	complete.emit()
	pass
