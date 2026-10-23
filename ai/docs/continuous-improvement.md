# Continuous improvement

## 2026-10-22 — Keep failed Save and Quit paused

- Removed premature unpausing from the pause menu. Run releases pause only after a successful save and scene change, so failed saves cannot resume combat behind the recovery dialog.
- The focused campaign fixture reproduced one failed assertion before the fix. Godot 4.7.2 headless and native D3D12 Forward+ checks pass (zero failures, exit 0): obstructed write, unchanged checkpoint bytes, retained pause/menu, visible error dialog, explicit resume, successful retry and resumable main-menu return. Resource guard and whitespace checks pass.
- Limits: native checks are offscreen assertions, not visual review; no full campaign/export or mid-animation gameplay QA. Intentional I/O failure emits its expected engine error. Existing certificate-store diagnostic and Void Spectre UID fallback warning remain.
- Next: exercise repeated multi-floor save/resume through actual AutoWalker gameplay; inspect corrupt checkpoint validation before expanding rejection rules.

Earlier completed work and findings are recorded in [the historical improvement log](../state/continuous-improvement.md).
