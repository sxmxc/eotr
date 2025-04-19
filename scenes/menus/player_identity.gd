extends Label

func _ready() -> void:
	Talo.players.identified.connect(_on_identified)

func _on_identified(player: TaloPlayer) -> void:
	text = player.id
