class_name BattleStateController
extends Node

enum Phase {
	IDLE,
	PLAYER_TURN,
	PLAYER_CLEANUP,
	ENEMY_TURN,
	SHRINKING,
	TRANSITION,
}

@export var game_world: GameWorld
@export var player_handler: PlayerHandler
@export var enemy_handler: EnemyHandler
@export var shrink_frequency: int = 3

signal phase_changed(new_phase: Phase)

var phase: Phase = Phase.IDLE
var battle_active := false


func _ready() -> void:
	_connect_events()


func start_battle() -> void:
	if not _has_required_nodes():
		return
	battle_active = true
	_set_phase(Phase.PLAYER_TURN)
	game_world.current_round = 1
	game_world.rounds_until_shrink = max(shrink_frequency - 1, 0)
	enemy_handler.reset_enemy_actions()


func end_battle() -> void:
	battle_active = false
	_set_phase(Phase.IDLE)


func _connect_events() -> void:
	if not Events.player_turn_ended.is_connected(_on_player_turn_ended):
		Events.player_turn_ended.connect(_on_player_turn_ended)
	if not Events.player_hand_discarded.is_connected(_on_player_hand_discarded):
		Events.player_hand_discarded.connect(_on_player_hand_discarded)
	if not Events.enemy_turn_ended.is_connected(_on_enemy_turn_ended):
		Events.enemy_turn_ended.connect(_on_enemy_turn_ended)


func _set_phase(new_phase: Phase) -> void:
	if phase == new_phase:
		return
	phase = new_phase
	phase_changed.emit(phase)


func _validate_transition(expected_phase: Phase, context: String) -> bool:
	if not battle_active:
		return false
	if phase != expected_phase:
		push_warning("Ignoring %s during %s phase" % [context, Phase.keys()[phase]])
		return false
	return _has_required_nodes()


func _has_required_nodes() -> bool:
	return is_instance_valid(game_world) and is_instance_valid(player_handler) and is_instance_valid(enemy_handler)


func _on_player_turn_ended() -> void:
	if player_handler.resolving_action or not player_handler.hand_ready:
		return
	if not _validate_transition(Phase.PLAYER_TURN, "player turn end"):
		return
	_set_phase(Phase.PLAYER_CLEANUP)
	player_handler.end_turn()


func _on_player_hand_discarded() -> void:
	if not _validate_transition(Phase.PLAYER_CLEANUP, "player hand discard"):
		return
	_set_phase(Phase.ENEMY_TURN)
	enemy_handler.start_turn()


func _on_enemy_turn_ended() -> void:
	if not _validate_transition(Phase.ENEMY_TURN, "enemy turn end"):
		return
	await _advance_round()


func _advance_round() -> void:
	_set_phase(Phase.TRANSITION)
	game_world.check_victory()
	if not battle_active:
		return
	var should_shrink := shrink_frequency > 0 and game_world.current_round % shrink_frequency == 0
	if should_shrink:
		_set_phase(Phase.SHRINKING)
		await game_world.shrink_game_board(1)
		_set_phase(Phase.TRANSITION)
		game_world.check_victory()

	if not battle_active:
		return

	game_world.current_round += 1
	if shrink_frequency > 0:
		game_world.rounds_until_shrink -= 1
	else:
		game_world.rounds_until_shrink = 0

	_set_phase(Phase.PLAYER_TURN)
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()
