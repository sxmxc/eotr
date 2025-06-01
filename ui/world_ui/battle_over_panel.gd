extends Panel
class_name BattleOverPanel

const MAIN_MENU_PATH = "res://scenes/menus/main_menu.tscn"
const SHINE = preload("res://assets/audio/music/shine.wav")
const DEFEAT = preload("res://assets/audio/music/defeat.mp3")

enum Type { WIN, LOSE }

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	continue_button.pressed.connect(func(): Events.battle_won.emit())
	main_menu_button.pressed.connect(_main_menu_button_pressed)
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	if not is_inside_tree():
		return
	label.text = text
	continue_button.visible = type == Type.WIN
	main_menu_button.visible = type == Type.LOSE
	show()
	match type:
		Type.WIN:
			SoundManager.play_music(SHINE,0)
		Type.LOSE:
			SoundManager.play_music(DEFEAT,0)
	get_tree().paused = true
	
func _main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
