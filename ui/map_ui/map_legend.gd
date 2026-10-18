extends CanvasLayer

signal bounty_board_requested


func _ready() -> void:
	%BountyBoardButton.pressed.connect(func(): bounty_board_requested.emit())
