extends CanvasLayer
class_name BattlePresentation

const VIGNETTE_SHADER := preload("res://scripts/shaders/dark_noise_vignette.gdshader")

@export var intro_text := "Engage"
@export var win_text := "Victory"
@export var lose_text := "Defeat"
@export var layer_index := 9

@onready var _vignette: ColorRect = _build_vignette()
@onready var _label: Label = _build_label()

var _tween: Tween


func _ready() -> void:
	layer = layer_index
	hide()


func play_intro(audio_player: AudioStreamPlayer = null) -> void:
	_reset_overlay(Color(0.05, 0.05, 0.08, 0.65))
	_label.text = intro_text
	_label.scale = Vector2(1.08, 1.08)
	_label.modulate = Color(1, 1, 1, 0)
	_run_audio_swell(audio_player, -4.0, 0.16, 0.28)
	_run_sequence(0.18, 0.22)


func play_outro(is_win: bool, audio_player: AudioStreamPlayer = null) -> void:
	var tint: Color
	if is_win:
		tint = Color(0.16, 0.32, 0.28, 0.7)
	else:
		tint = Color(0.35, 0.12, 0.12, 0.75)
	_reset_overlay(tint)
	if is_win:
		_label.text = win_text
	else:
		_label.text = lose_text
	_label.scale = Vector2(1.1, 1.1)
	_label.modulate = Color(1, 1, 1, 0)
	_run_audio_swell(audio_player, -6.0, 0.2, 0.32)
	_run_sequence(0.2, 0.28)


func _run_sequence(fade_in: float, fade_out: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	show()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_vignette, "modulate:a", _vignette.modulate.a, fade_in).from(0.0)
	_tween.parallel().tween_property(_label, "modulate:a", 1.0, fade_in)
	_tween.parallel().tween_property(_label, "scale", Vector2.ONE, fade_in)
	_tween.tween_interval(0.05)
	_tween.tween_property(_vignette, "modulate:a", 0.0, fade_out)
	_tween.parallel().tween_property(_label, "modulate:a", 0.0, fade_out)
	_tween.tween_callback(func(): hide())


func _run_audio_swell(
	audio_player: AudioStreamPlayer,
	drop_db: float,
	dip_duration: float,
	rise_duration: float
) -> void:
	if not audio_player:
		return
	var start_db := audio_player.volume_db
	var target_db := clampf(start_db + drop_db, -40.0, start_db)
	var audio_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	audio_tween.tween_property(audio_player, "volume_db", target_db, dip_duration)
	audio_tween.tween_property(audio_player, "volume_db", start_db, rise_duration)


func _reset_overlay(tint: Color) -> void:
	_vignette.modulate = tint
	if _vignette.material and _vignette.material is ShaderMaterial:
		var mat := _vignette.material as ShaderMaterial
		mat.set_shader_parameter("effect_color", tint)
		mat.set_shader_parameter("radius", 1.0)
		mat.set_shader_parameter("speed", 1.5)


func _build_vignette() -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "BattleVignette"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchors_preset = Control.PRESET_FULL_RECT
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rect.color = Color(0, 0, 0, 0)
	if VIGNETTE_SHADER:
		var mat := ShaderMaterial.new()
		mat.shader = VIGNETTE_SHADER
		mat.set_shader_parameter("radius", 1.0)
		mat.set_shader_parameter("effect_color", Color(0.05, 0.05, 0.08, 0.65))
		mat.set_shader_parameter("speed", 1.5)
		rect.material = mat
	add_child(rect)
	return rect


func _build_label() -> Label:
	var label := Label.new()
	label.name = "BeatLabel"
	label.text = intro_text
	label.modulate = Color(1, 1, 1, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(0.82, 0.79, 0.64, 0.92))
	_vignette.add_child(label)
	return label
