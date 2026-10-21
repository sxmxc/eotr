# Visual source reference

These files are maintained production inputs or provenance, not parallel developer
guides. Use [visual production](../../../docs/visual-production.md) for commands,
asset contracts and evidence interpretation.

- `rift-content.json` is read by the retained presentation builder.
- `rift-asset-inventory.json` is read by art validation.
- `battlefield-ability-direction.json` describes per-ability treatment and is read
  by the VFX inventory tool.
- `battlefield-vfx-inventory.json` is the regenerable source/consumer inventory from
  `tools/audit_visual_effects.py`; it includes vendor/demo coverage, not universal
  rendered approval.
- `visual-card-*.json`, `illustrated-fx-sources.json` and
  `visual-effects-inventory.json` retain prompts, source provenance and disposition.
  External generator paths document origin, not required runtime files.

Later event specs/reviews and actual assets supersede old treatment assumptions.
Do not delete these records as if they were disposable screenshots. New routine
runtime results belong in ignored `.qa-tmp/` folders.
