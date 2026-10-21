extends Resource
class_name Status

signal status_applied(status: Status)
signal status_changed

@export_group("Status Data")
@export var id: String
@export var type: Enums.StatusType
@export var stack_type: Enums.StatusStackType
@export var can_expire: bool
@export var duration: int : set = set_duration
@export var stacks: int : set = set_stacks

@export_group("Status Visuals")
@export var icon: Texture2D
@export_multiline var tooltip: String

func initialize_status(_target: Node) -> void:
	pass


func remove_status(_target: Node) -> void:
	pass


func is_expired() -> bool:
	return (can_expire and duration <= 0) or (stack_type == Enums.StatusStackType.INTENSITY and stacks <= 0)
	
func apply_status(_target: Node) -> void:
	status_applied.emit(self)
	
func get_tooltip() -> String:
	return tooltip
	
func set_duration(new_duration: int) -> void:
	duration = new_duration
	status_changed.emit()

func set_stacks(new_stacks: int) -> void:
	stacks = new_stacks
	status_changed.emit()


func get_display_tooltip() -> String:
	var markup := RegEx.new()
	markup.compile("\\[[^\\]]*\\]")
	return id.capitalize() + "\n" + markup.sub(get_tooltip(), "", true).replace("%%", "%")
