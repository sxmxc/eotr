extends Control

@onready var v_slider = $VSlider

func _ready():
	await get_tree().process_frame
	var cam = get_tree().get_first_node_in_group("map_camera") as MapCamera
	cam.zoom_changed.connect(_on_camera_zoom_changed)

func _on_camera_zoom_changed(zoom_value: float) -> void:
	#print("Camera zoom changed detected. New zoom: ", zoom_value)
	v_slider.value = zoom_value
