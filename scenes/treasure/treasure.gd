class_name Treasure
extends Control

@export var treasure_relic_pool: Array[Relic]
@export var relic_handler: RelicHandler
@export var player_stats: PlayerStats

@onready var animation_player: AnimationPlayer = %AnimationPlayer
var found_relic: Relic


func generate_relic() -> void:
	var available_relics := treasure_relic_pool.filter(
		func(relic: Relic):
			var can_appear := relic.can_appear_as_reward(player_stats)
			var already_had_it := relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)
	found_relic = RNG.array_pick_random(available_relics)


func _on_treasure_opened() -> void:
	var event_props := {
		"treasure_spawned" : found_relic.relic_name
	}
	Talo.events.track("treasure_room_exited", event_props)
	Events.treasure_room_exited.emit(found_relic)


func _on_treasure_chest_gui_input(event: InputEvent) -> void:
	if animation_player.current_animation == "open":
		return

	if event.is_action_pressed("left_mouse"):
		animation_player.play("open")
