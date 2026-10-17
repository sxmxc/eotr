extends Label

func _ready() -> void:
	Talo.players.identified.connect(_on_identified)
	Talo.players.identity_cleared.connect(_on_identity_cleared)
	if Talo.current_alias:
		_on_identified(Talo.current_alias)

func _on_identified(player_alias: TaloPlayerAlias) -> void:
	text = player_alias.player.id

func _on_identity_cleared() -> void:
	text = ""
