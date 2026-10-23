# Continuous improvement

## 2026-10-22 — Reject malformed checkpoint map graphs

- SaveGame now validates grid widths, node coordinates, next-floor route membership and the recorded last node before Run restores the map. Invalid graphs show recovery guidance and retain the checkpoint bytes instead of reaching unchecked map dereferences.
- Six serialized corruption fixtures reproduced 12 failed assertions before the fix. Focused offline Godot 4.7.2 save validation passes afterward, including recovery dialogs, unchanged files and current/legacy generated maps. Full bounded campaign lifecycle suite also passes (zero failures, exit 0); resource guard and whitespace checks pass.
- Limits: headless controlled fixtures, not human gameplay, rendered QA or export validation. The campaign suite intentionally emits a failed-write engine error; existing certificate-store/UID diagnostics and shutdown retention remain outside this change.
- Next: exercise repeated multi-floor save/resume through actual AutoWalker gameplay; inspect missing room encounter resources and disconnected routes before adding further checkpoint rejection rules.

## 2026-10-22 — Reject incomplete saved decks safely

- SaveGame now rejects missing deck resources and null card entries before Run restores them. Previously these passed validation, then failed in combat's deck/card duplication. Recovery guidance retains the original file; empty decks remain supported.
- Focused offline Godot 4.7.2 regression reproduced four failed assertions before the fix and passes afterward (zero failures, exit 0), covering both invalid forms, unchanged checkpoint bytes, visible recovery dialog and valid empty decks.
- Existing Save and Quit recovery checks also pass (zero failures, exit 0); resource guard and whitespace checks pass. Existing certificate-store diagnostic and Void Spectre UID fallback warning remain.
- Limits: controlled checkpoint fixtures, headless assertions; no rendered inspection, full campaign or packaged export. Save and Quit emits its intentional write error and shutdown reports 10 leaked objects/five retained resources despite exit 0; this is not a clean-shutdown claim. Map graph corruption and broader checkpoint validation remain future candidates.
- Next: exercise repeated multi-floor save/resume through actual AutoWalker gameplay; validate malformed map graphs against current and legacy checkpoint fixtures.

## 2026-10-22 — Keep failed Save and Quit paused

- Removed premature unpausing from the pause menu. Run releases pause only after a successful save and scene change, so failed saves cannot resume combat behind the recovery dialog.
- The focused campaign fixture reproduced one failed assertion before the fix. Godot 4.7.2 headless and native D3D12 Forward+ checks pass (zero failures, exit 0): obstructed write, unchanged checkpoint bytes, retained pause/menu, visible error dialog, explicit resume, successful retry and resumable main-menu return. Resource guard and whitespace checks pass.
- Limits: native checks are offscreen assertions, not visual review; no full campaign/export or mid-animation gameplay QA. Intentional I/O failure emits its expected engine error. Existing certificate-store diagnostic and Void Spectre UID fallback warning remain.
- Next: exercise repeated multi-floor save/resume through actual AutoWalker gameplay; inspect corrupt checkpoint validation before expanding rejection rules.

Earlier completed work and findings are recorded in [the historical improvement log](../state/continuous-improvement.md).
