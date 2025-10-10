# Echoes of the Rift — Agent Onboarding

Welcome! This guide equips agents contributing to **Echoes of the Rift** with the context, tools, and expectations needed to deliver high‑quality GDScript updates for the Godot 4.5 codebase.

## 1. Get Your Bearings
- **Genre & Loop**: Tactical deckbuilding roguelite. Players traverse a 15-floor rift map, engage in grid combat, manage resources, and collect relics.
- **Core Scenes**:
  - `scenes/run/run.tscn` – overworld loop that swaps views (map, battle, shop, etc.).
  - `scenes/game_world/game_world.tscn` – battle scene with `ProcGenTilemap`, `PlayerHandler`, `EnemyHandler`.
  - `scenes/map/map.tscn` – node-based floor selection using `MapGenerator`.
- **Important Resources**:
  - `scripts/resources/card/` – card definitions (`Card` subclasses) with effects.
  - `scripts/resources/stats/` – `PlayerStats`, `EnemyStats`, and shared `Stats` logic.
  - `scripts/autoloads/` – singletons (`Events`, `RNG`, `GameSettings`, `Utils`, etc.).

## 2. Always Sync Context
- **Non-negotiable**: Before editing or reviewing GDScript, always use `context7` mcp to ensure the latest language and API nuances. GDScript evolves quickly; this keeps completions aligned with the current standard library and Godot 4.5 syntax.
- If the harness output flags updates (e.g., keyword changes, API deprecations) incorporate them immediately or call them out in the plan.

## 3. Coding Expectations
- **Godot 4.5**: Prefer typed GDScript (`var foo: int`) and modern signal syntax. Keep compatibility with engine features defined in `project.godot` (e.g., `Feature Tag: 4.5`).
- **Signals & Events**:
  - Prefer `Events` autoload for cross-system communication.
  - Use `await`/`create_tween()` patterns already present rather than introducing new libs.
- **Scene Architecture**: Maintain separation between logic (`scripts/...`) and packed scenes (`scenes/...`). Avoid embedding logic in `.tscn` files unless hooking up exported properties.
- **Style**:
  - Follow existing formatting (tabs for indentation, trailing commas optional).
  - Use concise comments only when intention isn’t obvious.
  - Keep resources deterministic (avoid randomness at load time).

## 4. Working Process
1. **Plan**: Outline intent in the task plan tool (unless change is trivial).
2. **Inspect**: Gather references via `grep`, `find`, `sed`, or Godot scene paths.
3. **Edit**: Use `apply_patch` for manual edits. Respect existing user changes; never revert unrelated diffs.
4. **Verify**:
   - Static checks: `godot --headless --editor` (if needed) or targeted script `--check-only`.
   - Runtime sanity: launch relevant scene if possible (`godot --headless -s scripts/…`).
   - Manual QA: note which scene/card/system to test in the journal.
5. **Document**: Record progress in `ai/state/journal.md` and update `ai/state/progress.json`.

## 5. Testing & Debug Aids
- **Console Commands**: LimboConsole exposes helpers (`yeet_em_all`, `add_gold`, `hide_fog`, etc.). Register new commands sparingly.
- **Autoload Utilities**:
  - `Utils.shake()` for feedback.
  - `SoundManager.play_music_queue(...)` and `play_sound_random_pitch(...)`.
- **Expected Tests**:
  - **Cards**: ensure energy balance, targets (`Card.get_valid_targets()`), and descriptions match modified values.
  - **Map**: re-run `MapGenerator.generate_map()` and visually confirm placement (use `limbo_console_toggle`).
  - **Battle**: verify `PlayerHandler.start_turn()` / `EnemyHandler.start_turn()` loops and relic interactions.

## 6. Communication Checklist
- Update `ai/state/journal.md` after meaningful work with date, change summary, verification steps, and follow-ups.
- Sync `ai/state/progress.json` statuses (`todo`, `in_progress`, `blocked`, `done`).
- Surface open questions to the maintainer promptly (blocking assumptions, missing assets, Godot version mismatches).

## 7. Tooling Integrations
- **Godot MCP Server**: Accessible via the MCP client (`mcp godot ...`). Use it to query scenes, run headless checks, or fetch live node/property data without leaving the harness. Prefer MCP-assisted inspections over ad-hoc script edits when feasible, and log noteworthy calls in the journal if they influence decisions.

## 8. Safe-Guarding the Project
- Use the workspace sandbox responsibly; never request escalated permissions unless required.
- Do not run destructive git commands. Respect user’s dirty working tree.
- When introducing new files/resources, ensure import paths reference existing directories (`assets/`, `resources/`, etc.).
- Treat everything under `/addons` as third-party dependencies; avoid modifying files in that directory.

With this foundation, agents can confidently assist on Echoes of the Rift. Review `ai/docs/workflows.md` for task-specific playbooks before diving in.
