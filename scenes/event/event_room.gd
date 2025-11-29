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
		"body": "Nomads wave you over to trade. Their wares are worn, but their salves still sting with life.",
		"options": [
			{"label": "Trade 10 gold for a salve (+6 HP)", "action": "_option_caravan_heal"},
			{"label": "Trade 1 resource for intel (+card reward odds)", "action": "_option_caravan_intel"}
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


func setup_event(player: PlayerStats, run: RunStats, relics: RelicHandler) -> void:
	player_stats = player
	run_stats = run
	relic_handler = relics
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
	title_label.text = _current_event.get("title", "Unknown Event")
	body_label.text = _current_event.get("body", "")
	var options: Array = _current_event.get("options", [])
	if options.size() >= 2:
		option_a_button.text = options[0].get("label", "Option A")
		option_b_button.text = options[1].get("label", "Option B")
	option_a_button.disabled = false
	option_b_button.disabled = false
	leave_button.disabled = false


func _on_option_a_pressed() -> void:
	_run_option_by_index(0)


func _on_option_b_pressed() -> void:
	_run_option_by_index(1)


func _run_option_by_index(idx: int) -> void:
	var options: Array = _current_event.get("options", [])
	if idx >= options.size():
		_leave_event()
		return
	var action_name: String = options[idx].get("action", "")
	if action_name != "" and has_method(action_name):
		call(action_name)
	_disable_inputs()
	leave_button.text = "Leave"
	leave_button.disabled = false


func _disable_inputs() -> void:
	option_a_button.disabled = true
	option_b_button.disabled = true


func _leave_event() -> void:
	Events.event_exited.emit()


func _option_rift_risk() -> void:
	_apply_damage(4)
	_gain_resources(1)
	body_label.text = "The aether scorches your hand, but a shard stays behind. (+1 resource, -4 HP)"


func _option_rift_harvest() -> void:
	_gain_gold(20)
	body_label.text = "You sweep the fragments into a pouch. (+20 gold)"


func _option_caravan_heal() -> void:
	if run_stats.gold >= 10:
		run_stats.gold -= 10
		body_label.text = "The salve burns before it soothes. (-10 gold, +6 HP)"
	else:
		body_label.text = "You lack the gold to trade."
		return
	_heal(6)


func _option_caravan_intel() -> void:
	if run_stats.resources > 0:
		run_stats.resources -= 1
		_boost_card_weights()
		body_label.text = "Their intel sharpens your draft instincts. (-1 resource, improved card reward odds)"
	else:
		body_label.text = "No spare resources to barter."


func _option_scout_claim() -> void:
	_gain_gold(25)
	_gain_resources(1)
	body_label.text = "The satchel holds scribbled bounty slips. (+25 gold, +1 resource)"


func _option_scout_rest() -> void:
	_heal(8)
	body_label.text = "You honor the scout and press on. (+8 HP)"


func _apply_damage(amount: int) -> void:
	if player_stats:
		player_stats.take_damage(amount)


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
