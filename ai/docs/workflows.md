# Echoes of the Rift — Task Workflows

Use these playbooks to accelerate common contributions. Always capture outcomes in `ai/state/journal.md` and `ai/state/progress.json`.

## 1. Add or Update a Card
1. **Review Existing Card**: Locate script under `resources/data/cards/<class>/<card_id>.gd`.
2. **Check Pile Registration**: Ensure new cards are referenced in `draftable_cards` or `starting_deck` resources if needed.
3. **Implement Changes**:
   - Derive from `Card`, override `apply_effects()` and any description helpers.
   - Use `ModifierHandler` hooks (`DMG_DEALT`, `DMG_TAKEN`, etc.) for scaling.
4. **Wire Assets**: Update `.tres` resource for the card (art, rarity, cost). Confirm `project.godot` import metadata if new textures.
5. **Test**:
   - Console: `add_card` (if available) or adjust deck to include card.
   - Battle: confirm targeting, cost, and effects align with description.
6. **Document**: Log test steps and any follow-on tasks (balancing, VFX).

## 2. Create / Modify an Enemy Encounter
1. **Enemy Scene**: Scenes live in `scenes/enemy/<enemy_name>/`. Behaviour extends `Enemy` or `MovingEnemy`.
2. **Actions & Intents**: Update `EnemyAction` resources or `update_intent()` overrides. Ensure telegraphed intent matches actual effect.
3. **Stats**: Adjust `resources/stats/enemy_stats_*.tres` or script exported values.
4. **Spawner**: Hook enemy group into relevant `BattleStats` resource (under `resources/data/battles/...`).
5. **Testing**:
   - Start a run, use `yeet_em_all` or `add_resources` as needed.
   - Verify `EnemyHandler` turn order and status application.
6. **Record**: Document balance considerations and map tiers affected.

## 3. Tweak Map Generation or Progression
1. **Entry Point**: `scenes/map/map_generator.gd`.
2. **Parameters**: Evaluate constants (`FLOORS`, `MAP_WIDTH`, weights) and exported fields (`BattleStatsPool`).
3. **Connections**: Ensure `_setup_connection()` still prevents path overlaps. Update tests for treasure/rest floors if logic changes.
4. **Validate**:
   - Run the map scene in isolation.
   - Scroll with `scroll_up/down` actions to inspect layout.
   - Confirm `Map.unlock_floor()` gating works for changed rows.
5. **Log**: Capture RNG seeds used for reproduction.

## 4. Update Battle Systems (Player/Enemy Handlers, Tilemap)
1. **Handlers**: `scenes/player/player_handler.gd`, `scripts/nodes/enemy_handler.gd`.
2. **Tilemap**: `scripts/nodes/proc-gen-tilemap.gd` for map generation, fog, and interactions.
3. **Events**: Emit new signals via `scripts/autoloads/events.gd` and wire listeners in `_ready()`.
4. **Testing**:
   - Run `GameWorld` scene independently.
   - Exercise turn cycle: draw, play card, discard, trigger enemy turn.
   - Verify obelisk lifecycle and board shrink behaviour.
5. **Notes**: Mention any new console commands and ensure they’re registered once.

## 5. UI / UX Adjustments
1. **Location**: UI scenes under `ui/` or nested in gameplay scenes (search `%` references).
2. **Themes**: Maintain pixel aesthetic, reuse `SoundManager` FX for interactions.
3. **Accessibility**: Preserve keyboard/gamepad navigation (check focus, `grab_focus()` usage).
4. **QA**: Validate on 1920×1080 and windowed overrides (see `project.godot` display settings).
5. **Record**: Include before/after behaviour and any follow-up assets required.

## Verification Checklist
- `context7` consulted?
- Relevant scenes/scripts updated?
- Tests or manual QA run?
- `journal.md` entry added?
- `progress.json` updated?

Use this file as a living document—add workflows when new feature areas emerge (e.g., relic crafting, telemetry). Coordinate with maintainers before overhauling existing processes.
