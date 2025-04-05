extends Panel
class_name BattleOverPanel

enum Type {WIN,LOSE}

@onready var label : Label = %Label
@onready var continue_button : Button = %ContinueButton
@onready var restart_button : Button = %RestartButton

func _ready() -> void:
	continue_button.pressed.connect(func(): Events.battle_won.emit())
	restart_button.pressed.connect(get_tree().reload_current_scene)
	Events.battle_over_screen_requested.connect(show_screen)
	
func show_screen(text: String, type: Type) -> void:
	label.text = text
	continue_button.visible = type == Type.WIN
	restart_button.visible = type == Type.LOSE
	show()
	if SoundManager.is_sound_playing():
		await SoundManager.sound_effects.sound_finished
	get_tree().paused = true
