extends TextureButton
class_name ThemedIconButton

var _mouse_inside := false


func _ready() -> void:
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_refresh_icon_tint)
	focus_exited.connect(_refresh_icon_tint)
	button_down.connect(_refresh_icon_tint)
	button_up.connect(_refresh_icon_tint)
	theme_changed.connect(_refresh_icon_tint)
	_refresh_icon_tint()


func _on_mouse_entered() -> void:
	_mouse_inside = true
	_refresh_icon_tint()


func _on_mouse_exited() -> void:
	_mouse_inside = false
	_refresh_icon_tint()


func _refresh_icon_tint() -> void:
	var state: StringName = &"normal"
	if disabled:
		state = &"disabled"
	elif is_pressed():
		state = &"pressed"
	elif _mouse_inside or has_focus():
		state = &"hover"
	self_modulate = get_theme_color(state, &"IconButton")
