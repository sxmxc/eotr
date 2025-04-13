extends Node

@warning_ignore_start("unused_signal")
# Card-related events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(card_ui: CardUI)
signal card_aim_ended(card_ui: CardUI)
signal card_played(card: Card)
signal card_tooltip_requested(data: TooltipData)
signal tooltip_hide_requested

# Player-related events
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_hit
signal player_died

# Enemy-related events
signal enemy_died(enemy: Enemy)
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_selected(enemy: Enemy)
signal enemy_updated(enemy: Enemy)
signal enemy_info_hide_requested

# Battle-related events
signal status_tooltip_requested(statuses: Array[Status])
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal obilisk_destroyed
signal battle_won

# Map-related events
signal map_exited(map_node: MapNode)
signal tile_selected(tile_data: HexTileData)
signal tile_updated(tile_data: HexTileData)
signal world_message_requested(message: WorldMessageData)
signal world_message_hide_requested

# Shop-related events
signal shop_entered(shop: Shop)
signal shop_relic_bought(relic: Relic, gold_cost: int)
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_exited

# rest zone events
signal rest_exited

# Battle Reward-related events
signal battle_reward_exited

# Treasure Room & Relic-related events
signal treasure_room_exited(relic: Relic)
signal relic_tooltip_requested(relic: Relic)
