# AutoWalker abort investigation — October 20, 2026

The nine historical aborts were recorded on build `0.2.0.0`. Their local reports
are absent from this checkout, and their uploaded completion events contain no
abort reason. Four have 51 cumulative turns, consistent with the 50-turn guard;
the other five cannot be classified retrospectively from their uploaded metrics.

The current checkout is `0.2.1.0`. Reruns use the same policy/seed pairs, without
the original action traces. They are current-build checks, not exact historical
replays or evidence that higher limits alone fixed the original aborts.

Higher limits: 200 cumulative turns, 2,000 actions, 300 actions per turn, 300 seconds.

| Policy | Seed | Final result | Reported floor | Turns |
| --- | ---: | --- | ---: | ---: |
| greedy | 32 | loss | 4 | 18 |
| greedy | 45 | loss after treasure adapter fix | 5 | 30 |
| greedy | 57 | loss | 2 | 13 |
| stress | 33 | loss | 1 | 4 |
| stress | 45 | loss | 4 | 14 |
| stress | 55 | loss | 4 | 14 |
| stress | 57 | loss | 2 | 9 |
| stress | 60 | loss | 4 | 20 |
| stress | 97 | loss | 5 | 20 |

Stress seeds 33, 45, 55, 57 and 60 also ended in ordinary losses when rerun with
the original 50/500/100 limits. Their historical aborts did not reproduce.

Before the treasure fix, greedy seed 45 reached floor 9 and softlocked with 12 HP
after 41 turns. AutoWalker's progression adapter accessed the removed
`Treasure.animation_player` property. It now uses the current Open button flow,
waits for opening to finish, and permits empty treasure caches to continue.
An isolated scene test verifies this flow and guards against duplicate rewards.
The subsequent seed rerun took a different route and ended in a normal loss;
it does not replay the original treasure checkpoint.

The full 14-run investigation JSONL (4,289 events) was uploaded with its original
event IDs. The post-fix greedy-45 launch independently delivered all 624 events.
Live ClickHouse queries verified all 15 completion events and their metadata.
Useful session IDs:

- Treasure softlock: `d19805cbc2d45e5fc6518232042edd64`
- Post-fix greedy-45: `3cd09eda26ca766f416229d1b8d42b60`

New completion metadata records reason/code, encounter, scene, policy version,
action counts, configured limits, final health, last action, and diagnostic counts.
This works with the existing ingestion schema. The updated AutoWalker QA dashboard
source adds a table for aborts and technical failures. Live dashboard publication
returned HTTP 403 because the connected account lacks dashboard write permission;
the updated source still needs provisioning by the operator.

Local investigation artifacts are temporary under `qa/abort-investigation/`.
Uploaded events are queryable through `telemetry.events_deduplicated`, including
`JSONExtractString(metadata, 'reason_code')` and other metadata keys.

Validation: seven Python launcher tests, eight backend ingestion tests, backend
artifact checks, Godot telemetry tests, and isolated AutoWalker telemetry/treasure
tests passed. A real headless `--all-encounters` launch discovered and started all
27 encounters, intentionally stopping each after one action: 27 expected action-limit
aborts, zero technical or launcher failures. The new dashboard SQL also executed
successfully against live ClickHouse and returned the captured treasure softlock.
