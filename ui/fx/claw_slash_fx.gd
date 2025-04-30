extends VisualFX

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func execute() -> void:
	animation_player.animation_finished.connect(func(_arg): queue_free())
	animation_player.play("slash_grow")
	
