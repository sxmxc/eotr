class_name Treasure
extends Control

@export var treasure_relic_pool: Array[Relic]
@export var relic_handler: RelicHandler
@export var player_stats: PlayerStats

@onready var open_button: Button = %OpenButton
@onready var emblem: TextureRect = %Emblem
var opening := false
var reward_emitted := false
var found_relic: Relic


func generate_relic() -> void:
	var available_relics := treasure_relic_pool.filter(
		func(relic: Relic):
			var can_appear := relic.can_appear_as_reward(player_stats)
			var already_had_it := relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)
	found_relic = RNG.array_pick_random(available_relics) if not available_relics.is_empty() else null
	if not found_relic:
		open_button.text = "Continue"
		%RoomLayout.find_child("Story", true, false).text = "The cache is empty. You have already claimed its relics."


func _on_treasure_opened() -> void:
	if reward_emitted:
		return
	reward_emitted = true
	var event_props := {
		"treasure_spawned" : found_relic.relic_name if found_relic else "none"
	}
	TelemetryManager.track_event("treasure_room_exited", event_props)
	Events.treasure_room_exited.emit(found_relic)


func _open_treasure() -> void:
	if opening:
		return
	opening = true
	open_button.disabled = true
	open_button.text = "Opening..."
	var tween := create_tween()
	tween.tween_property(emblem, "modulate", Color(0.48, 0.92, 0.85), Utils.presentation_duration(0.25))
	tween.tween_interval(Utils.presentation_duration(0.25))
	tween.tween_callback(_on_treasure_opened)


func _on_treasure_chest_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		_open_treasure()
