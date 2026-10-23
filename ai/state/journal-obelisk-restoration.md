# Restore non-boss Obelisks

## 2026-10-22

User clarified the design contract: every normal and Elite encounter includes an
Obelisk; act bosses are exempt. The prior diagnosis established that Measured
Advance lacked an Obelisk, but incorrectly treated that omission as intended.

Restored 26 authored campaign compositions, retaining existing mobile enemies,
stats, encounter metadata, rewards and boss scenes. Added base Obelisks to normal
rooms and the existing strengthened profile to Elites, with explicit summon pools
from each encounter roster. Existing Obelisk profiles/pools are untouched.

Old checkpoint scenes are embedded, so authored scene edits alone did not repair
the user's continued run. SaveGame now repairs a known normal/Elite composition
only if its saved scene lacks an Obelisk and the current registered scene has one.
Only the composition is replaced; saved route, rewards/settings, player state and
bosses are retained. No checkpoint/release version change. Loading performs this
in memory and does not rewrite the original save. Read-only inspection of the
user's actual Measured Advance save confirmed restoration and unchanged SHA-256.

Added a campaign-wide composition assertion and a reusable old-composition fixture.
The focused resume check serializes that fixture, continues through Run, verifies
center placement/reveal, viable summon pool, saved reward preservation and that
SaveGame.load_data leaves file bytes unchanged. Enemy-rules fixtures now locate
named actors instead of assuming their child indices after adding the Obelisk.

Updated combat, campaign, content authoring and testing guides, the BKL-031
follow-up and campaign review with the clarified requirement. Prior BKL-047 edits
remain preserved.

Validation on the original project, Godot 4.7.2, offline:

- `python tools/validate_campaign.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --bosses-only` initially reproduced 26 missing-Obelisk assertions.
- `--obelisk-encounters-only --capture`: zero errors/failures, exit 0; native
  D3D12 Forward+ / RTX 2060. Inspected `.qa-tmp/bkl-031/campaign/measured-advance-resumed.png`:
  visible Obelisk body, 20/20 queue entry and intent, with fog elsewhere retained.
- Full `python tools/validate_campaign.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe`: zero errors/failures, exit 0, including bosses and 45-floor structural lifecycle.
- `python tools/check_scene_resources.py`: zero problems. `git diff --check`: pass.
- Three bounded AutoWalker checks used seed 1, greedy policy, tier loadout,
  max 20 turns / 100 actions / 90-second timeout and local-only telemetry:
  Measured Advance won in six turns/28 actions, one summon, Obelisk destroyed;
  Rootbound Coven lost in 11 turns, one summon, Obelisk destroyed;
  Last Coin lost in five turns. All three: zero failures, invalid actions,
  invalid AI decisions, softlocks, timeouts or configured aborts. Reports live
  under `.qa-tmp/obelisk-visibility/{measured-autowalker,act2-elite-autowalker,act3-autowalker}/`.

Visual discovery traced GameWorld.start_world -> EnemyHandler.setup_enemies ->
ProcGenTilemap.place_obelisk/reveal. Native baseline Measured Advance stills and
timing are under `.qa-tmp/obelisk-visibility/before/`; frame-01 was inspected and
showed no Obelisk. The resumed fixture uses a different setup, so its still is
presence/reveal evidence, not a matched pixel comparison. No artwork, shader,
impact timing, targeting, collapse or victory-rule changes were made.

Limits: three bot samples do not establish balance. No full natural campaign,
continuous audio/motion review or export validation. Existing Windows certificate
store and Void Spectre UID diagnostics remain; full campaign intentionally emits
a failed-write error for save recovery. No commit, push or deployment.
