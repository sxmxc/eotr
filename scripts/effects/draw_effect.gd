extends Effect
class_name DrawEffect

var amount : int = 0

func execute(targets: Array[Node]) -> void:
	if !targets[0] is Player:
		return
	var player_handler : PlayerHandler = targets[0].get_tree().get_first_node_in_group("player_handler")
	player_handler.draw_cards(amount)
