extends Control

@onready var next_button: Button = %NextButton
@onready var prev_button: Button = %PrevButton
@onready var continue_button: Button = %ContinueButton
@onready var tab_container: TabContainer = $TabContainer

func _ready():
	continue_button.hide()
	prev_button.disabled = true
	_update_buttons()

func _on_next_button_pressed() -> void:
	if tab_container.current_tab < tab_container.get_tab_count() - 1:
		tab_container.current_tab += 1
	_update_buttons()

func _on_prev_button_pressed() -> void:
	if tab_container.current_tab > 0:
		tab_container.current_tab -= 1
	_update_buttons()

func _update_buttons() -> void:
	var current = tab_container.current_tab
	var max_tabs = tab_container.get_tab_count() - 1

	prev_button.disabled = current == 0
	next_button.visible = current < max_tabs
	continue_button.visible = current == max_tabs
