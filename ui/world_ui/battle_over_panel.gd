extends Panel
class_name BattleOverPanel

const MAIN_MENU_PATH = "res://scenes/menus/main_menu.tscn"
const SHINE = preload("res://assets/audio/music/shine.wav")
const DEFEAT = preload("res://assets/audio/music/defeat.mp3")
const VIGNETTE_SHADER := preload("res://scripts/shaders/battle_over_vignette.gdshader")

enum Type { WIN, LOSE }

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var vignette_rect: ColorRect = %VignetteRect

var show_tween: Tween

const APPEAR_DURATION := 0.22
const APPEAR_SCALE := Vector2(0.92, 0.92)
const APPEAR_TRANS := Tween.TRANS_BACK
const APPEAR_EASE := Tween.EASE_OUT
const VIGNETTE_FADE := 0.28


func _ready() -> void:
	continue_button.pressed.connect(func(): Events.battle_won.emit())
	main_menu_button.pressed.connect(_main_menu_button_pressed)
	Events.battle_over_screen_requested.connect(show_screen)


func _play_battle_over_music(stream: AudioStream) -> void:
	var player := SoundManager.play_music(stream, 0)
	if player:
		player.stream_paused = false
		player.volume_db = 0
		if not player.is_playing():
			player.play()
		player.process_mode = Node.PROCESS_MODE_ALWAYS


func show_screen(text: String, type: Type) -> void:
	if not is_inside_tree():
		return
	if show_tween and show_tween.is_running():
		show_tween.kill()

	label.text = text
	continue_button.visible = type == Type.WIN
	main_menu_button.visible = type == Type.LOSE
	modulate = Color(1, 1, 1, 0)
	scale = APPEAR_SCALE
	_setup_vignette()
	show()
	match type:
		Type.WIN:
			_play_battle_over_music(SHINE)
		Type.LOSE:
			_play_battle_over_music(DEFEAT)
	show_tween = create_tween().set_trans(APPEAR_TRANS).set_ease(APPEAR_EASE)
	show_tween.tween_property(self, "modulate", Color.WHITE, APPEAR_DURATION)
	show_tween.parallel().tween_property(self, "scale", Vector2.ONE, APPEAR_DURATION)
	if is_instance_valid(vignette_rect):
		vignette_rect.modulate = Color(1, 1, 1, 0)
		show_tween.parallel().tween_property(vignette_rect, "modulate:a", 0.45, VIGNETTE_FADE)
	show_tween.tween_callback(func(): get_tree().paused = true)
	
func _main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _setup_vignette() -> void:
	if not is_instance_valid(vignette_rect):
		return
	if VIGNETTE_SHADER:
		var mat := ShaderMaterial.new()
		mat.shader = VIGNETTE_SHADER
		mat.set_shader_parameter("radius", 1.0)
		mat.set_shader_parameter("softness", 0.32)
		mat.set_shader_parameter("vignette_color", Color(0, 0, 0, 0.8))
		mat.set_shader_parameter("noise_amount", 0.08)
		mat.set_shader_parameter("noise_speed", 1.6)
		vignette_rect.material = mat
	vignette_rect.visible = true
