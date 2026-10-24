extends Node2D
## Read-only board presentation. StatusHandler owns status application and expiry.
const STATUS_CHIP := preload("res://ui/world_ui/unit_status_chip.tscn")
var chips: Dictionary = {}
@onready var unit: Node2D = get_parent()
@onready var layout: VBoxContainer = $Layout
@onready var intent_panel: PanelContainer = %Intent
@onready var intent_icon: TextureRect = %IntentIcon
@onready var intent_label: Label = %IntentLabel
@onready var status_row: HBoxContainer = %Statuses
@onready var block_panel: PanelContainer = %Block
@onready var block_label: Label = %BlockLabel

func _process(_delta: float) -> void:
	if not is_instance_valid(unit) or not unit.is_node_ready():
		return
	if (unit is Enemy or unit is Construct) and unit.is_dying:
		hide()
		return
	show()
	_sync_intent()
	_sync_statuses()
	layout.reset_size()
	var block: int = unit.stats.block if unit.stats else 0
	block_panel.visible = block > 0
	block_label.text = str(block)
	%Health.visible = unit is Construct
	if unit is Construct:
		%HealthLabel.text = "%d/%d" % [unit.stats.health, unit.stats.max_health]
		%Health.tooltip_text = unit.definition.display_name + ": current / maximum health"
	var sprite := unit.get_node("Sprite2D") as Sprite2D
	if not sprite.texture:
		return
	# Constant screen size keeps symbols legible at tactical and overview zooms.
	var camera := get_viewport().get_camera_2d()
	var camera_zoom := camera.zoom.x if camera else 1.0
	global_scale = Vector2.ONE / camera_zoom
	global_rotation = 0.0
	var top := sprite.to_global(Vector2(0, sprite.get_rect().position.y))
	global_position = top - Vector2(0, (layout.size.y + 6.0) / camera_zoom)
	layout.position.x = -layout.size.x * 0.5

func _sync_intent() -> void:
	var plan: Intent = null
	if unit is Enemy and unit.current_action:
		plan = unit.current_action.intent
	elif unit is Construct:
		plan = unit.attack_intent
	intent_panel.visible = plan != null
	if not plan:
		return
	intent_icon.texture = plan.get_display_icon()
	intent_label.text = plan.get_display_text()
	# Movement/wait already have distinct glyphs; keep their words in the rail
	# and tooltip while reserving board labels for amounts and consequential plans.
	var quiet := intent_label.text in ["Move", "Wait", "Prepare"]
	intent_label.visible = not quiet
	intent_panel.theme_type_variation = &"BoardQuietIntentChip" if quiet else &"BoardIntentChip"
	%SecondaryIcon.visible = not plan.secondary_text.is_empty()
	%SecondaryLabel.visible = not plan.secondary_text.is_empty()
	%SecondaryIcon.texture = plan.secondary_icon
	%SecondaryLabel.text = plan.secondary_text
	intent_panel.tooltip_text = plan.get_description() + "\nCurrent plan; may change with position and conditions."

func _sync_statuses() -> void:
	var active: Array[Status] = []
	var handler: StatusHandler = unit.status_handler
	if is_instance_valid(handler):
		for status_ui: StatusUI in handler.get_children():
			var status := status_ui.status
			if not status or status_ui.is_queued_for_deletion():
				continue
			if (status.can_expire and status.duration <= 0) or (status.stack_type == Enums.StatusStackType.INTENSITY and status.stacks <= 0):
				continue
			active.append(status)
			if not chips.has(status):
				var chip := STATUS_CHIP.instantiate()
				status_row.add_child(chip)
				chip.bind_status(status)
				chips[status] = chip
	for status: Status in chips.keys():
		if not active.has(status):
			var chip: Control = chips[status]
			status_row.remove_child(chip)
			chip.queue_free()
			chips.erase(status)
	status_row.visible = not chips.is_empty()
