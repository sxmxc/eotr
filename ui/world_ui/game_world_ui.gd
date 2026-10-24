extends CanvasLayer
class_name GameWorldUI

var player_stats: PlayerStats: set = _set_player_stats


@onready var hand : PlayerHand = $PlayerUI/Hand as PlayerHand
@onready var stats_ui : StatsUI = $PlayerUI/Stats as StatsUI
@onready var tile_info : TileInfoUI = $PlayerUI/TileInfo as TileInfoUI
@onready var end_turn_button = %EndTurnButton
@onready var draw_pile_button: CardPileButton = %DrawPileButton
@onready var discard_pile_button: CardPileButton = %DiscardPileButton
@onready var exhaust_pile_button: CardPileButton = %ExhaustPileButton
@onready var draw_pile_view: CardPileView = %DrawPileView
@onready var discard_pile_view: CardPileView = %DiscardPileView
@onready var exhaust_pile_view: CardPileView = %ExhaustPileView
@onready var status_handler: StatusHandler = stats_ui.status_handler
@onready var enemy_rail = $EnemyRail
@onready var enemy_stats_container: GridContainer = $EnemyRail.queue
@onready var enemy_stats_scroll: ScrollContainer = $EnemyRail.scroll
@onready var enemy_inspection_container: Container = $EnemyRail.inspection
@export var tutorial_ui: TutorialUI
@onready var card_spotlight: HBoxContainer = %CardSpotlight
@onready var card_drop_area: Area2D = $CardDropArea
@onready var debug_ui = $DebugUI

var board: ProcGenTilemap

# Actual HUD edges in the reference viewport, including the card fan and controls.
func combat_rect() -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	var left := maxf($ActionHint.get_rect().end.x, tile_info.get_rect().end.x) + 24.0
	var right: float = enemy_rail.get_rect().position.x - 24.0
	var top: float = enemy_rail.get_rect().position.y
	if $BossHealth.visible:
		top = maxf(top, $BossHealth.get_rect().end.y + 12.0)
	var bottom := minf(hand.get_rect().position.y, stats_ui.get_rect().position.y) - 20.0
	return Rect2(Vector2(left, top), Vector2(maxf(right - left, 1.0), maxf(minf(bottom, viewport_size.y) - top, 1.0)))


func bind_world(player: Player, tilemap: ProcGenTilemap, camera: Camera2D) -> void:
	hand.player = player
	board = tilemap
	debug_ui.base_layer = tilemap.base_layer
	debug_ui.map_camera = camera

func _ready() -> void:
	$CameraHint.toggled.connect($CameraHelp.set_visible)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	Events.card_aim_started.connect(_show_aim_hint)
	Events.card_drag_started.connect(_show_aim_hint)
	Events.card_aim_ended.connect(_restore_hint)
	Events.card_drag_ended.connect(_restore_hint)
	Events.rounds_until_shrink_updated.connect(_collapse_hint)
	Events.player_moved.connect(_refresh_collapse_hint)
	if GameSettings.show_tutorial:
		Events.player_hand_drawn.connect(show_tutorial)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	draw_pile_button.pressed.connect(draw_pile_view.show_current_view.bind("Draw Pile", true))
	discard_pile_button.pressed.connect(discard_pile_view.show_current_view.bind("Discard Pile"))
	exhaust_pile_button.pressed.connect(exhaust_pile_view.show_current_view.bind("Exhaust Pile"))
	for child in enemy_stats_container.get_children():
		child.queue_free()
	
func initialize_card_pile_ui() -> void:
	draw_pile_button.card_pile = player_stats.draw_pile
	draw_pile_view.card_pile = player_stats.draw_pile
	discard_pile_button.card_pile = player_stats.discard
	discard_pile_view.card_pile = player_stats.discard
	exhaust_pile_button.card_pile = player_stats.exhaust_pile
	exhaust_pile_view.card_pile = player_stats.exhaust_pile
	
func show_tutorial() -> void:
	tutorial_ui.display_tutorial()
	await tutorial_ui.completed
	GameSettings.show_tutorial = false
	var data : SettingsData = GameSettings.get_current_settings()
	data.tutorial_enabled = false
	GameSettings.save_settings(data)
	Events.player_hand_drawn.disconnect(show_tutorial)
	

func _set_player_stats(value: PlayerStats) -> void:
	player_stats = value
	if not is_node_ready():
		await ready
	stats_ui.player_stats = player_stats
	hand.player_stats = player_stats
	hand.card_spotlight = card_spotlight

func _on_player_hand_drawn() -> void:
	_turn_active = true
	end_turn_button.disabled = false
	end_turn_button.text = "End Turn"
	_restore_hint()

func _on_end_turn_button_pressed() -> void:
	_turn_active = false
	SoundManager.play_ui_sound_random_pitch(AudioLibrary.ui_click)
	end_turn_button.disabled = true
	end_turn_button.text = "Enemy turn..."
	$ActionHint.text = "ENEMY TURN\nResolving their plans"
	Events.player_turn_ended.emit()


var _collapse_rounds := 99
var _turn_active := false

func _show_aim_hint(card_ui: CardUI) -> void:
	end_turn_button.disabled = true
	$ActionHint.text = "%s\nChoose a highlighted target\nRight click · Cancel" % card_ui.card.name

func _restore_hint(_card: CardUI = null) -> void:
	end_turn_button.disabled = not _turn_active
	$ActionHint.text = "YOUR TURN\nChoose a card"
	_refresh_collapse_hint()

func _collapse_hint(rounds: int) -> void:
	_collapse_rounds = rounds
	_refresh_collapse_hint()

func _refresh_collapse_hint() -> void:
	if _collapse_rounds <= 1 and board and not board.tile_map_data.is_empty():
		if board.get_battlemap_edge_clockwise().has(board.player_position):
			$ActionHint.text = "COLLAPSE IMMINENT - You are on the edge. Move inward to survive."
			$ActionHint.theme_type_variation = &"ActionHintDanger"
			return
	if $ActionHint.text.begins_with("COLLAPSE IMMINENT"):
		$ActionHint.text = "YOUR TURN\nChoose a card"
	$ActionHint.theme_type_variation = &"ActionHint"
