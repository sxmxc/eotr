extends Panel
class_name BattleOverPanel

const MAIN_MENU_PATH = "res://scenes/menus/main_menu.tscn"

enum Type { WIN, LOSE }

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	continue_button.pressed.connect(func(): Events.battle_won.emit())
	main_menu_button.pressed.connect(get_tree().change_scene_to_file.bind(MAIN_MENU_PATH))
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	if not is_inside_tree():
		return
	label.text = text
	continue_button.visible = type == Type.WIN
	main_menu_button.visible = type == Type.LOSE
	show()
	if SoundManager.is_sound_playing():
		await SoundManager.sound_effects.sound_finished
	get_tree().paused = true
