extends Button

var enemy: Enemy
var bound_stats: EnemyStats

func _ready() -> void:
	pressed.connect(_select)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	focus_entered.connect(_hover.bind(true))
	focus_exited.connect(_hover.bind(false))
	Events.enemy_updated.connect(_enemy_updated)
	Events.player_moved.connect(refresh)
	Events.player_hand_drawn.connect(refresh)

func bind_enemy(value: Enemy) -> void:
	_unbind()
	enemy = value
	enemy.queue_button = self
	bound_stats = enemy.stats
	if bound_stats:
		bound_stats.stats_changed.connect(refresh)
	enemy.tree_exiting.connect(_enemy_exiting)
	if is_instance_valid(enemy.tilemap):
		enemy.tilemap.presentation_changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	_unbind()

func _unbind() -> void:
	if bound_stats and bound_stats.stats_changed.is_connected(refresh):
		bound_stats.stats_changed.disconnect(refresh)
	if is_instance_valid(enemy) and enemy.tree_exiting.is_connected(_enemy_exiting):
		enemy.tree_exiting.disconnect(_enemy_exiting)
	if is_instance_valid(enemy) and is_instance_valid(enemy.tilemap) and enemy.tilemap.presentation_changed.is_connected(refresh):
		enemy.tilemap.presentation_changed.disconnect(refresh)
	if is_instance_valid(enemy) and enemy.queue_button == self:
		enemy.queue_button = null
	bound_stats = null
	enemy = null

func _enemy_exiting() -> void:
	hide()
	queue_free()

func _select() -> void:
	if is_instance_valid(enemy) and visible:
		Events.enemy_selected.emit(enemy)

func _enemy_updated(value: Enemy) -> void:
	if value == enemy:
		if value.stats != bound_stats:
			bind_enemy(value)
		else:
			refresh()

func refresh() -> void:
	if not is_instance_valid(enemy) or not bound_stats:
		return
	visible = not enemy.is_dying and (not is_instance_valid(enemy.tilemap) or not enemy.tilemap.is_tile_behind_fog(enemy.current_tile_position))
	if not visible:
		return
	var title := bound_stats.enemy_name if bound_stats.enemy_name else str(enemy.name)
	var prefix := "◇ " if enemy is Obelisk else ""
	var block := " +%d block" % bound_stats.block if bound_stats.block > 0 else ""
	var intent := "Considering…"
	icon = null
	if enemy.current_action and enemy.current_action.intent:
		var plan := enemy.current_action.intent
		icon = plan.get_display_icon()
		intent = plan.get_description()
		if intent.begins_with(title + " "):
			intent = intent.trim_prefix(title + " ")
	text = "%s%s  ·  %d/%d%s\n%s" % [prefix, title, bound_stats.health, bound_stats.max_health, block, intent.replace(" For ", " ")]
	tooltip_text = intent + "\nCurrent plan; may change with position and conditions.\nSelect to inspect statuses and details."
	theme_type_variation = &"ObjectiveQueueEntry" if enemy is Obelisk else &"EnemyQueueEntry"


func _hover(entered: bool) -> void:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree():
		return
	if entered and visible:
		enemy._on_queue_button_entered()
	elif not entered:
		enemy._on_queue_button_exited()
