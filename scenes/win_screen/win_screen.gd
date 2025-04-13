class_name WinScreen
extends Control

const MAIN_MENU_SCENE = "res://scenes/menus/main_menu.tscn"

const TITLE := "The %s is victorious!"

@export var player_stats: PlayerStats:
	set = set_player

@onready var win_title: Label = %WinTitle
@onready var class_icon: TextureRect = %ClassIcon
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	if not main_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)


func set_player(new_character: PlayerStats) -> void:
	if not is_node_ready():
		await ready
	player_stats = new_character
	win_title.text = TITLE % player_stats.player_class_name
	class_icon.texture = player_stats.board_icon


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
