extends Area2D
class_name MapNodeUI

signal clicked(map_node: MapNode)
signal selected(map_node: MapNode)

@export var presentation_theme: Theme

@onready var line_2d: Line2D = $Visuals/Line2D
@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_current_position := false
var inspecting := false

var available := false:
	set = set_available
var map_node: MapNode:
	set = set_map_node


func set_available(new_value: bool) -> void:
	available = new_value
	if available:
		animation_player.play("highlight")
	elif not map_node.selected:
		animation_player.play("RESET")
	update_route_state(is_current_position)


func set_map_node(new_value: MapNode) -> void:
	map_node = new_value
	position = map_node.position
	line_2d.rotation_degrees = randi_range(0, 360)
	var kind: StringName = Enums.MapNodeType.keys()[map_node.type]
	sprite_2d.texture = presentation_theme.get_icon(kind, &"MapNode") if presentation_theme.has_icon(kind, &"MapNode") else null
	var scale_key := &"boss_icon_scale_percent" if map_node.type == Enums.MapNodeType.BOSS else &"icon_scale_percent"
	# Normalize mixed UI/entity source sizes to the theme's logical 512px canvas.
	var source_width := sprite_2d.texture.get_width() if sprite_2d.texture else 512
	sprite_2d.scale = Vector2.ONE * presentation_theme.get_constant(scale_key, &"MapNode") / 100.0 * 512.0 / source_width
	update_route_state(false)


func show_selected() -> void:
	line_2d.modulate = presentation_theme.get_color(&"selected", &"MapNode")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return
	select_route()


func select_route() -> bool:
	if not available or map_node.selected:
		return false
	map_node.selected = true
	clicked.emit(map_node)
	animation_player.play("select")
	return true


#Called by animation player "select"
func _on_map_node_selected() -> void:
	selected.emit(map_node)


func _ready() -> void:
	mouse_entered.connect(_inspect.bind(true))
	mouse_exited.connect(_inspect.bind(false))

func _inspect(value: bool) -> void:
	inspecting = value
	update_route_state(is_current_position)

func update_route_state(current: bool) -> void:
	is_current_position = current
	if not is_node_ready() or not map_node:
		return
	var state := ""
	if current:
		state = "Current"
	elif map_node.selected:
		state = "Cleared"
	elif available:
		state = "Available"
	var kind: String = Enums.MapNodeType.keys()[map_node.type].capitalize()
	if kind == "Monster":
		kind = "Battle"
	$RouteLabel.text = "%s\n%s" % [kind, state] if inspecting else (kind if available else state)
	$RouteLabel.visible = inspecting or available or map_node.selected
	z_index = 5 if inspecting else 0
	line_2d.modulate = presentation_theme.get_color(&"active", &"MapNode") if available or map_node.selected else presentation_theme.get_color(&"inactive_route", &"MapNode")
	line_2d.default_color = presentation_theme.get_color(&"cleared", &"MapNode") if map_node.selected else presentation_theme.get_color(&"available", &"MapNode")
	var accent := Color("d9b76f") if map_node.selected else Color("66d9c7")
	$RouteLabel.modulate = accent if available or map_node.selected else presentation_theme.get_color(&"text", &"MapNode")
	sprite_2d.modulate = Color.WHITE if available or map_node.selected or inspecting else presentation_theme.get_color(&"inactive_icon", &"MapNode")
