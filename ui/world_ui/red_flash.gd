extends TextureRect

@onready var timer = $Timer
var flash: Tween

func _ready() -> void:
	Events.player_hit.connect(_on_player_hit)
	timer.timeout.connect(_on_timer_timeout)
	
func _on_player_hit() -> void:
	if flash and flash.is_valid():
		flash.kill()
	modulate.a = 0.5
	timer.start()
	flash = create_tween()
	flash.tween_property(self, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
func _on_timer_timeout() -> void:
	modulate.a = 0.0
