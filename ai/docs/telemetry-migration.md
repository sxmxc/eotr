# Talo telemetry migration

Audit: old TelemetryManager identified players with host/web identifiers, stringified
all properties and called Talo.events.track / Talo.stats.track. Enemy/player turns,
card usage, enemy kills and gathering were also gated on Talo.current_player.
Existing callers covered class/run/floor selection, purchases, rewards, room exits,
card plays and counters; encounter outcomes, collapse and simulation diagnostics
were absent. Talo also owns player alias/UI/auth APIs, unrelated to event delivery.

The manager now delegates to the generic addon, keeps numbers, registers shared
schemas and maintains random session/run context. All gameplay identity gates were
removed. Existing stat calls become typed stat_changed events. The former automatic
host identification entry point remains a no-op for caller compatibility; it never
collects OS IDs. Existing Talo addon, identity display and identity signals remain.
Existing opt-out Talo queue/auth/socket cleanup is preserved to avoid resurrecting
old pending events. No unrelated Talo APIs or third-party implementation files are
removed or edited as part of the migration.

Added authoritative encounter start/completion, enemy spawn/death/action/fallback,
Obelisk destruction, collapse, session duration and AutoWalker lifecycle/action data.
Card costs are committed before card_played, fixing stale reported costs and movement
refunds. Sever Anchor now overrides effect resolution rather than the cost/event path.
The compatibility test checks that telemetry reaches the new addon while Talo's
event queue stays empty, and still checks alias UI and consent cleanup.

Live Talo services are unnecessary for these tests. Validation launchers isolate saves
and use the existing offline Talo settings. Public ingestion, HTTP TLS delivery,
ClickHouse SQL execution and rendered Grafana queries require later infrastructure
deployment and have not been claimed as verified.
