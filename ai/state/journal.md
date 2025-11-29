# Echoes of the Rift — Agent Journal

Record notable work here. Use reverse chronological order (newest at top).

---

**2025-11-29 – Codex**
- Summary: Fixed channeler/bulwark scene UID mismatches and cleared GDScript errors (indent + type mismatch) that blocked channeler battles from loading.
- Files: `scenes/enemy/bulwark/bulwark_cleave_action.gd`, `scenes/enemy/channeler/channeler_empower_action.gd`, `scenes/enemy/bulwark/bulwark_enemy_ai.tscn`, `scenes/enemy/channeler/channeler_enemy_ai.tscn`
- Verification: Not run (Godot executable unavailable in this environment).
- Follow-ups: Re-enter battles featuring Channelers/Bulwarks to confirm no remaining script load errors and that actions play correctly.

**2025-11-29 – Codex**
- Summary: Added Bulwark (frontline brace/cleave) and Void Channeler (ally buffer + weaken beam) enemies with new AI/action scripts, and introduced tier 1/2 battle pools that seed obelisks with the new spawn mix.
- Files: `scenes/enemy/channeler/*`, `scenes/enemy/bulwark/*`, `resources/data/battles/tier_1_channelers_bulwark.*`, `resources/data/battles/tier_2_bulwark_channelers.*`, `resources/data/battles/battle_stats_pool.tres`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot client/headless checks unavailable in this environment).
- Follow-ups: Playtest the new battles to tune weights, rewards, and damage/block numbers; sanity-check obelisk spawns still respect caps with the expanded pool.

**2025-11-29 – Codex**
- Summary: Started BKL-035 intent overhaul: normalized intent formatting for Channeler/Bulwark/Blob/Horror (including elite) actions and tooltips; improved intent UI tooltip handling to avoid placeholder errors; marked task in progress.
- Files: `ui/enemy_ui/intent_ui.gd`, `scenes/enemy/channeler/*`, `scenes/enemy/bulwark/*`, `scenes/enemy/blob/*`, `scenes/enemy/horror/*`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot unavailable here).
- Follow-ups: Finish audit and apply schema to remaining enemy AIs (void spectre, bats/wasps/obelisk variants), then review visual refresh (color tiers/badges) once formatting is stable.

**2025-11-28 – Codex**
- Summary: Added a reusable card cost selection popup (selectable card grid with hover details and optional tooltips), new event signals, and GameWorld wiring so rituals/events can request card sacrifices.
- Files: `ui/card_selection/card_cost_selection.tscn`, `ui/card_selection/card_cost_selection.gd`, `ui/card_menu_ui/card_menu_ui.gd`, `scripts/autoloads/events.gd`, `scripts/resources/card/card_cost_selection_request.gd`, `scenes/game_world/game_world.tscn`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (manual code review only; Godot scene/headless checks not executed).
- Follow-ups: Route rituals/events that consume cards through `Events.card_cost_selection_requested`, and add SFX/animation polish after UX is validated.

**2025-11-28 – Codex**
- Summary: Marked the tutorial refresh (run + battle overlays) as complete after copy review; no code or layout changes.
- Files: `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (status update only).
- Follow-ups: Play through the intro/battle tutorial once to confirm sizing/fit on-device.

**2025-11-28 – Codex**
- Summary: Clarified battle tutorial text so the movement refund and obelisk hit energy bonus are labeled as Riftwalker-only perks.
- Files: `scenes/game_world/game_world.tscn`
- Verification: Not run (text-only tweak).
- Follow-ups: If other classes later gain similar perks, revisit the tutorial copy to reflect their rules.

**2025-11-28 – Codex**
- Summary: Refreshed run and battle tutorials to teach the obelisk objective, tile effects (mana wells, rift gates, ruins), movement refund/obelisk energy bonuses, and updated currencies; marked the boss health meter task as blocked pending the boss redesign.
- Files: `scenes/run/run.tscn`, `scenes/game_world/game_world.tscn`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (UI copy changes only; Godot scenes not launched here).
- Follow-ups: Play through the run intro and first battle to confirm the new tutorial copy fits on screen and reads clearly; revisit the boss health meter once the redesign spec lands.

**2025-11-27 – Codex**
- Summary: Retuned the enemy roster for v0.0.6.0 by lowering early-unit damage/HP (bat/wasp/blob/horror), trimming obelisk pressure (range hit to 6, spawn cap 3, slower spawn cadence), and softening elite/void durability and payouts (capped void spectre heal/block, reduced gold rewards, lighter elite stats).
- Files: `scenes/enemy/bat/bat_enemy_attack_action.gd`, `scenes/enemy/wasp/wasp_enemy_attack_action.gd`, `scenes/enemy/blob/*`, `scenes/enemy/horror/*`, `scenes/enemy/obelisk/*`, `scenes/enemy/void_spectre/*`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot gameplay/headless checks not executed in this session).
- Follow-ups: Playtest tier 0–2 fights to ensure spawn pacing and rewards still feel fair; watch void spectre defend timing with the new heal cap; re-evaluate gold/resource yields if runs become too generous after these nerfs.

**2025-11-27 – Codex**
- Summary: Added battle start tile preferences and reservation handling so special tiles (mana wells, ruins, rift gates) can be enforced without enemy overlap; deferred initial placement effects now fire right after START_OF_COMBAT so spawn tiles trigger once cleanly before turn 1.
- Files: `scripts/resources/battle_stats.gd`, `scripts/nodes/proc-gen-tilemap.gd`, `scripts/nodes/enemy_handler.gd`, `scenes/game_world/game_world.gd`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot scenes/tests not executed in this session).
- Follow-ups: Mark specific battles that should force special start tiles and sanity-check in-game that effects trigger once at battle start.

**2025-11-27 – Codex**
- Summary: Boosted enemy death feedback with flash/smoke VFX, camera shake, optional death sound fallback, a shared fade-out helper, and guards against double-triggered deaths (including obelisk/boss overrides).
- Files: `scenes/enemy/enemy.gd`, `scenes/enemy/obelisk/obelisk_enemy.gd`, `scenes/enemy/void_spectre/void_spectre_enemy.gd`, `scripts/resources/stats/enemy_stats.gd`, `scripts/statics/audio_library.gd`
- Verification: Not run (Godot scene/gameplay checks not executed in this session).
- Follow-ups: Wire specific death sounds per enemy where fitting; sanity-check that the 0.25–0.5s fade keeps tiles usable and camera shake feels right across enemy sizes.

**2025-11-27 – Codex**
- Summary: Added an impact profile kit (hit-stop, tint, scalable shakes, and rune decals) used by damage handling for players and enemies, with a lightweight impact decal FX and shared hit-stop helper.
- Files: `scripts/ref_counted/effects/impact_profile.gd`, `ui/fx/impact_decal_fx.gd`, `ui/fx/impact_decal_fx.tscn`, `scripts/effects/node/damage_effect.gd`, `scenes/player/player.gd`, `scenes/enemy/enemy.gd`, `scripts/autoloads/utils.gd`
- Verification: Not run (Godot headless/scene checks not executed in this session).
- Follow-ups: In-game, confirm heavy hits briefly slow time and tint sprites without stalling turn flow; verify decals render at impact points and time-scale restores if multiple hits land quickly.

**2025-11-27 – Codex**
- Summary: Guarded battle-over handling so we only emit the screen once, paused battle music, and forced win/lose stingers to start at full volume even when the tree is paused.
- Files: `scenes/game_world/game_world.gd`, `ui/world_ui/battle_over_panel.gd`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot headless/audio checks not executed here).
- Follow-ups: Verify in-game that the victory/defeat audio plays immediately on the battle over screen and stops cleanly when moving to rewards/map; keep an ear out for any remaining overlap with battle playlists.
