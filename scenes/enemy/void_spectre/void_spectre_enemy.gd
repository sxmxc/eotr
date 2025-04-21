class_name VoidSpectreEnemy
extends MovingEnemy


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func do_death() -> void:
	Talo.stats.track("bosses_defeated")
	await get_tree().create_timer(.5).timeout
	queue_free()
