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
	for contract: BountyContract in contracts:
		var reward := "%d gold" % contract.gold
		if contract.resources > 0:
			reward += "   ·   %d resources" % contract.resources
		var badge := "  [color=#d9b76f]HIGH VALUE[/color]" if contract.is_high_value else ""
		lines.append("[b]%s[/b]%s\n[color=#86bdb7]%s[/color]" % [contract.enemy_name, badge, reward])
	_title.text = "ACTIVE CONTRACTS   /   Refresh in %d floor(s)" % floors_until_refresh
	_body.text = "\n\n".join(lines)
	show()
