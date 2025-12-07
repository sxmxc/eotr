extends Relic

# Stores leftover energy at end of turn and restores it at the start of the next one.
var stored_energy := 0
var _connected := false
var relic_ui: RelicUI


func initialize_relic(_owner: RelicUI) -> void:
	relic_ui = _owner
	_connect_signals()


func deactivate_relic(_owner: RelicUI) -> void:
	_disconnect_signals()
	stored_energy = 0
	relic_ui = null


func activate_relic(owner: RelicUI) -> void:
	if stored_energy <= 0:
		return
	var player := owner.get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	player.stats.energy += stored_energy
	stored_energy = 0
	owner.flash()


func _connect_signals() -> void:
	if _connected:
		return
	Events.player_turn_ended.connect(_on_player_turn_ended)
	_connected = true


func _disconnect_signals() -> void:
	if not _connected:
		return
	if Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.disconnect(_on_player_turn_ended)
	_connected = false


func _on_player_turn_ended() -> void:
	if not relic_ui:
		return
	var player_handler := relic_ui.get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if not player_handler:
		return
	var player_stats := player_handler.player_stats
	if not player_stats:
		return
	stored_energy = max(player_stats.energy, 0)
