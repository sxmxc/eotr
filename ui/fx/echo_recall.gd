extends "res://ui/fx/spell_signature.gd"

func execute() -> void:
	super.execute()
	if DisplayServer.get_name() == "headless":
		return
	var handler := get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if not handler or not handler.player_stats or not handler.player_stats.discard:
		return
	var cards := handler.player_stats.discard.cards
	if cards.size() < 2:
		return
	var previous: Card = cards[cards.size() - 2]
	if previous.card_art:
		$RecalledCard.texture = previous.card_art
		var tween := create_tween().set_parallel(true)
		tween.tween_property($RecalledCard, "position:y", -32.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property($RecalledCard, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
