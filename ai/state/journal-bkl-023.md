# 2026-10-20 - BKL-023: Obelisk terminology

- Added docs/combat.md as the canonical description of existing variants and
  current role. Obelisk destruction stops its actions and summons, but remaining
  hostiles must still be defeated. Linked the encounter authoring workflow.
- Kept player-facing names, resource paths, gameplay and presentation unchanged.
  Future boss composition remains a separate BKL-031 decision. Completed BKL-023
  in todo.yaml and progress.json.
- Inspected both stats/AI resources, the spawn action, EncounterDefinition and
  GameWorld victory handling. Context7 Godot 4.7 resource/export docs consulted
  during the preceding proposal review.
- Validation: checked authored battle resources for victory-objective overrides,
  validated progress.json parsing and ran git diff --check. Runtime tests are not
  needed for this documentation-only change.
- Used this focused journal because the main journal has previously documented
  invalid UTF-8; no encoding repair is included in this task.
- Follow-up: decide whether future bosses retain Obelisks under BKL-031.
