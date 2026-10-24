extends RiftBoss

const REAP_SOUND = preload("res://assets/audio/Monster Sounds/Ghost/Ghost_Death.ogg")
var chorus := 0
var listening := true
var reaping := false
var reap_progress := 0.0

func _process(delta: float) -> void:
	super._process(delta)
	if reaping:
		reap_progress = minf(reap_progress + delta / maxf(Utils.presentation_duration(0.22), 0.01), 1.0)

func _ready() -> void:
	super._ready()
	Events.card_played.connect(_hear_card)

func prepare_signature() -> void:
	listening = turn_ticker % 2 == 0
	_refresh_caption()

func _hear_card(card: Card) -> void:
	if encounter_finished or is_dying or stats.health <= 0:
		return
	chorus = clampi(chorus + (1 if card.card_type == Enums.CardType.ATTACK else -1), 0, 3)
	_refresh_caption()
	update_intent()

func _refresh_caption() -> void:
	boss_caption = "%s. Chorus %d/3. Attack cards add one voice; other cards remove one. Reap %d x 3. Living Anchor adds Residue at 2+ voices and heals 4 while listening." % ["LISTENING" if listening else "REAP", chorus, chorus + 1]

func describe_boss_intent(plan: Intent) -> void:
	plan.current_text = "Listen" if listening else "%d x 3" % (chorus + 1)
	plan.detail_text = boss_caption

func get_boss_summary() -> String:
	return "%s / CHORUS %d OF 3 / REAP %d x 3 %s" % ["LISTENING" if listening else "REAP", chorus, chorus + 1, "next turn" if listening else "this turn"]

func perform_boss_turn(action: EnemyAction, generation: int) -> void:
	if await retreat_from_collapse(action, generation):
		return
	if not action_is_live(action, generation):
		return
	if listening:
		var obelisk := get_tree().get_first_node_in_group("obelisk") as Obelisk
		if is_instance_valid(obelisk) and not obelisk.is_dying:
			obelisk.stats.heal(4)
		var next := calculate_next_tile_move(1)
		if next != INVALID_TILE and set_movement_target(next):
			await movement_finished
		return
	var hits := chorus + 1
	var anchor := get_tree().get_first_node_in_group("obelisk") as Obelisk
	if chorus >= 2 and is_instance_valid(anchor) and not anchor.is_dying:
		tilemap.player.stats.draw_pile.add_card(preload("res://resources/data/cards/common/void_residue.tres").duplicate())
	for hit in hits:
		feedback = 1.0
		present_attack("windup")
		reaping = true
		reap_progress = 0.0
		await get_tree().create_timer(Utils.presentation_duration(0.22)).timeout
		if not action_is_live(action, generation):
			return
		reaping = false
		present_attack("release")
		strike_player(3, REAP_SOUND)
		if not await wait_for_player_effects(action, generation):
			return
	chorus = 0
	_refresh_caption()
	update_intent()

func _draw() -> void:
	super._draw()
	if is_dying or encounter_finished or not is_instance_valid(sprite_2d) or not sprite_2d.texture:
		return
	var texture := sprite_2d.texture
	if reaping and is_instance_valid(tilemap.player):
		var destination := to_local(tilemap.player.global_position) + Vector2(0, -20)
		var point := Vector2(0, -35).lerp(destination, reap_progress * reap_progress)
		draw_texture_rect(texture, Rect2(point + Vector2(-24, -34), Vector2(48, 60)), false, Color(0.82, 0.65, 1.0, 0.7))
	for voice in chorus:
		var offset := Vector2((voice - 1) * 28, -34 - (voice % 2) * 14)
		offset *= 1.0 - feedback * 0.7
		draw_texture_rect(texture, Rect2(offset + Vector2(-21, -38), Vector2(42, 52)), false, Color(0.7, 0.5, 1.0, 0.38))
