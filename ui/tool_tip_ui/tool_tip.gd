extends PanelContainer
class_name Tooltip

@export var fade_seconds := 0.2
@onready var tooltip_text_label = %TooltipTextLabel

var tween: Tween
var _visible: bool

func _ready() -> void:
	Events.card_tooltip_requested.connect(show_tooltip)
	Events.tooltip_hide_requested.connect(hide_tooltip)
	modulate = Color.TRANSPARENT
	hide()
	
func show_tooltip(data: TooltipData) -> void:
	_visible = true
	if tween:
		tween.kill()
		
	tooltip_text_label.text = data.description
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(show)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)

func hide_tooltip() -> void:
	_visible = false
	if tween:
		tween.kill()
		
	get_tree().create_timer(fade_seconds,false).timeout.connect(hide_animation)
	
func hide_animation() -> void:
	if !_visible:
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
		tween.tween_callback(hide)
