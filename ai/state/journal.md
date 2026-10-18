# Echoes of the Rift — Agent Journal

Record notable work here. Use reverse chronological order (newest at top).

**2026-10-17 – Codex: trustworthy QA metrics, bounded storage and Grafana access**
- Assigned unique simulation IDs before scene startup and preserved them through
  run_started. Fresh JSONL per session and reset health counters prevent accumulated
  launches/counter skew; comparison filters stale reports by summary session and
  requires matching metric versions. Actual sample: 105 events after rerunning a
  two-seed output as one seed; one current-session report selected, stale seed ignored.
- Versioned encounter/simulation metrics as v2: actual health damage after block and
  overkill, effective healing and net health loss are distinct; total player turns
  span battles with final battle/floor counters separate. Updated both bundled
  schemas, ingestion regression and dashboard queries, preserving the user's exported
  AutoWalker dashboard layout. Deployment must update ingestion schemas first.
- Bounded local artifacts: 8 MiB JSONL, 16 MiB compact replay trace, 32 reports/64 MiB
  per output, global generated QA artifact retention of 14 days/256 MiB with five-second
  launcher maintenance and active-file/replay protection. A log above 8 MiB triggers
  bounded shutdown before trimming, retaining any script-error marker. Root confinement, no junction traversal, and
  save/cache/unrelated-file exclusions are tested. Permanent evidence belongs outside qa/.
- Backend delivery remains the default and all normal guide examples now use it;
  offline is explicit. Updated stale architecture/backend statements and documented
  official Grafana MCP with Viewer token environment configuration. Plugin discovery
  found no Grafana connector; no credentials/configuration installed or live access claimed.
- Verification: five launcher tests, four retention/comparison/log tests, eight mocked
  ingestion tests, Godot health/identity/session/retention/turn tests with zero failed
  assertions; 292 actual encounter/run events pass the canonical backend validator.
  New run reports 10 total turns vs final battle turn 4. Full compatibility loads 531
  resources with zero failed assertions but exits 1 on known shader/certificate and
  four-resource shutdown diagnostics. No backend services started or contacted.
- Live reduced-threshold log-budget check shuts Godot down normally, returns 2 and
  writes launcher_storage_limit without leaving an orphan stop request. Log trimming
  happens after writer shutdown so its seek offset cannot produce growing gaps.

**2026-10-17 – Codex: graceful AutoWalker interruption and QA directory**
- Confirmed the reported session ended with terminal Ctrl+C after a recorded win.
  Isolated Godot from terminal interrupts, added a per-launch stop request handled
  at an action boundary, retained bounded telemetry shutdown and completed reports,
  and returned 130 without a traceback. Polling avoids Python 3.10.2's Windows
  timed-wait retry turning a late KeyboardInterrupt into a long native wait.
- Moved existing QA result folders, logs, AutoWalker scratch project and isolated
  saves from build/ to qa/. Updated AutoWalker, compatibility and standalone telemetry
  tools, scene defaults, test output paths, README and all affected documentation.
  Git ignores generated QA data; qa/.gdignore and release filters exclude it from
  imports/exports. Platform exports remain under build/. No directories merged or
  existing report contents rewritten. Generated a fresh comparison in qa/.
- Verification: five launcher lifecycle tests; simulated interruption during headless
  play and after a rendered victory, with code 130, no static-string/navigation errors
  and the completed report checksum unchanged; three-seed batch wins in 6/5/8 turns
  with zero failures; migrated default-path battle wins in six turns. Standalone
  telemetry exits 0 with zero failed assertions. Control assertions pass, but their
  runner exits 1 on existing shutdown resource-retention diagnostics. Existing
  certificate/headless shader and normal-renderer texture diagnostics remain.
- Full compatibility check from qa/ exits 0, loads 531 first-party resources and
  reports zero failed assertions, with existing shader/certificate/single-resource
  shutdown diagnostics. The moved three-seed comparison has no outcome changes.
- Context7 Godot 4.7 API guidance consulted. Resource guard, documentation path/link
  checks and diff whitespace checks pass. No backend services started or contacted.

**2026-10-17 – Codex: AutoWalker documentation walkthrough**
- Added `ai/docs/autowalker.md` with an offline first-battle walkthrough, Watch controls,
  headless batches, result interpretation, replay, progression, comparisons, option
  defaults and troubleshooting. Linked it from the root README and architecture notes.
- Kept implementation details and historical validation evidence in the architecture
  document. Clarified import prerequisites, report overwrite behavior, headless-only
  batching, Watch summary behavior and Start versus Restart/Play controls.
- Verification: checked instructions against the launcher, comparison tool, runner and
  Watch bindings; checked CLI help, Markdown local links and diff whitespace. Documentation
  only; no gameplay or backend services launched and no new runtime validation claimed.

**2026-10-17 – Codex: AutoWalker backend uploads alongside local QA**
- AutoWalker now honors the configured enabled HTTP endpoint with an independent
  addon client, QA profile/environment, bot source and shared local session/run
  context. The local JSONL/report/replay path remains available during backend
  failure or remote queue pressure. Remote consent and disabled settings are honored.
- The Python launcher preserves configured telemetry by default and offers
  --telemetry-local for offline runs. Validation retains its isolated Null config.
  Completed batches and Watch close use a bounded 15-second multi-batch drain;
  unresolved uploads are exposed through warning/health rather than claimed sent.
  Watch inspector and summary.json include delivered/pending/retry/error metrics.
- Regression uses a fake asynchronous upload transport without opening a service
  or contacting the user's endpoint. Telemetry-only runner exits 0 with zero failed
  assertions. Full controls assertions also pass; that run still reports existing
  shutdown-resource diagnostics and exits 1. Headless local-only seed 1 wins in six
  turns with zero failures/invalid actions and 105 local events delivered, none
  pending. Existing certificate/shader/resource diagnostics remain. No backend
  services started or live HTTP delivery claimed. User project/export/scene edits
  were preserved.

**2026-10-17 – Codex: cancel card draws when the player is removed**
- Draw callbacks were bound to PlayerHandler and could outlive its player node.
  Guarded draws against missing/dead/queued/detached players and hand controls,
  retained and cancelled the draw tween on player/handler exit and replacement,
  and prevented cancelled draw completion from advancing the player phase.
- Added a regression that advances a draw tween deterministically, queues player
  deletion mid-sequence, then attempts direct and zero-card draws after freeing.
  Timing-based setup initially raced headless presentation; custom stepping makes
  the fixture independent of frame duration. User project/export/Watch-scene
  edits were preserved. AutoWalker telemetry routing was not changed by this fix.
- Validation: isolated compatibility runner exited 0, loaded 531 resources and
  reported zero failed assertions, including deletion during draw. Existing
  certificate-store, headless shader and retained MapNode shutdown diagnostics
  remain; no backend services were launched.

**2026-10-17 – Codex: avoid Grafana HTTP server-hello timeout override**
- The user still observed code 452 at the HTTP server handshake after the prior
  timeout change. Driver source confirms context deadlines can overwrite custom
  max_execution_time values with remaining seconds plus five. The previous static
  checks did not account for this override and did not validate a live handshake.
- Switched Grafana to internal native protocol/9000 and provisioning version 2,
  retaining explicit 30-second timeouts, read-only grants and the 60-second ceiling.
  Ingestion remains on HTTP, with no database ports published. Updated artifact
  checks for native connection and five-second timeout headroom and documented
  inspection of effective provisioning on the Docker host.
- Backend artifact checks pass. No services launched; the deployed datasource
  still requires operator verification after pulling and restarting Grafana.

**2026-10-17 – Codex: tolerate non-JSON telemetry HTTP responses**
- Removed unconditional JSON.parse_string from HTTP classification. Failed requests
  and non-200 statuses now produce transport/status diagnostics without parsing
  the response body. HTTP 200 acknowledgements use JSON.parse with explicit error
  handling, preserving bounded retries for malformed or incomplete acknowledgements.
- Standalone addon regressions cover empty/text/HTML responses, null/array/wrong
  counts, 503 retries, permanent 404s and connection failures. Telemetry tests pass
  with no JSON parser errors; the existing Windows certificate-store diagnostic
  remains. Endpoint configuration was preserved; no backend service was launched.

**2026-10-17 – Codex: Grafana timeout constraint mismatch**
- The deployed datasource authenticated but its server handshake failed with
  ClickHouse code 452 because max_execution_time exceeded the reader's 60-second
  ceiling. Explicitly provisioned a 30-second query timeout and matching custom
  connection setting, so the initial handshake also uses a permitted value.
- Kept the server ceiling and read-only profile. Added artifact checks comparing
  datasource timeout values to the XML constraints and documented Grafana restart.
  Static backend checks pass; no services started or live validation performed.

**2026-10-17 – Codex: independent backend submodule build**
- Kept the `backend/telemetry` Git submodule and its remote unchanged. Switched
  Compose/Dockerfile to backend-local paths, bundled the current event contract,
  updated schema lookup for tests and source execution, and excluded secrets and
  unrelated files from the Docker context. Documented independent backend commits
  and explicit contract version coordination with the game.
- Restored account configuration and Grafana password fixes missing from the newly
  extracted backend repository. Artifact checks validate local Docker COPY inputs,
  Compose context and the account/grant/password wiring, with host port assertions
  matching the existing deployment configuration.
- Validation: seven mocked ingestion tests and artifact checks passed both in the
  submodule and in a temporary backend-only copy outside the game tree. Bundled
  schemas match the game's current contract; both repositories pass diff checks.
  Docker CLI is unavailable, so image build was not executed. No backend services
  or containers started. Backend changes remain uncommitted in the submodule.

**2026-10-17 – Codex: final Talo removal and Grafana account provisioning**
- Removed leftover Talo calls from telemetry consent, main menu and sandbox,
  deleted identity UI/script and offline settings, and cleaned export references.
  The addon/autoload/plugin were already absent. Tests and AutoWalker now start
  with isolated Null telemetry, preserving the user's HTTP production resource.
- Fixed backend account setup: Compose now loads persistent-volume-independent
  ClickHouse users with environment passwords, explicit INSERT/SELECT grants and
  read-only query limits. Allowed the Grafana client to set bounded query timeouts.
  Changed datasource password expansion to preserve `$` characters and documented
  the existing-host repair without deleting data volumes.
- Validation: 531 resources loaded and compatibility smoke assertions passed;
  standalone telemetry tests and seven mocked ingestion tests passed. A headless
  AutoWalker encounter won in six turns with zero failures, invalid actions,
  softlocks or timeouts. Backend
  account/grant/password/configuration static checks passed. Existing Windows
  certificate, headless shader and shutdown-resource diagnostics remain. No
  backend services or containers started; live authentication must be checked
  by the operator after updating the Docker host.

**2026-10-17 – Codex: telemetry minimum-batch byte boundary**
- Count JSON separators only between events so an accepted event exactly at
  max_event_bytes fits a batch clamped to max_event_bytes + 32, avoiding empty
  deliveries and a permanently blocked queue head.
- Added a standalone regression covering exact-size acceptance, one-byte-over rejection,
  nonempty one-event batches, acknowledgement progress, FIFO order and subsequent drain.
  Reproduced three failed assertions before the fix; the updated standalone test passes.

**2026-10-17 – Codex: combat, AutoWalker, reusable telemetry and analytics source package**
- Implemented all five deliverables tracked in `ai/docs/implementation-checklist.md`.
  Enemy elimination replaces automatic Obelisk victory; guarded enemy turns, bounded
  tactical movement, collapse escape, occupied movement and pure AI predicates retain
  the existing weighted/conditional architecture and enemy roster.
- AutoWalker uses real GameWorld/Run scenes and shared card validation, random/greedy/
  stress policies, Watch controls and inspector, headless batches, checkpoint replay,
  invariants and local reports. Fixed delayed hand removal/double discard, Sever Anchor
  skipping costs/events, logical fog delays and presentation consuming gameplay RNG.
- Added independent schema-aware Godot telemetry addon, JSONL/HTTP/Null transports,
  bounded buffering/retries, consent controls and portable game schemas. Migrated Talo
  event/stat delivery while preserving unrelated identity UI/APIs and opt-out cleanup.
- Authored Python ingestion, ClickHouse migrations, Grafana dashboards/provisioning,
  Compose/Docker source and operator guidance. No analytics services or containers
  were started or deployed; all backend tests use mocked storage or static inspection.
- Validation: standalone addon, combat and Watch-control assertions pass; compatibility
  smoke reports 530 resource loads and zero failed assertions. Greedy tier-0 seeds 1–3
  win in 6/5/8 turns; random/stress batches distinguish losses/limits from failures.
  Native Watch replay matches a 20-action winning encounter; run automation performs
  76 actions including route, rewards and a card draft before defeat. All 307 QA events
  from that run pass the backend schema validator. Seven ingestion tests and static
  artifact/resource/whitespace checks pass. Version bumped to 0.0.7.0.
- Limits: existing certificate/shader/resource-retention shutdown diagnostics persist;
  no complete campaign win, every optional room, large balance benchmark or release
  export verified. Gross damage accounting, optional disk HTTP retry spool and later
  live backend/TLS/dashboard integration limits are documented, not claimed verified.

---

**2025-12-15 – Codex**
- Summary: Centralized targeting into a single TargetSelector with cached valid cells and reusable validators; card drag/aim states now pull highlights from the cache and the movement selector inherits the shared logic (electric arc enabled). Updated planning to mark BKL-043 in review.
- Files: `scenes/game_world/card_target_selector/card_target_selector.gd`, `scenes/game_world/movement_target_selector/movement_target_selector.gd`, `ui/card_ui/card_states/card_aiming_state.gd`, `ui/card_ui/card_states/card_dragging_state.gd`, `ai/planning/todo.yaml`
- Verification: Not run (Godot/headless checks not executed here).
- Follow-ups: In-engine pass to ensure enemy/tile targeting respects fog/adjacency rules, arcs/indicators update smoothly, and cached targets refresh correctly after movement or enemy deaths.

**2025-12-15 – Codex**
- Summary: Migrated more Riftwalker cards to the CardResolver pipeline: Arcane Explosion and Void Shard now use data-driven damage configs; Overload Shot, Void Surge, and Deminishing Returns build resolver configs at play time for dynamic damage. Added a resolver-first note to the card workflow doc.
- Files: `resources/data/cards/riftwalker/arcane_explosion.gd`, `.tres`, `resources/data/cards/riftwalker/void_shard.gd`, `.tres`, `resources/data/cards/riftwalker/overload_shot.gd`, `resources/data/cards/riftwalker/void_surge.gd`, `resources/data/cards/riftwalker/deminishing_returns.gd`, `ai/docs/workflows.md`
- Verification: Manual sandbox check advised for new resolver cards; no automated tests run.
- Follow-ups: Migrate remaining cards once resolver supports energy/status/multi-hit, and consider adding resolver effect types for energy/status.

**2025-12-15 – Codex**
- Summary: Expanded CardResolver to support ENERGY, DRAW, STATUS, and MULTI_DAMAGE effects (with multi-hit + intervals) and migrated a wide set of Riftwalker cards to resolver configs: Adrenaline Rush, Arcane Flame, Chrono Jab, Corroding Shot, Corrosion Wave, Focus, Mana Leech, Mana Surge, Nano Shield, Fracture Pulse, Jab. Resolver now handles status/energy/draw/multi-hit in data-driven configs.
- Files: `scripts/resources/card/card_effect_config.gd`, `scripts/systems/card_resolver.gd`, `resources/data/cards/riftwalker/adrenaline_rush.gd`, `arcane_flame.gd`, `chrono_jab.gd`, `corroding_shot.gd`, `corrosion_wave.gd`, `focus.gd`, `mana_leech.gd`, `mana_surge.gd`, `nano_shield.gd`, `fracture_pulse.gd`, `jab.gd`
- Verification: Not run; sandbox smoke test recommended for migrated cards.
- Follow-ups: Consider migrating remaining complex/status-heavy cards once comfortable; extend resolver with any additional effect types if needed.

**2025-12-15 – Codex**
- Summary: Fixed movement card validation by ensuring tile targets enter the scene tree before checks and removing get_tree reliance in Phase Step/Quantum Rift; preserved aimed targets on release to keep damage cards (e.g., Arcane Bolt) from losing their selected enemy.
- Files: `scenes/game_world/card_target_selector/card_target_selector.gd`, `resources/data/cards/riftwalker/phase_step.gd`, `resources/data/cards/riftwalker/quantum_rift.gd`
- Verification: Not run (Godot/headless checks not executed here).
- Follow-ups: Re-test movement cards and Arcane Bolt in-engine to confirm targeting sticks, damage applies, and tile validation no longer errors when hovering.

**2025-12-15 – Codex**
- Summary: Added a CardResolver + CardEffectConfig pipeline for data-driven effects and migrated sample damage/block/move/gather cards (Arcane Bolt, Eldritch Barrier, Phase Step, Echo Harvest) to the resolver; base Card now uses resolver-driven effects when configs are present.
- Files: `scripts/systems/card_resolver.gd`, `scripts/resources/card/card_effect_config.gd`, `scripts/resources/card/card.gd`, `resources/data/cards/riftwalker/arcane_bolt.gd`, `resources/data/cards/riftwalker/eldritch_barrier.gd`, `resources/data/cards/riftwalker/phase_step.gd`, `resources/data/cards/riftwalker/echo_harvest.gd`
- Verification: Not run (Godot/headless client not available here).
- Follow-ups: Expand resolver coverage to the remaining card set/effect types and validate FX/camera context injection in-engine.

**2025-12-15 – Codex**
- Summary: Added a BattleStateController to own turn/shrink phases, rewired GameWorld to route player end -> enemy loop -> shrink via the controller, and hooked the scene to the new node; updated planning/progress for BKL-041.
- Files: `scenes/game_world/battle_state_controller.gd`, `scenes/game_world/game_world.gd`, `scenes/game_world/game_world.tscn`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot/headless checks unavailable here).
- Follow-ups: Play through a few battles to confirm end-turn -> discard -> enemy loop -> shrink sequencing stays in sync and that battle-over handling stops further phase transitions.

**2025-12-07 – Codex**
- Summary: Added a Corroded end-of-turn debuff (true damage + block shred) and two Riftwalker cards—Corroding Shot (single-target) and Corrosion Wave (AoE, exhaust)—then seeded them into the draftable pool to broaden combat builds.
- Files: `resources/data/statuses/corroded.gd`, `resources/data/statuses/corroded.tres`, `resources/data/cards/riftwalker/corroding_shot.gd`, `resources/data/cards/riftwalker/corroding_shot.tres`, `resources/data/cards/riftwalker/corrosion_wave.gd`, `resources/data/cards/riftwalker/corrosion_wave.tres`, `resources/data/card_piles/riftwalker_draftable_cards.tres`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot/headless client not available here).
- Follow-ups: Playtest the corroded package to tune damage/block shred and energy costs; confirm card reward tables surface the new cards at intended rarities.

**2025-11-30 – Codex**
- Summary: Added battle intro/outro presentation (vignette + audio swell) and tightened discard/draw pacing. New BattlePresentation overlay hooks into GameWorld start/end, and hand cleanup/draw intervals now finish faster with shorter reshuffle trails.
- Files: `ui/world_ui/battle_presentation.gd`, `scenes/game_world/game_world.gd`, `scenes/player/player_handler.gd`
- Verification: Not run (visual/audio timing needs in-engine check).
- Follow-ups: Playtest to confirm intro/outro beats don’t mask telegraphs or clip stingers; ensure faster discard/draw doesn’t desync SFX.

**2025-11-30 – Codex**
- Summary: Added map event nodes with a lightweight EventRoom (gold/resource/HP trades) and a map bounty board overlay that surfaces reachable battle rewards. Map generator now rolls Event nodes; map UI shows event icon plus bounty panel for available battles.
- Files: `scenes/event/event_room.tscn`, `scenes/event/event_room.gd`, `scripts/autoloads/enums.gd`, `scenes/map/map_generator.gd`, `scenes/map/map_node_ui.gd`, `scenes/map/map.gd`, `scenes/map/map_bounty_board.gd`, `scenes/run/run.gd`
- Verification: Not run.
- Follow-ups: Expand event variety/rewards, and confirm bounty board values match in-game reward rolls and future bounty systems.

**2025-11-29 – Codex**
- Summary: Added pooled pulsing card-target highlights using the highlighter shader (separate overlay to avoid clearing obelisk telegraphs), rewired card drag/aim states to the new layer, and triggered a light scan SFX on aim start.
- Files: `scripts/nodes/proc-gen-tilemap.gd`, `scenes/game_world/game_world.tscn`, `scenes/sandbox/gameworld_sandbox.tscn`, `ui/card_ui/card_states/card_dragging_state.gd`, `ui/card_ui/card_states/card_aiming_state.gd`, `scripts/statics/audio_library.gd`
- Verification: `D:\Godot-Editors\godot.cmd --headless --check-only` (timed out after initialization; no errors surfaced before timeout).
- Follow-ups: In-game check for highlight alignment/readability across card shapes, ensure aim whoosh volume blends with existing UI SFX, and watch for lingering highlight sprites after map rebuilds.

**2025-11-29 – Codex**
- Summary: Added context-aware enemy action weighting plus attack/block heuristics (distance, expected damage, player block/energy) for common melee enemies to react to turtling/kiting strategies. Updated planning/progress for BKL-038.
- Files: `scenes/enemy/enemy_action.gd`, `scenes/enemy/enemy_action_picker.gd`, `scenes/enemy/blob/blob_attack_action.gd`, `scenes/enemy/blob/blob_block_action.gd`, `scenes/enemy/bat/bat_enemy_attack_action.gd`, `scenes/enemy/wasp/wasp_enemy_attack_action.gd`, `scenes/enemy/horror/horror_attack_action.gd`, `scenes/enemy/horror/horror_block_action.gd`, `scenes/enemy/void_spectre/void_spectre_attack_action.gd`, `scenes/enemy/void_spectre/void_spectre_block_action.gd`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: Not run (Godot/headless checks unavailable here).
- Follow-ups: Playtest varied encounters to tune the new weight scaling (distance thresholds, finisher bonus) and ensure no AI stalls when targets are hidden or out of range.

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

**2025-11-29 – Codex**
- Summary: Completed BKL-035 by applying the standardized intent schema across the roster (including obelisk/void spectre/bulwark/blob/horror) and adding palette-based accent colors with pulse animation for intent chips.
- Files: `ui/enemy_ui/intent_ui.gd`, `scripts/resources/intent.gd`, `scenes/enemy/obelisk/*`, `scenes/enemy/void_spectre/*`, `scenes/enemy/bulwark/*`, `scenes/enemy/blob/*`, `scenes/enemy/horror/*`, `ai/planning/todo.yaml`, `ai/state/progress.json`
- Verification: `& "D:\Godot-Editors\godot.cmd" --headless --check-only`
- Follow-ups: In-game pass to ensure intent colors map well (especially obelisk spawn/wait) and tweak heuristics or explicit accent colors if needed.

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
- Summary: Retuned the enemy roster for v0.0.6.1 by lowering early-unit damage/HP (bat/wasp/blob/horror), trimming obelisk pressure (range hit to 6, spawn cap 3, slower spawn cadence), and softening elite/void durability and payouts (capped void spectre heal/block, reduced gold rewards, lighter elite stats).
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
**2026-10-17 – Codex: Godot 4.7.2 / Talo 1.2.0 compatibility**
- Preserved the existing dirty working tree and addon upgrades. Consulted Godot 4.7 documentation via Context7 and Talo's 1.x identification/events documentation.
- Migrated identity callbacks to TaloPlayerAlias; centralized event string conversion and identity/preference guards; prevented overlapping identification; applied telemetry opt-out cleanup; routed menu quit through Talo's flush notification.
- Added safe defaults for partial settings, restored sandbox offline state, removed the menu/data-editor preload cycle, repaired 18 external-resource UIDs, corrected the renderer feature tag, and updated CI to 4.7.2.
- Fixed Obelisk scene teardown triggering victory and detached world-message timer calls. Added fallback returns to four gradient shaders.
- Verification: loaded 487 first-party resources; numeric event/alias/opt-out checks; menu, sandbox, new run, save/load, and combat startup. Final isolated headless runner exited 0 with zero failed assertions and no script errors. Hidden D3D12/Forward+ smoke run also passed, with no shader compilation errors.
- Remaining diagnostics/limits: headless dummy-renderer sampler diagnostics, sandbox Windows certificate-store access failure, a retained MapNode script at shutdown, and stale imported-background UID cache warnings. Live backend delivery, packaged exports, and complete campaign QA remain unverified. Details: `ai/docs/godot-4.7.2-upgrade.md`; repeatable runner: `tools/validate_project.py`.

**2026-10-17 – Codex: scene/resource architecture cleanup**
- Replaced fourteen identical embedded RGFloat emission images with one compressed binary texture; verified the saved image bytes exactly.
- Shared the six-emitter ambient effect through one PackedScene across seven screens, preserving every serialized particle property and each layer/position override. Removed 114 first-party text-resource references to generated import caches.
- Moved BattlePresentation's fixed controls/material into an editor-visible scene, instanced by game_world.tscn, with per-instance material state.
- Added the scene resource guard to the validation runner and coverage for binary resources, all seven particle layouts, overlay animation completion, and material isolation.
- Verification: baseline and updated offline Godot 4.7.2 smoke checks passed with zero failed assertions; existing headless shader/certificate/shutdown diagnostics remain. An intermediate run retained more resources; verbose and subsequent checks returned to baseline. No visual/export/campaign QA performed.
- Remaining work and manual QA: ai/docs/godot-architecture-audit.md. Existing dirty working tree and addons preserved.
**2026-10-17 – Codex: run.tscn large text-resource warning**
- The run scene is now text rather than the previous binary run.scn. Its pause menu contained two identical embedded RGFloat images and sixteen cache texture dependencies.
- Reused menu_emission_points.res and original star PNGs. Reduced run.tscn from 9,916,548 to 35,936 bytes. Compared emission arrays with the previously verified texture source and asserted every node/connection section stayed unchanged.
- Verification: scene resource guard reports zero problems; all scene resource IDs resolve; compatibility runner loads 490 resources with zero failed assertions. Normal run returned failure on the existing intermittent 8-resource shutdown retention; verbose diagnostic run exited 0 with the existing single MapNode script retention. Existing headless shader/certificate diagnostics remain.
- Manual QA: reload run.tscn from disk before saving an older editor copy; check opening/closing the pause menu visually.
**2026-10-17 – Codex: reliable hand cleanup and exhausted decks**
- Reproduced animation-dependent discard loss, null-card draw errors, and a zero-card empty-tween error. Committed discard state before phase notification, detached standalone controls, guarded empty draws, and completed zero-card draw phases directly.
- Added focused hand-cycle cases to the existing isolated compatibility scene. Godot 4.7.2 runner passed with 494 resources and zero failed assertions; existing shader/certificate/shutdown diagnostics remain. No rendered visual QA or campaign playthrough. Existing run.tscn edits preserved.
- Continuity and follow-ups: `ai/docs/continuous-improvement.md`; next investigate card resolution versus end-turn timing and empty enemy turns, establishing actual failures first.

**2026-10-17 – Codex: DataEditor enum startup crash**
- Fixed _populate_enum_options and _populate_card_filters using inherited Node.name as a dictionary key rather than enum_name/rarity_name. This caused lookups for the key DataEditor and aborted startup population.
- Added DataEditor scene startup to the compatibility smoke test, checking all enum dropdown counts and that card resource initialization completes.
- Verification: runtime smoke completed with zero failed assertions and no script errors; diff whitespace checks passed. The runner returned nonzero for the previously observed intermittent shutdown retention (8 resources), alongside existing headless shader/certificate diagnostics.

**2026-10-17 – Codex: shared theme, owned UI scenes, reward/shop and transitions**
- Migrated first-party scene styling to Rift theme variations and authored fixed UI/board visuals as scenes/resources. Containers now measure CardVisuals' actual minimum size; card selection owns its root hit/focus area. Rebuilt reward, inspection, pile and cost-selection dialogs; repeated purchases release whole shop items.
- Extracted run HUD, map legend, pause menu, run tutorial, battle HUD, battle tutorial and consolidated sandbox panel. StatsUI owns StatusHandler, CardPopup owns confirmation, and pile buttons own counters with a compact inherited presentation. Removed generated status attachments, private hierarchy injection, sandbox editable-child overrides and repeated global UI searches. Composition roots bind dependencies; EnemyHandler receives a typed enemy rail.
- Corrected both fullscreen shaders to respect CanvasItem modulation, the outcome vignette edge, whole-screen scaling and intro effects freezing over paused tutorials. Victory awaits completion, outgoing views detach immediately, and transient presentation no longer changes global music volume.
- Verification: isolated Godot 4.7.2 headless runner exited 0 with zero failed assertions. Native D3D12 checks also reported zero failed assertions, including actual shader pixels at zero/half/full opacity and scene pack/save/reload ownership. Reviewed reward confirmation, shop, enemy inspection, selection/pile and victory captures. Existing hand-cycle, editor startup, sandbox, save overwrite, clock and shake checks remain in the suite. Resource guard and diff whitespace checks pass.
- Limits: native runner still exits nonzero on texture/resource shutdown diagnostics; headless shader/certificate and known shutdown retention diagnostics remain. No full campaign, release export or performance benchmark. Godot repeatedly resaved an old in-memory run.tscn during work; restored the extracted composition and told the user to reload from disk before saving.
- Authoring and continuity: ai/docs/ui-authoring.md, ai/docs/continuous-improvement.md and updated ai/docs/godot-architecture-audit.md. Particle profiling and further board simulation separation remain explicit opportunities.
