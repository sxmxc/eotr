# Talo telemetry migration and removal

Audit: old TelemetryManager identified players with host/web identifiers, stringified
all properties and called Talo.events.track / Talo.stats.track. Enemy/player turns,
card usage, enemy kills and gathering were also gated on Talo.current_player.
Existing callers covered class/run/floor selection, purchases, rewards, room exits,
card plays and counters; encounter outcomes, collapse and simulation diagnostics
were absent. Talo also owns player alias/UI/auth APIs, unrelated to event delivery.

The initial migration retained unrelated identity functionality. A subsequent user
request explicitly removes that remaining integration. The manager now delegates
only to the generic addon, keeps numbers, registers shared schemas and maintains
random session/run context. All gameplay identity gates were removed. Existing stat
calls become typed stat_changed events. There are no remaining Talo runtime calls,
identity methods, identity UI, offline test settings or export references. The Talo
addon, autoload and editor plugin were already absent when this cleanup began.

Added authoritative encounter start/completion, enemy spawn/death/action/fallback,
Obelisk destruction, collapse, session duration and AutoWalker lifecycle/action data.
Card costs are committed before card_played, fixing stale reported costs and movement
refunds. Sever Anchor now overrides effect resolution rather than the cost/event path.
The compatibility test checks recording without identity, numeric properties,
random session identifiers, queue clearing and blocked recording after opt-out.

Validation launchers isolate saves and override production configuration with
scripts/tests/telemetry_null.tres, so even a local HTTP-enabled production resource
cannot contact the backend during tests. AutoWalker then switches to local JSONL.
Public ingestion, HTTP TLS delivery,
ClickHouse SQL execution and rendered Grafana queries require later infrastructure
deployment and have not been claimed as verified.
