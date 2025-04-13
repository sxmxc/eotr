extends Control
class_name Rest

@export var player_stats: PlayerStats

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rest_button: Button = %RestButton


func _on_rest_button_pressed() -> void:
	rest_button.disabled = true
	player_stats.heal(ceili(player_stats.max_health * 0.3))
	animation_player.play("fade_out")


#Called in animation player "fade out"
func _on_fade_out_finished() -> void:
	Events.rest_exited.emit()
