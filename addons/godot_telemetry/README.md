# Godot Telemetry

Standalone Godot 4.7 addon. Copy only `addons/godot_telemetry` into the same path in
another project. No Echoes of the Rift autoload, schema, asset, backend or plugin is
required. The optional editor plugin exposes `telemetry/config_path`; it does not
automatically install an autoload or collect data.

```gdscript
const Client = preload("res://addons/godot_telemetry/core/client.gd")
const Config = preload("res://addons/godot_telemetry/resources/telemetry_config.gd")
var telemetry = Client.new()

func _ready():
    add_child(telemetry)
    var settings = Config.new() # Or load an authored .tres configuration.
    settings.enabled = true
    settings.game_id = "my_game"
    settings.transport = "jsonl" # null, jsonl, http
    settings.output_path = "user://events.jsonl"
    telemetry.configure(settings)
    telemetry.register_schema("level_completed", {
        "version": 1, "required": ["level"],
        "properties": {"level": {"type": "integer", "minimum": 1}},
        "additionalProperties": false
    })
    telemetry.set_consent(true) # Supply the player's actual consent decision.
    telemetry.set_context({"build_version": "1.0", "run_id": "run-1"})
    telemetry.record("level_completed", {"level": 3})
    telemetry.flush()
```

Use a JSON file containing the same definitions in other tools: `register_schema`
accepts ordinary dictionaries. The game integration uses `telemetry/schemas/events.json`
outside this addon. This is a documented portable subset, not a full JSON Schema
implementation: version, required, properties, additionalProperties, string/integer/
number/boolean/object/array/null types, enum, minimum and maxLength. Unknown versions
are rejected in strict mode. Missing fields and explicit null are distinct. Change
required fields/types by registering a new version. Definitions may carry
`versions: {"1": <definition>, "2": <definition>}` under an event name in a shared
catalog to support old and new clients together; register each definition with the
addon API. The game adapter and backend both understand that optional catalog form.
Definitions may carry
`diagnostic: true` to exclude events from the production collection profile.

Resource configuration controls enablement, consent, game/environment, profile,
endpoint/transport, batching, timeout, queue capacity, retry budget, schema policy,
excluded events, file capacity and common metadata. Default collection is disabled
and delivery is null. A session receives a random 128-bit hex ID; every event gets a
separate random 128-bit ID. No OS identifiers, IPs or personal data are collected.
`set_context` updates session/run source metadata. Timestamps are UTC ISO-8601 strings
with seconds precision (`Z`). Numbers remain JSON numbers; use strings for 64-bit RNG
states that must survive JavaScript's precision limit. Event properties belong only
under `properties`, shared metadata under `metadata`.

The envelope contains event_id/event_name/schema_version/timestamp/game_id/environment/
build_version/session_id/run_id/source_type/metadata/properties. `source_type` defaults
to human; QA applications should explicitly set bot. Metadata is untrusted client
data and does not establish identity. Never embed backend credentials in Resources.
HTTP production environments require HTTPS. The HTTP transport submits
`{"events":[...]}` and accepts only status 200 with `accepted` equal to the submitted
batch count. Adapt another backend by subclassing `transports/transport.gd` and
implementing `deliver(batch)` and `purge()`, without changing instrumentation.

`record` returns acceptance into a bounded in-memory queue, not remote delivery.
Event and batch byte limits also bound memory and request sizes. Overflow drops
newest events and increments diagnostics. Delivery is asynchronous
for HTTP; JSONL does bounded local file I/O. Retries retain event IDs and use capped
exponential backoff for network/429/5xx/ambiguous acknowledgements. Other 4xx failures
drop the batch; retry exhaustion drops with diagnostics. `health()` exposes queue,
delivery and rejection counters. Null transport acknowledges/discards cleanly.

JSONL is bounded offline collection: on capacity it truncates the current file before
writing the next batch. It is **not** an offline HTTP spool. HTTP queues are in memory
and may be lost on crashes. Disk-backed HTTP retry persistence is not implemented.
`set_consent(false)` clears queued events, cancels HTTP, and deletes the configured
JSONL file. It cannot recall an already accepted remote batch. `set_enabled(false)`
also purges. `shutdown()` disables new events and initiates one best-effort flush;
the owner should allow a bounded deadline for `busy`, draining further queued batches
with `flush()` as appropriate. No shutdown routine blocks the game indefinitely.

Tests from the host repository: `python tools/test_telemetry.py --godot <executable>`.
This creates a separate project containing only the addon and tests, with no game
autoloads, and checks schemas, JSONL, queue limits, retry/backoff/recovery, rejection,
consent, shutdown and HTTP serialization/acknowledgements. No HTTP server is started.
