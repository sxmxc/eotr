# Combat initiative audit — 2026-10-17

## Existing architecture

GameWorld composes the board, player/hand, enemy handler, BattleStateController,
relics and presentation. BattleStateController owns phase transitions through
Events. Card resources own costs/targets/effects; CardUI and its state machine
currently initiate plays. CardResolver awaits projectiles but damage and movement
also schedule tweens. Therefore awaiting Card.play alone is not a complete action
boundary. EnemyHandler serializes status/action completion signals and camera waits.

EnemyActionPicker prioritizes conditional children then weights chance actions.
Chance actions are not uniformly checked for feasibility. MovingEnemy uses BFS but
randomizes destinations, can oscillate, and its start==goal path permits a no-op.
Bat movement searches many paths and can traverse arbitrary distance in one action.
Bulwark movement awaits a signal after a call that can emit synchronously: a stall.
Enemy death can advance another enemy's active turn; cached actions can become stale.

Obelisk is a real immobile enemy with capped, synchronous spawning, ranged attacks,
block and wait actions. Its tile queue is a preview, not pending combatants. Destruction
currently activates end-of-combat relics immediately. Child-count victory includes
dying nodes and has no single victory-commit guard. Cleanup must cancel future Obelisk
actions, retain already spawned enemies, and evaluate victory at stable boundaries.

Roster already contains melee bats/wasps/horrors, defensive blobs/bulwarks, channeler
support/ranged pressure and the spectre boss. Improve their existing selection and
movement rather than add enemies. Preserve encounter compositions and resource rules
until measured simulation evidence supports balance changes.

## Automation and telemetry

Sandbox has real cards and debug controls but a separate setup/loop and no production
victory path. Compatibility smoke checks startup and UI interactions, not autonomous
combat. AutoWalker will instantiate GameWorld directly, reuse its turn state, hand,
targeting and CardUI play path; no synthetic engine or coordinate clicks. Legal actions
must use card target methods, fog checks and live costs. Policies receive observations
and structured actions. Runner records checkpoints and local reports; Watch uses the
same runner and an authored developer scene. Replay must fail explicitly on divergence.

TelemetryManager currently stringifies properties into Talo events/stats. Many callers
are gated on Talo.current_player. It identifies using OS host ID, and opt-out clears
Talo auth/socket. Talo also supplies identity UI; preserve those unrelated APIs/addon.
Existing events cover run/floor/class, shop/rewards, card plays, turn starts and kill
counters. Missing: encounter outcomes, collapse, AI validity, simulation and transport
health. New events retain JSON numeric types and carry source_type to separate bots.

## Implementation sequence and boundaries

1. Standalone telemetry Resource configuration, portable schemas, bounded queue and
   JSONL/HTTP/null transports; game adapter retains existing call sites.
2. Authoritative shared card validation/resolution boundary; AutoWalker legal actions,
   random baseline and headless actual encounters.
3. Correct victory, enemy queue lifetime/feasibility, deterministic tactical BFS.
4. Watch scene, policy scores, pause/step/replay and local batch artifacts.
5. Migrate telemetry guards and instrument authoritative boundaries.
6. Independent Python ingestion package, ClickHouse migration and Grafana provisioning.
   Author and test with mocks only: no API, database, Grafana or containers started.

No backend dependency belongs in combat. Generic addon must have no game event names.
Shared JSON schemas are loaded by both game adapter and ingestion service. Production
collection requires consent and defaults to null delivery; QA explicitly uses JSONL.
Backend must acknowledge whole batches, reject permanent failures, bound bodies/rates,
and query a deduplicated ClickHouse view. Clients are untrusted public senders.

See autowalker-architecture.md and telemetry-architecture.md for implemented commands,
validation evidence and remaining limitations as implementation progresses.
