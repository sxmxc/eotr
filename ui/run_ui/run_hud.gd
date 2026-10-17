extends CanvasLayer

@onready var health_ui: HealthUI = %HealthUI
@onready var gold_ui: GoldUI = %GoldUI
@onready var resources_ui: ResourceUI = %ResourcesUI
@onready var deck_button: CardPileButton = %DeckButton
@onready var deck_view: CardPileView = %DeckView
@onready var relic_handler: RelicHandler = %RelicHandler
@onready var relic_tooltip: RelicTooltip = %RelicTooltip
@onready var run_time_ui: RunTimerUI = %RunTimeUI
@onready var bounty_board_popup: BountyBoardView = %BountyBoardPopup


func bind_run(player_stats: PlayerStats, run_stats: RunStats) -> void:
	player_stats.stats_changed.connect(health_ui.update_stats.bind(player_stats))
	health_ui.update_stats(player_stats)
	gold_ui.run_stats = run_stats
	resources_ui.run_stats = run_stats
	Events.relic_tooltip_requested.connect(relic_tooltip.show_tooltip)
	deck_button.card_pile = player_stats.deck
	deck_view.card_pile = player_stats.deck
	deck_button.pressed.connect(deck_view.show_current_view.bind("Deck"))
	bounty_board_popup.hide()


func show_bounties(contracts: Array[BountyContract], floor_count: int, next_refresh: int) -> void:
	update_bounties(contracts, floor_count, next_refresh)
	bounty_board_popup.show()


func update_bounties(contracts: Array[BountyContract], floor_count: int, next_refresh: int) -> void:
	bounty_board_popup.apply_bounties(contracts, floor_count, next_refresh)
