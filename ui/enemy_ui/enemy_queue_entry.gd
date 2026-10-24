extends Button

var enemy: Enemy
var bound_stats: EnemyStats

func _ready() -> void:
	$Content.minimum_size_changed.connect(_fit_content)
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
	if is_instance_valid(enemy) and visible and _is_revealed():
		Events.enemy_selected.emit(enemy)

func _enemy_updated(value: Enemy) -> void:
	if value == enemy:
		if value.stats != bound_stats:
			bind_enemy(value)
		else:
			refresh()

func _is_revealed() -> bool:
	return is_instance_valid(enemy) and (not is_instance_valid(enemy.tilemap) or not enemy.tilemap.is_tile_behind_fog(enemy.current_tile_position))

func refresh() -> void:
	if not is_instance_valid(enemy) or not bound_stats:
		return
	visible = not enemy.is_dying and bound_stats.health > 0
	if not visible:
		return
	var revealed := _is_revealed()
	disabled = not revealed
	%HealthRow.visible = revealed and not enemy.has_meta("encounter_health")
	%Block.visible = revealed and bound_stats.block > 0
	%IntentIcon.visible = revealed
	%EnemyName.text = "Unknown enemy"
	%EnemyName.theme_type_variation = &"QueueName"
	%Plan.text = "Hidden by fog"
	tooltip_text = "An enemy is present beyond your vision. Reveal it to see its health and plan."
	theme_type_variation = &"EnemyQueueEntry"
	# Clear cached information as well as concealing it when fog returns.
	%HealthBar.value = 0
	%HealthValue.text = ""
	%Block.text = ""
	%IntentIcon.texture = null
	if not revealed:
		return
	var title := bound_stats.enemy_name if bound_stats.enemy_name else str(enemy.name)
	%EnemyName.text = ("◇ " if enemy is Obelisk else "") + title
	%EnemyName.theme_type_variation = &"QueueObjectiveName" if enemy is Obelisk else &"QueueName"
	%HealthBar.max_value = maxi(bound_stats.max_health, 1)
	%HealthBar.value = bound_stats.health
	%HealthValue.text = "%d/%d" % [bound_stats.health, bound_stats.max_health]
	%Block.text = "%d block" % bound_stats.block
	var description := "Considering…"
	var summary := description
	if enemy.current_action and enemy.current_action.intent:
		var plan := enemy.current_action.intent
		%IntentIcon.texture = plan.get_display_icon()
		description = plan.get_description()
		summary = enemy.current_action.get_queue_summary()
	%Plan.text = summary
	tooltip_text = title + "\n" + description + "\nCurrent plan; may change with position and conditions.\nSelect to inspect statuses and details."
	theme_type_variation = &"ObjectiveQueueEntry" if enemy is Obelisk else &"EnemyQueueEntry"
	_fit_content.call_deferred()


func _fit_content() -> void:
	var content := $Content as VBoxContainer
	custom_minimum_size.y = content.get_combined_minimum_size().y + content.offset_top - content.offset_bottom


func _hover(entered: bool) -> void:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree():
		return
	if entered and visible and _is_revealed():
		enemy._on_queue_button_entered()
	elif not entered:
		enemy._on_queue_button_exited()
