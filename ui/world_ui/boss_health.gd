extends PanelContainer

var combatants: Array[Enemy] = []
var total_max := 0
var encounter: EncounterDefinition

func bind_world(world: GameWorld) -> void:
	encounter = world.battle_stats
	visible = encounter.category == EncounterDefinition.Category.BOSS
	if not visible:
		return
	%Name.text = encounter.encounter_name
	%Context.text = ActDefinition.campaign()[world.run_stats.act_index].title.to_upper() + " / ACT BOSS"
	for enemy: Enemy in world.enemy_handler.get_children():
		_bind_enemy(enemy, false)
	Events.enemy_spawned.connect(_bind_enemy)
	Events.enemy_updated.connect(_refresh_from_enemy)
	Events.enemy_died.connect(_refresh_from_enemy)
	Events.battle_over_screen_requested.connect(func(_text: String, _type: BattleOverPanel.Type): hide())
	_refresh()

func _bind_enemy(enemy: Enemy, _summoned: bool) -> void:
	if combatants.has(enemy):
		return
	combatants.append(enemy)
	total_max += enemy.stats.max_health
	enemy.set_meta("encounter_health", true)
	enemy.stats.stats_changed.connect(_refresh)
	enemy.tree_exiting.connect(_refresh)
	if enemy.queue_button:
		enemy.queue_button.refresh()
	if enemy.stats_ui:
		enemy.stats_ui.update_stats(enemy.stats)
	_refresh()

func _refresh_from_enemy(_enemy: Enemy) -> void:
	_refresh()

func _refresh() -> void:
	if not is_node_ready(): return
	var hp := 0
	var alive := 0
	var caption := ""
	for enemy in combatants:
		if not is_instance_valid(enemy): continue
		if not enemy.is_dying and enemy.stats.health > 0:
			hp += enemy.stats.health
			alive += 1
		if enemy is RiftBoss and not enemy.is_dying:
			caption = enemy.get_boss_summary()
	%Health.max_value = maxi(total_max, 1)
	%Health.value = hp
	%Amount.text = "%d / %d hostile HP - %d remaining" % [hp, total_max, alive]
	%Mechanic.text = caption
