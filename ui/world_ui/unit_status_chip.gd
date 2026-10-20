extends PanelContainer

var status: Status
@onready var icon: TextureRect = %Icon
@onready var count: Label = %Count

func bind_status(value: Status) -> void:
	status = value
	status.status_changed.connect(refresh)
	refresh()

func refresh() -> void:
	icon.texture = status.icon
	count.visible = status.stack_type != Enums.StatusStackType.NONE
	count.text = str(status.duration if status.stack_type == Enums.StatusStackType.DURATION else status.stacks)
	tooltip_text = status.get_display_tooltip()
	if status.stack_type == Enums.StatusStackType.DURATION:
		tooltip_text += "\nCount: turns remaining."
	elif status.stack_type == Enums.StatusStackType.INTENSITY:
		tooltip_text += "\nCount: stacks."
