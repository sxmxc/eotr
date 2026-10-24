extends Control
## Coordinates one shared view offset; Parallax2D owns depth displacement.

@export var pointer_travel := Vector2(12.0, 7.0)
@export_range(0.1, 12.0) var response: float = 5.5
@export_range(1.02, 1.1) var overscan: float = 1.035

var _target := Vector2.ZERO
var _motion := Vector2.ZERO
var _pointer_active: bool = false
var _previous_pixel_snap: bool = false

@onready var _viewport: Viewport = get_viewport()

@onready var frame: Node2D = $Frame
@onready var pointer_layer: Parallax2D = $Frame/Ruins


func _ready() -> void:
	# Slow illustrated motion must retain subpixel positions. Restore the
	# gameplay viewport's pixel snapping when this menu leaves the tree.
	_previous_pixel_snap = _viewport.snap_2d_transforms_to_pixel
	_viewport.snap_2d_transforms_to_pixel = false
	resized.connect(_fit_artwork)
	get_window().mouse_exited.connect(_rest)
	get_window().focus_exited.connect(_rest)
	_fit_artwork()


func _exit_tree() -> void:
	if is_instance_valid(_viewport):
		_viewport.snap_2d_transforms_to_pixel = _previous_pixel_snap


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Use viewport input coordinates, not OS pointer polling. This also avoids
		# jumps when display scaling or window positioning changes.
		var pointer: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_pointer_active = Rect2(Vector2.ZERO, size).has_point(pointer)
		if _pointer_active:
			_target = (pointer / size * 2.0 - Vector2.ONE) * pointer_travel
		else:
			_rest()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_rest()


func _process(delta: float) -> void:
	if _pointer_active and not get_window().has_focus():
		_rest()
	_motion = _motion.lerp(_target, 1.0 - exp(-response * delta))
	pointer_layer.screen_offset = _motion / frame.scale.x


func _rest() -> void:
	_pointer_active = false
	_target = Vector2.ZERO


func _fit_artwork() -> void:
	var art_size := Vector2(1672.0, 941.0)
	var fit: float = maxf(size.x / art_size.x, size.y / art_size.y) * overscan
	frame.scale = Vector2.ONE * fit
	frame.position = (size - art_size * fit) * 0.5
	# Keep the obelisk tip inside the frame at the upper movement extreme.
	frame.position.y += size.y * 0.006
	_rest()
