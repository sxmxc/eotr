# Synthforged implementation handoff — 2026-10-23

Implemented the approved second-class plan: selectable Synthforged, Overclock,
Analyze, all 28 cards, four stationary allied constructs, enemy targeting,
two-stage Redeployment, class pools, checkpoints and AutoWalker support.
The original misspelled starter deck resource and its UID remain compatible.
Riftwalker's movement refund, Obelisk bonus and Adaptive Surge are class-gated.

Constructs use authoritative occupancy, independent stats/statuses and an awaited
allied phase before enemies. Collapse destroys them regardless of block.
Analyze damage has explicit player-side provenance; consuming hits snapshot and
remove stacks before applying their specified bonus. No mid-battle save support
was introduced. Shops/rewards now use the merged deterministic class registries.

## Validation

All checks ran against the original Godot 4.7.2 project with isolated disposable
saves and offline telemetry. Executable:
`D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe`.

| Check | Actual result / evidence under `.qa-tmp/` |
| --- | --- |
| `tools/validate_project.py --synthforged` | Zero failures, `synthforged-final-integration.log`; every card executed through real CardUI; new/continue run, shops and rarity rewards checked for both classes |
| `--combat-automation` | Zero failures, `synthforged-final-combat.log` |
| `--status-lifecycle`, `--board-queries` | Zero failures, `synthforged-regression-status.log`, `synthforged-regression-board.log` |
| `--ui-transactions-only` | Zero failures, `synthforged-regression-transactions-final.log` |
| `tools/validate_campaign.py --bosses-only` | Zero errors/failures, `synthforged-regression-bosses.log` |
| `tools/test_run_autowalker.py` | Nine tests pass, `synthforged-python-launcher.log`; mocked loss/interruption outputs are test cases |
| `tools/check_scene_resources.py` | Zero problems |
| `tools/validate_rift_art.py` | Only existing retained unused legacy FX/shuffle assets reported |
| `git diff --check` | Clean |

The final Synthforged encounter run used `--class synthforged --loadout tier_2
--seed 27 --encounter res://resources/data/battles/tier_1_channelers_bulwark.tres`
with output `.qa-tmp/synthforged-walk-tier2-final`: **win, 12 turns, 45 actions,
18/35 HP remaining, zero invalid player actions, failures, aborts or softlocks**.
Four `ai_invalid_decisions` are enemy intent revalidations; two unreachable-ground
path warnings are recorded. Card usage includes deployment, repairs, Fire Command,
Rail Lance and scans. The default Riftwalker control won in eight turns with zero
invalid actions (`synthforged-riftwalker-control`). These bounded runs do not
establish human balance or full campaign viability.

No engine script errors in final passing checks. Existing Windows certificate
store diagnostics and the Void Spectre encounter's stale UID/text-path fallback
remain. Earlier fixture failures and captures are retained for diagnosis and are
superseded by the final passing evidence. No backend, commit, push, deployment or
release-version edit was performed for this task. Concurrent splash/export/project
settings edits belong to the existing workspace and were preserved.

## Art and visual review

Character reference: `assets/rift/source/synthforged.webp`; existing source and
selector identity retained. Built-in `image_gen` produced 28 original illustrated
cards packaged at 592×396 in `assets/rift/cards/`, and four transparent 512-square
construct sources in `assets/rift/entities/synthforged_*.webp`. Prompts and output
provenance are in `ai/visual/reference/synthforged-art.json` and
`synthforged-construct-art.json`; card bindings/hashes are in `synthforged-cards.json`
and the maintained inventories. Analyze/Core icons are native SVG; purpose-specific
FX use native bounded components, so no new raster FX sheet was required.

Discovery/direction: `ai/visual/specs/synthforged.md`. Primary inspection:
`ai/visual/reviews/synthforged-reviewed.md`; final collapse framing supplement:
`ai/visual/reviews/synthforged-collapse-reviewed.md`. Native execution captured all
28 cards plus ranged/melee construct attacks, enemy contact, Overclock and collapse.
Every card's contact frame was inspected. Missing Pike/Siege textures and oversized
badges found during review were corrected and recaptured.

The initial class review used sparse native PNGs. A later Fire Command/facing fix
has a native Godot Movie Writer capture at `.qa-tmp/command-facing-fixed/capture.avi`
(419 frames at 30 FPS). Existing OpenCV decoded eight left/right samples into
`movie-facing-sheet.png`; no new Python tool or permanent regression case was added.
Cursor acquisition had failed because construct areas used layer 4 while the
selector scanned layer 8. Constructs now use layer 8; all four sprites face the
actual attack recipient. The disposable checker verified eight cursor-confirmed
commands, one energy cost each, damage, facing and retained normal activations,
with zero final failures. Its script was removed after use.

Removed redundant intermediate Synthforged captures; retained the original
functional baseline, reviewed card evidence/contact sheets, collapse before/after
and this short movie. Earlier superseded captures are no longer retained.
The movie samples show all four constructs facing both directions; continuous
animation, camera impulses, audio, export-platform behavior and human balance
remain unverified.
Human playtests should prioritize summon survival/placement and Analyze burst
balance. No reported bot win should be treated as release approval.
