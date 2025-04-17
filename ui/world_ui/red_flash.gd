extends TextureRect

@onready var timer = $Timer

func _ready() -> void:
	Events.player_hit.connect(_on_player_hit)
	timer.timeout.connect(_on_timer_timeout)
	
func _on_player_hit() -> void:
	modulate.a = 0.5
	timer.start()
	
func _on_timer_timeout() -> void:
	modulate.a = 0.0
