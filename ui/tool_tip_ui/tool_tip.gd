extends PanelContainer
class_name Tooltip

@export var fade_seconds := 0.2
@onready var tooltip_text_label = %TooltipTextLabel
@onready var keyword_text_label: RichTextLabel = %KeywordTextLabel

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
		
	tooltip_text_label.text = _build_tooltip_text(data)
	_update_keyword_text(data)
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


func _build_tooltip_text(data: TooltipData) -> String:
	return data.description


func _update_keyword_text(data: TooltipData) -> void:
	if data.keyword_tooltips.is_empty():
		keyword_text_label.hide()
		keyword_text_label.text = ""
		return

	var keyword_text := "[b]Keywords[/b]\n"
	for keyword_data: Dictionary in data.keyword_tooltips:
		var keyword := keyword_data.get("keyword", "") as String
		var keyword_description := keyword_data.get("text", "") as String
		if keyword == "" or keyword_description == "":
			continue
		keyword_text += "[b]%s[/b]: %s\n" % [keyword, keyword_description]

	keyword_text_label.text = keyword_text.strip_edges()
	keyword_text_label.show()
