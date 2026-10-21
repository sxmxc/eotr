class_name ActTransition
extends Control

var run: Run
var choosing := false

func _ready() -> void:
	%Continue.pressed.connect(func(): run.advance_act())
	%Refine.pressed.connect(_refine)
	Events.card_cost_selection_completed.connect(_selected)
	Events.card_cost_selection_cancelled.connect(func(request: CardCostSelectionRequest):
		if request.source == self: choosing = false)

func bind_run(value: Run) -> void:
	run = value
	$Backdrop.texture = run.acts[run.run_stats.act_index + 1].background
	%Title.text = "%s\nRIFT SEALED" % run.active_act.title.to_upper()
	%Next.text = "Beyond the fracture: %s" % run.acts[run.run_stats.act_index + 1].title
	%Story.text = run.acts[run.run_stats.act_index + 1].description
	%Reward.text = "Claim %s and 35 gold. Choose recovery or refinement." % run.active_act.boss_relic.relic_name
	%Refine.disabled = run.player_stats.deck.cards.size() <= 8
	%Continue.grab_focus()

func _refine() -> void:
	if choosing:
		return
	choosing = true
	var request := CardCostSelectionRequest.new()
	request.source = self
	request.title = "Leave one memory behind"
	request.body = "Remove one card permanently and recover 20% maximum HP."
	request.cards = run.player_stats.deck.cards.duplicate()
	Events.card_cost_selection_requested.emit(request)

func _selected(cards: Array[Card], request: CardCostSelectionRequest) -> void:
	if request.source == self and not cards.is_empty():
		run.advance_act(cards[0])
