extends Control
class_name MapBountyBoard

# @onready var _panel: Panel = %Panel
@onready var _title: Label = %Title
@onready var _body: RichTextLabel = %Body


func _ready() -> void:
	hide()


func update_bounties(
	contracts: Array[BountyContract],
	floors_climbed: int,
	next_refresh_floor: int
) -> void:
	var floors_until_refresh: int = max(0, next_refresh_floor - floors_climbed)
	if contracts.is_empty():
		_title.text = "No Active Bounties"
		_body.text = "Refreshes in %d floor(s)." % floors_until_refresh
		show()
		return

	var lines: Array[String] = []
	var slot: int = 1
	for contract: BountyContract in contracts:
		var reward_parts: Array[String] = []
		reward_parts.append("+%d gold" % contract.gold)
		if contract.resources > 0:
			reward_parts.append("+%d resources" % contract.resources)
		var details: String = ", ".join(reward_parts)
		if contract.is_high_value:
			details += " [b](High Value)[/b]"
		lines.append("[b]%d.[/b] %s — %s" % [slot, contract.enemy_name, details])
		slot += 1

	_title.text = "Active Bounties — refresh in %d floor(s)" % floors_until_refresh
	_body.text = "\n".join(lines)
	show()
