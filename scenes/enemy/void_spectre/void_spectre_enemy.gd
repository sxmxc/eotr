class_name VoidSpectreEnemy
extends MovingEnemy


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func do_death() -> void:
	if not _begin_death_sequence():
		return
	TelemetryManager.track_stat("bosses_defeated")
	_fade_out_and_queue_free(0.5)
