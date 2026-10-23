# BKL-047: enemy inspection binding

## 2026-10-22

Selected the ready P2 integration task over new mechanics, balance changes and
presentation proposals. Verified that combat already uses a screen-space rail;
the old floating-panel premise was stale. Retained authored standalone previews
and the existing status owner, queue, hover, selection and aiming paths.

Inspection now consumes Events.enemy_updated for both current stats and intent.
Removed the redundant bound-resource callback and direct refreshes from Enemy
and EnemyHandler. Replacement stats update name, max health, HP and block together.
Board presentation changes close and unpin fogged details; selection and direct
show/hover also reject hidden/dying enemies. Board and enemy-exit subscriptions
are disconnected on panel teardown/rebinding. Updated docs/ui-authoring.md and
the existing backlog entry.

Validation against the original project, offline with Godot 4.7.2:

- New regression initially reproduced six failures: fog closure/reopening,
  replacement resource identity/name/max health, and stale resource updates.
- `python tools/validate_project.py --godot D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe --combat-automation --battlefield-only` passed after the fix.
- Full `--combat-automation` passed, zero failures, exit 0. Final tests also cover
  queue parity and aiming dismissal, and restore fixture stats afterward.
- `--combat-automation --battlefield-only --capture-ui` passed on native D3D12
  Forward+ / RTX 2060, zero failures, exit 0.
- `python tools/check_scene_resources.py`: zero problems; `git diff --check`: pass.

Limits: native execution establishes assertions, not inspected rendered evidence
or a readability claim. No AutoWalker gameplay, campaign or export validation;
this change concerns binding/inspection rather than combat action sequences.
Existing Windows certificate-store diagnostic and Void Spectre UID fallback
warning remain. No commit, push, deployment, balance or scene layout changes.
