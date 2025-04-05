extends Area2D
class_name MapNodeUI

signal selected(map_node: MapNode)

const ICONS := {
	Enums.MapNodeType.NOT_ASSIGNED: [null, Vector2.ONE],
	Enums.MapNodeType.MONSTER: [preload("res://assets/icons/portal.svg"), Vector2(0.1,0.1)],
	Enums.MapNodeType.TREASURE: [preload("res://assets/icons/chest.svg"), Vector2(0.1, 0.1)],
	Enums.MapNodeType.REST: [preload("res://assets/icons/night-sleep.svg"), Vector2(0.1, 0.1)],
	Enums.MapNodeType.SHOP: [preload("res://assets/icons/pay-money.svg"), Vector2(0.1,0.1)],
	Enums.MapNodeType.BOSS: [preload("res://assets/icons/overlord-helm.svg"), Vector2(0.2,0.2)]
}

@onready var line_2d: Line2D = $Visuals/Line2D
@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var map_node : MapNode : set = set_map_node

func set_available(new_value: bool) -> void:
	available = new_value
	if available:
		animation_player.play("highlight")
	elif not map_node.selected:
		animation_player.play("RESET")
		
func set_map_node(new_value: MapNode) -> void:
	map_node = new_value
	position = map_node.position
	line_2d.rotation_degrees = randi_range(0,360)
	sprite_2d.texture = ICONS[map_node.type][0]
	sprite_2d.scale = ICONS[map_node.type][1]

func show_selected() -> void:
	line_2d.modulate = Color.WHITE

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return
	map_node.selected = true
	animation_player.play("select")

#Called by animation player "select"
func _on_map_node_selected() -> void:
	selected.emit(map_node)
