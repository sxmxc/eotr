extends Control
class_name EventRoom

const EVENTS := [
	{
		"title": "Rift Echo",
		"body": "A low hum vibrates through the stones. A fracture in the air offers raw aether if you dare to reach through.",
		"options": [
			{"label": "Reach in (-4 HP, +1 resource)", "action": "_option_rift_risk"},
			{"label": "Harvest fragments (+20 gold)", "action": "_option_rift_harvest"}
		]
	},
	{
		"title": "Drifter Caravan",
		"body": "Nomads wave you over to trade. Their packs hold worn supplies and jars of salve.",
		"options": [
			{"label": "Trade 10 gold for a salve (+6 HP)", "action": "_option_caravan_heal", "gold_cost": 10},
			{"label": "Trade 1 resource for intel (better uncommon and rare card odds)", "action": "_option_caravan_intel", "resource_cost": 1}
		]
	},
	{
		"title": "Fallen Scout",
		"body": "A scout’s satchel is buried near a broken obelisk shard. The journal inside lists current bounty prices.",
		"options": [
			{"label": "Claim the satchel (+25 gold, +1 resource)", "action": "_option_scout_claim"},
			{"label": "Lay them to rest (+8 HP)", "action": "_option_scout_rest"}
		]
	}
]

@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var option_a_button: Button = %OptionAButton
@onready var option_b_button: Button = %OptionBButton
@onready var leave_button: Button = %LeaveButton

var player_stats: PlayerStats
var run_stats: RunStats
var relic_handler: RelicHandler
var _current_event: Dictionary
var _choice_made := false


func setup_event(player: PlayerStats, run: RunStats, relics: RelicHandler) -> void:
	if run_stats:
		run_stats.gold_changed.disconnect(_refresh_options)
		run_stats.resources_changed.disconnect(_refresh_options)
	player_stats = player
	run_stats = run
	relic_handler = relics
	run_stats.gold_changed.connect(_refresh_options)
	run_stats.resources_changed.connect(_refresh_options)
	_roll_event()


func _ready() -> void:
	option_a_button.pressed.connect(_on_option_a_pressed)
	option_b_button.pressed.connect(_on_option_b_pressed)
	leave_button.pressed.connect(_leave_event)
	hide()


func _roll_event() -> void:
	if EVENTS.is_empty():
		return
	var index := RNG.instance.randi_range(0, EVENTS.size() - 1)
	_current_event = EVENTS[index]
	_populate_event()
	show()


func _populate_event() -> void:
	_choice_made = false
	%OutcomeLabel.text = ""
	%Hint.text = "You may leave without making a choice."
	leave_button.text = "Return to the path"
	title_label.text = _current_event.get("title", "Unknown Event")
	body_label.text = _current_event.get("body", "")
	_refresh_options()
	leave_button.disabled = false


func _refresh_options() -> void:
	var options: Array = _current_event.get("options", [])
	var buttons: Array[Button] = [option_a_button, option_b_button]
	for idx in buttons.size():
		var button := buttons[idx]
		button.visible = idx < options.size()
		if not button.visible:
			continue
		var option: Dictionary = options[idx]
		var requirement := _unmet_requirement(option)
		button.text = option.get("label", "Option")
		button.tooltip_text = requirement if not requirement.is_empty() else "Choose this outcome. You can choose only once."
		if not _choice_made and not requirement.is_empty():
			button.text += " — " + requirement
		button.disabled = _choice_made or not requirement.is_empty()


func _unmet_requirement(option: Dictionary) -> String:
	var gold_cost: int = option.get("gold_cost", 0)
	var resource_cost: int = option.get("resource_cost", 0)
	if gold_cost > 0 and run_stats.gold < gold_cost:
		return "Requires %d gold" % gold_cost
	if resource_cost > 0 and run_stats.resources < resource_cost:
		return "Requires %d resource" % resource_cost
	return ""


func _on_option_a_pressed() -> void:
	_run_option_by_index(0)


func _on_option_b_pressed() -> void:
	_run_option_by_index(1)


func _run_option_by_index(idx: int) -> void:
	if _choice_made or not is_inside_tree():
		return
	var options: Array = _current_event.get("options", [])
	if idx < 0 or idx >= options.size():
		return
	var option: Dictionary = options[idx]
	if not _unmet_requirement(option).is_empty():
		_refresh_options()
		return
	var action_name: String = option.get("action", "")
	if action_name.is_empty() or not has_method(action_name):
		return
	# Commit once before currency signals or reward callbacks can reenter.
	_choice_made = true
	run_stats.gold -= int(option.get("gold_cost", 0))
	run_stats.resources -= int(option.get("resource_cost", 0))
	call(action_name)
	# A lethal HP cost synchronously replaces this room with the defeat panel.
	if not is_inside_tree():
		return
	_refresh_options()
	%OutcomeLabel.text = "Choice complete"
	%Hint.text = "Return to the route when you are ready."
	leave_button.text = "Continue the journey"
	leave_button.disabled = false
	leave_button.grab_focus()


func _leave_event() -> void:
	if not is_inside_tree():
		return
	Events.event_exited.emit()


func _option_rift_risk() -> void:
	_apply_damage(4)
	_gain_resources(1)
	body_label.text = "The aether scorches your hand, but a shard stays behind. (+1 resource, -4 HP)"


func _option_rift_harvest() -> void:
	_gain_gold(20)
	body_label.text = "You sweep the fragments into a pouch. (+20 gold)"


func _option_caravan_heal() -> void:
	body_label.text = "The salve burns before it soothes. (-10 gold, +6 HP)"
	_heal(6)


func _option_caravan_intel() -> void:
	_boost_card_weights()
	body_label.text = "You buy their intel. (-1 resource, better uncommon and rare card odds)"


func _option_scout_claim() -> void:
	_gain_gold(25)
	_gain_resources(1)
	body_label.text = "The satchel holds scribbled bounty slips. (+25 gold, +1 resource)"


func _option_scout_rest() -> void:
	_heal(8)
	body_label.text = "You honor the scout and press on. (+8 HP)"


func _apply_damage(amount: int) -> void:
	if player_stats:
		# Event HP costs bypass block left over from combat.
		player_stats.take_direct_damage(amount)


func _heal(amount: int) -> void:
	if player_stats:
		player_stats.heal(amount)


func _gain_gold(amount: int) -> void:
	if run_stats:
		run_stats.gold += amount


func _gain_resources(amount: int) -> void:
	if run_stats:
		run_stats.resources += amount


func _boost_card_weights() -> void:
	if not run_stats:
		return
	run_stats.common_weight = max(0.0, run_stats.common_weight - 0.5)
	run_stats.uncommon_weight += 0.25
	run_stats.rare_weight += 0.05
