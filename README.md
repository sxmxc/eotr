# Echoes of the Rift

[![Release build](https://github.com/sxmxc/eotr/actions/workflows/build_release.yml/badge.svg)](https://github.com/sxmxc/eotr/actions/workflows/build_release.yml)

Echoes of the Rift is a hybrid hex-grid tactics x deckbuilder. Each battle blends positional play (fog of war, shrinking arenas, an Obelisk objective) with card-driven actions, relics, and resource-gathering tiles.

## What’s In This Build

- Hex map with fog, resource, corrupted, mana well, rift gate, and ruin tiles.
- Active Obelisk attacks/summons, enemy-elimination victory and periodic board shrink.
- Deck/energy system with rarities, exhaust, and status-driven modifiers.
- Enemy AI defined by weighted/conditional actions and per-unit stats.
- Dev sandbox for fast iteration (spawn enemies, add cards, regenerate maps).

## Quickstart

1. Install Godot 4.7.2 (use the renderer configured in project.godot).
2. Open the project and run the default main scene (`scenes/splash_screens/splash_screen.tscn`) for the full flow, or run `scenes/sandbox/gameworld_sandbox.tscn` for instant combat iteration.
3. Controls: drag/aim cards to targets, right-click to cancel aim, End Turn ends the player phase.

## Playtesting the Deckbuilder

- Use the Sandbox (`scenes/sandbox/gameworld_sandbox.tscn`):
  - Dev Panel lets you regenerate the map, spawn enemies, toggle fog, refill energy/health, and pass turns.
  - Card dropdowns add cards to hand/draw/discard; “Draw Card” triggers a draw.
- LimboConsole commands (press the console hotkey):
  - `draw_card` (from `PlayerHandler`) draws the top card.
  - `hide_fog` / `show_fog`, `show_resources` / `hide_resources` (from `ProcGenTilemap`) adjust visibility.
- To sanity-check drafts: add cards to the draw pile, pass turn, and observe energy/block/HP deltas in the Dev Panel.

## Adding New Cards

1. Create a script that extends `Card` (see `resources/data/cards/riftwalker/arcane_bolt.gd`) and implement `apply_effects` plus optional `get_modified_description` / `is_valid_target`.
2. Make a `.tres` resource for the card (art, cost, rarity, target_type, sfx/vfx, projectile) pointing to your script.
3. Register it in `resources/data/registries/card_registry_riftwalker.tres` (or add via the Sandbox Dev Panel pulling from `RegistryData`).
4. Test quickly in `gameworld_sandbox.tscn` by adding the card to hand/draw and spawning a target.

## Adding New Enemies & Encounters

- Enemy:
  1. Create an `EnemyStats` resource (see `scenes/enemy/bat/bat_enemy.tres`) with icon, sounds, HP, AI scene, and rewards.
  2. If it moves, point to `moving_enemy.tscn`; if static, use/duplicate `enemy.tscn` variants.
  3. Add to `resources/data/catalogs/enemy_catalog.tres` with tags for filtering.
- Encounter:
  1. Build a PackedScene that instances your enemies (`resources/data/battles/*.tscn` are examples).
  2. Wrap it in a `BattleStats` resource (size, rewards, elite/boss flags) and add to `resources/data/registries/encounter_registry_act1.tres`.

## Architecture Notes

- Core logic lives in `scenes/game_world/game_world.gd` (battle loop), `scenes/player/player_handler.gd` (hand/turn), `scripts/nodes/proc-gen-tilemap.gd` (map/fog/shrink), and `scripts/nodes/enemy_handler.gd` (enemy loop).
- Reusable effects: `scripts/effects/node` (damage, block, energy), `scripts/effects/tile` (move, gather).
- Status system: `scripts/resources/status.gd` + `ui/status_ui/status_handler.gd` manage stacks/durations; modifiers live under `scenes/modifier_handler`.

## Developer Utilities

AutoWalker plays the real combat/run scenes visibly or headlessly, with random,
greedy and stress policies, pause/step controls, replay checkpoints and local reports.
See [AutoWalker commands and validation](ai/docs/autowalker-architecture.md).
AutoWalker keeps local QA files and uploads bot telemetry when the configured HTTP
transport is enabled. Use `--telemetry-local` to run without backend access.

The reusable [Godot telemetry addon](addons/godot_telemetry/README.md) supports portable
schemas, HTTP/JSONL/Null delivery and consent-aware bounded buffering. Game configuration
and migration notes are in [telemetry architecture](ai/docs/telemetry-architecture.md).
The [analytics backend source package](backend/telemetry/README.md) includes ingestion,
ClickHouse migrations, Grafana dashboards and deployment artifacts for later hosting.
No analytics backend services were started during implementation.

The backend is a Git submodule with its own repository and self-contained Docker
build. Use `git submodule update --init backend/telemetry` to populate it in a game
checkout, or clone `git@github.com:sxmxc/eotr-telemetry-backend.git` directly on the
Docker host. Backend changes can be committed and pushed independently; update the
game's submodule pointer only when recording a newer backend revision.

The [implementation checklist](ai/docs/implementation-checklist.md) records all five
deliverables, acceptance evidence and remaining validation limits.

- Sandbox Dev Panel: spawn enemies, add cards, refill stats, center/zoom camera, clear fog.
- RegistryData autoload scans registries/resources for cards and encounters.
- Audio/FX libraries are prewired; `SoundManager` and PhantomCamera handle feedback.

## Compatibility Validation

After importing the project in Godot 4.7.2, run:

```powershell
python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe
```

Use your own executable path. The runner uses a separate project configuration and save directory under `build/`, with Null telemetry delivery and no backend access. It checks first-party resource loading, telemetry consent and event recording, sandbox setup and cleanup, new-run saves, and combat startup. See [the upgrade notes](ai/docs/godot-4.7.2-upgrade.md) for remaining validation limits.

## 📂 Repository Structure

```
/
├── addons/               # Custom Godot editor plugins
├── assets/               # Art, audio, fonts, animations
├── resources/            # Data assets (cards, encounters, registries, statuses)
├── scenes/               # Scene files for battles, map, UI, enemies, sandbox
├── scripts/              # Core GDScript code
├── script_templates/     # GDScript templates
├── ui/                   # User interface and HUD
└── README.md
```

## Credits

Created by Voidmoose  
Inspired by *Slay the Spire*, *Into the Breach*, *Griftlands*, and *Settlers of Catan*
