extends Control
class_name Rest

@export var player_stats: PlayerStats:
	set(value):
		player_stats = value
		if is_node_ready():
			_refresh_recovery()

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rest_button: Button = %RestButton
var leaving := false

func _ready() -> void:
	%RefineDeck.refined.connect(_on_skip_button_pressed)
	_refresh_recovery()

func _refresh_recovery() -> void:
	if not player_stats:
		return
	%RefineDeck.configure(player_stats)
	var amount := mini(ceili(player_stats.max_health * 0.3), player_stats.max_health - player_stats.health)
	%RecoveryAmount.text = "Restore %d HP" % amount
	%HealthPreview.text = "%d / %d HP now  ->  %d / %d HP after resting" % [player_stats.health, player_stats.max_health, player_stats.health + amount, player_stats.max_health]
	rest_button.text = "Rest and recover" if amount > 0 else "Rest at full health"

func _begin_leaving() -> bool:
	if leaving:
		return false
	leaving = true
	rest_button.disabled = true
	%SkipButton.disabled = true
	%RefineDeck.deactivate()
	return true


func _on_rest_button_pressed() -> void:
	if not _begin_leaving():
		return
	player_stats.heal(ceili(player_stats.max_health * 0.3))
	animation_player.play("fade_out")


#Called in animation player "fade out"
func _on_fade_out_finished() -> void:
	Events.rest_exited.emit()


func _on_skip_button_pressed() -> void:
	if not _begin_leaving():
		return
	animation_player.play("fade_out")
