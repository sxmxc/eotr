extends Control
class_name BountyBoardView

@onready var back_button: Button = %BackButton
@onready var bounty_board: MapBountyBoard = %BountyBoard
var _last_contracts: Array[BountyContract] = []
var _last_floor: int = 0
var _last_next_refresh: int = 0

func _ready() -> void:
	back_button.pressed.connect(
		func():
			SoundManager.play_sound_random_pitch(AudioLibrary.ui_click)
			hide()
	)
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()


func apply_bounties(contracts: Array[BountyContract], floors_climbed: int, next_refresh_floor: int) -> void:
	_last_contracts = contracts
	_last_floor = floors_climbed
	_last_next_refresh = next_refresh_floor
	if is_instance_valid(bounty_board):
		bounty_board.update_bounties(contracts, floors_climbed, next_refresh_floor)
