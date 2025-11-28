# Echoes of the Rift — Agent Journal

Record notable work here. Use reverse chronological order (newest at top).

---

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
