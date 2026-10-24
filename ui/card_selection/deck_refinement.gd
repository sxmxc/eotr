extends Button

signal refined
var player_stats: PlayerStats
var run_stats: RunStats
var price := 0
var used := false
var pending := false
var inactive := false

func deactivate() -> void:
	inactive = true
	var was_pending := pending
	pending = false
	_refresh()
	if was_pending:
		($SelectionLayer/Selection as CardCostSelection)._on_cancel_pressed()

func _ready() -> void:
	pressed.connect(_choose)
	Events.card_cost_selection_completed.connect(_confirm)
	Events.card_cost_selection_cancelled.connect(func(request: CardCostSelectionRequest):
		if request.source == self: pending = false)

func configure(stats: PlayerStats, currency: RunStats = null, gold_cost: int = 0) -> void:
	player_stats = stats
	run_stats = currency
	price = gold_cost
	if run_stats and not run_stats.gold_changed.is_connected(_refresh):
		run_stats.gold_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	text = "Refine deck - remove one card" + (" (%d gold)" % price if price else " instead of resting")
	disabled = inactive or used or player_stats == null or player_stats.deck.cards.size() <= 8 or (price > 0 and (run_stats == null or run_stats.gold < price))

func _choose() -> void:
	if not is_inside_tree() or inactive or pending or disabled: return
	pending = true
	var request := CardCostSelectionRequest.new()
	request.source = self
	request.title = "Refine your memories"
	request.body = "Permanently remove one card. Your deck must retain at least eight cards."
	request.cards = player_stats.deck.cards.duplicate()
	Events.card_cost_selection_requested.emit(request)

func _confirm(cards: Array[Card], request: CardCostSelectionRequest) -> void:
	if not is_inside_tree() or inactive or request.source != self or not pending: return
	pending = false
	if cards.size() != 1 or used or player_stats.deck.cards.size() <= 8 or not player_stats.deck.cards.has(cards[0]): return
	if price > 0 and (run_stats == null or run_stats.gold < price): return
	used = true
	if run_stats: run_stats.gold -= price
	player_stats.deck.remove_card(cards[0])
	TelemetryManager.track_event("card_removed", {"card": cards[0].id, "source": "shop" if price else "rest", "gold_cost": price})
	_refresh()
	refined.emit()
