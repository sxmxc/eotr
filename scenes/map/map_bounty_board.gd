extends Control
class_name MapBountyBoard

@onready var _panel: Panel = _build_panel()
@onready var _title: Label = _build_title()
@onready var _body: RichTextLabel = _build_body()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -420
	offset_top = 20
	offset_right = -20
	offset_bottom = 220
	custom_minimum_size = Vector2(360, 180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hide()


func update_bounties(nodes: Array[MapNode], arg_floor: int) -> void:
	if nodes.is_empty():
		hide()
		return
	var lines: Array[String] = []
	var slot := 1
	for node in nodes:
		if not node.battle_stats:
			continue
		var bs := node.battle_stats
		var gold_range := "%d-%d" % [bs.gold_reward_min, bs.gold_reward_max + bs.enemy_gold_reward]
		var res_range := "%d-%d" % [bs.resource_reward_min, bs.resource_reward_max + bs.enemy_resource_reward]
		var tag := _describe_node(node)
		lines.append("[b]%d.[/b] %s — Gold %s, Resources %s" % [slot, tag, gold_range, res_range])
		slot += 1
	if lines.is_empty():
		hide()
		return
	_title.text = "Available Bounties — Floor %d" % arg_floor
	_body.text = "\n".join(lines)
	show()


func _describe_node(node: MapNode) -> String:
	var node_name: String = str(Enums.MapNodeType.keys()[node.type])
	if node.battle_stats and node.battle_stats.is_elite:
		node_name = "Elite Battle"
	elif node.type == Enums.MapNodeType.MONSTER:
		node_name = "Battle"
	return node_name


func _build_title() -> Label:
	var label := Label.new()
	label.name = "Title"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	_panel.add_child(label)
	return label


func _build_body() -> RichTextLabel:
	var text := RichTextLabel.new()
	text.name = "Body"
	text.bbcode_enabled = true
	text.fit_content = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.scroll_active = false
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.offset_top = 24
	_panel.add_child(text)
	return text


func _build_panel() -> Panel:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.theme_type_variation = &"HudPanelMain"
	panel.anchors_preset = Control.PRESET_FULL_RECT
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(panel)
	return panel
