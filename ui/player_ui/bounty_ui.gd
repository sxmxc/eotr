extends Panel

@onready var gold_label: Label = %BountyGoldLabel
@onready var res_label: Label = %BountyResLabel

func _ready() -> void:
	Events.enemy_gold_bounty_collected.connect(func(arg): gold_label.text = str(arg))
	Events.enemy_resource_bounty_collected.connect(func(arg): res_label.text = str(arg))
