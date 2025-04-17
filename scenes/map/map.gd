class_name Map
extends Node2D

const SCROLL_SPEED := 15
const MAP_NODE_UI_SCENE = preload("res://scenes/map/map_node_ui.tscn")
const MAP_NODE_LINE_SCENE = preload("res://scenes/map/map_node_line.tscn")

@onready var visuals: Node2D = %Visuals
@onready var lines: Node2D = %Lines
@onready var map_nodes: Node2D = %MapNodes
@onready var camera_2d: Camera2D = %Camera2D
@onready var map_generator: MapGenerator = $MapGenerator
@onready var ui_layer: CanvasLayer = $UILayer

var map_data: Array[Array]
var floors_climbed: int
var last_map_node: MapNode
var camera_edge_y: float


func _ready() -> void:
	camera_edge_y = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("scroll_up"):
		camera_2d.position.y -= SCROLL_SPEED
	elif event.is_action_pressed("scroll_down"):
		camera_2d.position.y += SCROLL_SPEED

	camera_2d.position.y = clamp(camera_2d.position.y, -camera_edge_y, 0)


func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()


func load_map(map: Array[Array], floors_completed: int, last_map_node_climbed: MapNode) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_map_node = last_map_node_climbed
	create_map()

	if floors_climbed > 0:
		unlock_next_map_node()
	else:
		unlock_floor()


func create_map() -> void:
	for current_floor: Array in map_data:
		for map_node: MapNode in current_floor:
			if map_node.next_nodes.size() > 0:
				_spawn_map_node(map_node)
	var middle := floori(MapGenerator.MAP_WIDTH * .5)
	_spawn_map_node(map_data[MapGenerator.FLOORS - 1][middle])

	var map_width_pixels := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	visuals.position.y = get_viewport_rect().size.y / 2


func unlock_floor(which: int = floors_climbed) -> void:
	for map_node_ui: MapNodeUI in map_nodes.get_children():
		if map_node_ui.map_node.row == which:
			map_node_ui.available = true


func unlock_next_map_node() -> void:
	for map_node_ui: MapNodeUI in map_nodes.get_children():
		if last_map_node.next_nodes.has(map_node_ui.map_node):
			map_node_ui.available = true


func show_map() -> void:
	show()
	ui_layer.show()
	camera_2d.enabled = true


func hide_map() -> void:
	hide()
	ui_layer.hide()
	camera_2d.enabled = false


func _spawn_map_node(map_node: MapNode) -> void:
	var new_map_node_ui := MAP_NODE_UI_SCENE.instantiate() as MapNodeUI
	map_nodes.add_child(new_map_node_ui)
	new_map_node_ui.map_node = map_node
	new_map_node_ui.clicked.connect(_on_map_node_ui_clicked)
	new_map_node_ui.selected.connect(_on_map_node_ui_selected)
	_connect_lines(map_node)

	if map_node.selected and map_node.row < floors_climbed:
		new_map_node_ui.show_selected()


func _connect_lines(map_node: MapNode) -> void:
	if map_node.next_nodes.is_empty():
		return

	for next: MapNode in map_node.next_nodes:
		var new_map_line := MAP_NODE_LINE_SCENE.instantiate() as Line2D
		new_map_line.add_point(map_node.position)
		new_map_line.add_point(next.position)
		lines.add_child(new_map_line)


func _on_map_node_ui_selected(map_node: MapNode) -> void:
	last_map_node = map_node
	floors_climbed += 1
	Events.map_exited.emit(map_node)


func _on_map_node_ui_clicked(map_node: MapNode) -> void:
	SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
	for map_node_ui: MapNodeUI in map_nodes.get_children():
		if map_node_ui.map_node.row == map_node.row:
			map_node_ui.available = false
