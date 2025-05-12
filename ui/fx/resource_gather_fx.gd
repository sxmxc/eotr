class_name ResourceGatherFX
extends VisualFX

@export var quantity := 0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var quantity_label: Label = $QuantityLabel

func execute() -> void:
	if quantity > 1:
		quantity_label.text = str(quantity)
		quantity_label.show()
	else:
		quantity_label.hide()
	animation_player.animation_finished.connect(func(_args): queue_free())
	animation_player.play("grow_out")
	pass
