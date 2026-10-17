extends CanvasLayer
class_name BattlePresentation

signal finished

@export var intro_text := "Engage"
@export var win_text := "Victory"
@export var lose_text := "Defeat"
@export_group("Presentation")
@export var intro_tint: Color
@export var win_tint: Color
@export var lose_tint: Color
@onready var _vignette: ColorRect = $BattleVignette
@onready var _label: Label = $BattleVignette/BeatLabel

var _tween: Tween


func _ready() -> void:
	_label.text = intro_text
	hide()


func play_intro() -> void:
	_reset_overlay(intro_tint)
	_label.text = intro_text
	_label.modulate = Color(1, 1, 1, 0)
	_run_sequence(0.18, 0.22)


func play_outro(is_win: bool) -> void:
	var tint: Color
	if is_win:
		tint = win_tint
	else:
		tint = lose_tint
	_reset_overlay(tint)
	if is_win:
		_label.text = win_text
	else:
		_label.text = lose_text
	_label.modulate = Color(1, 1, 1, 0)
	_run_sequence(0.2, 0.28)


func _run_sequence(fade_in: float, fade_out: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_vignette.modulate.a = 0.0
	show()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(_vignette, "modulate:a", 1.0, fade_in)
	_tween.parallel().tween_property(_label, "modulate:a", 1.0, fade_in)
	_tween.tween_interval(0.05)
	_tween.tween_property(_vignette, "modulate:a", 0.0, fade_out)
	_tween.parallel().tween_property(_label, "modulate:a", 0.0, fade_out)
	_tween.tween_callback(_finish)


func _finish() -> void:
	hide()
	finished.emit()


func _reset_overlay(tint: Color) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_vignette.modulate = Color.WHITE
	if _vignette.material and _vignette.material is ShaderMaterial:
		var mat := _vignette.material as ShaderMaterial
		mat.set_shader_parameter("effect_color", tint)
