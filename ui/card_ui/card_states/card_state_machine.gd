class_name CardStateMachine
extends Node

@export var initial_state: CardState

var current_state: CardState
var states := {}
var card_ui: CardUI


func init(card: CardUI) -> void:
	card_ui = card
	for child in get_children():
		if child is CardState:
			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			child.card_ui = card
	if initial_state:
		initial_state.enter()
		current_state = initial_state


func on_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_input(event)


func on_gui_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_gui_input(event)


func on_mouse_entered() -> void:
	if current_state:
		current_state.on_mouse_entered()


func on_mouse_exited() -> void:
	if current_state:
		current_state.on_mouse_exited()


func _on_transition_requested(from: CardState, to: CardState.State) -> void:
	if from != current_state:
		return
	if is_instance_valid(card_ui.interaction_controller):
		card_ui.interaction_controller.transition(card_ui, from, to)
	else:
		change_state(to)


func change_state(to: CardState.State) -> void:
	var new_state: CardState = states[to]
	if not new_state:
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	new_state.enter()
	new_state.post_enter()
