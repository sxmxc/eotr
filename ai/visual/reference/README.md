# Visual source reference

These files are maintained production inputs or provenance, not parallel developer
guides. Use [visual production](../../../docs/visual-production.md) for commands,
asset contracts and evidence interpretation.

- `rift-content.json` retains the original presentation content mapping.
- `rift-asset-inventory.json` is read by art validation.
- `battlefield-ability-direction.json` describes per-ability treatment.
- `battlefield-vfx-inventory.json` retains historical source/consumer coverage,
  including vendor/demo effects. Verify current consumers before relying on it;
  it does not establish universal rendered approval.
- `visual-card-*.json`, `illustrated-fx-sources.json` and
  `visual-effects-inventory.json` retain prompts, source provenance and disposition.
  External generator paths document origin, not required runtime files.

Later event specs/reviews and actual assets supersede old treatment assumptions.
Do not delete these records as if they were disposable screenshots. New routine
runtime results belong in ignored `.qa-tmp/` folders.
