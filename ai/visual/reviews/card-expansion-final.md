# Card expansion and boss presence: inspected evidence

Visual pipeline: Godot 4.7.2 Forward+, native 1920x1080 PNGs. No continuous movie/audio
was inspected. Source contact sheets are review aids; gameplay claims below use
actual CardUI/battle captures. No human balance or whole-project audit is claimed.

## Source inspection and revisions

Inspected approved Arcane Bolt, original Riftwalker, Synthforged source/entity,
Deploy Sentry, Fire Command, Field Repairs, Reserve Capacitor, Target Scan,
Thruster Assault, Pike/Sentry entities, and original Bulwark/Spectre/Obelisk.
The first Synthforged batch lacked its actual character reference and was rejected.
Cash Out's extended hand and near-identical correction were rejected; final pose
uses two small closed hands attached coherently to the shoulders. Shared Sure
Footing and Keep Distance initially depicted Riftwalker; replacements omit class
identity. The horn-bearing Spectre was rejected for identity drift; final teal
hood, cyan chest and plum spectral body match the original. Flanking Maneuver's
beam was removed because the card deals no damage. Source sheets and full-size
corrections were inspected. Accepted pixel data is now at canonical per-card paths;
rejected revisions live only in ignored `.qa-tmp/expansion/rejected-art/`.

## Native card evidence

`.qa-tmp/visual/expansion-riftwalker-modular/`: the fixture completed real plays of
8 Riftwalker and 6 shared cards with no fixture failures. Earlier equivalent card
faces in `expansion-riftwalker-cards` were also inspected: Cash Out before,
Sure Footing before, Backwash recovery. The revised Cash Out pose reads inside the
actual hand; Sure Footing is neutral equipment; Backwash shows authoritative block
8 and its real discard transition. Rules fit the existing CardVisuals layout.

`.qa-tmp/visual/expansion-synthforged-modular/`: fixture completion has no failures.
Service Cycle before, Flanking Maneuver before and Power Tap before were inspected
at full viewport size. Synthforged/Pike identity survives the card viewport; the
flanking artwork no longer implies damage, and Power Tap's six-line rules fit.
The first `expansion-synthforged-cards` pass was rejected because native logs exposed
missing ID-derived VFX paths despite fixture assertions passing. Resolver feedback
now uses authored PackedScene references; the modular capture has no such errors.

## Native boss evidence

Baseline `.qa-tmp/visual/expansion-bulwark-before/frame-02.png` was inspected:
ordinary-unit-sized body under a dominant health meter. Native campaign captures
`.qa-tmp/bkl-031/campaign/act-1.png`, `act-2.png`, `act-3.png` were inspected after
initial changes. They showed increased physical size, Bulwark's wide amber threat,
and the new Core silhouette. Spectre's enlarged head overlapped the boss HUD.
A whole-arena fit was tried and rejected because it made actors too small.
Final framing uses revealed combatant sprite bounds in the existing Phantom
Camera; revised act-2.png was inspected and its head/intent now clear the HUD,
with the apparition larger than the player and Anchor. Current boss native suite
also checks whole-body movement, visible flank/hidden anchor targeting, one area
hit per entity, block-bypassing non-anchor collapse and remaining-relay victory.

## Regression checks

- Hit reactions: exercised by runtime/native fixtures; sparse recovery stills do
  not establish continuous motion quality.
- Combat feedback: observed block 8, actual HP/resource results and card disposal.
- Spell identity: source and representative hand faces observed; corrections
  remove mismatched character identities and a misleading damaging beam.
- Camera impulses: not visually verified; existing camera authority retained.
- Targeting highlights: wide Bulwark threat observed; hidden-anchor authorization
  and full-body cells asserted by the focused boss test.
- Tile edge synchronization: authoritative footprint/movement/collapse assertions
  pass; broad animated edge review not exercised.
- Collapse presentation: existing animation retained, body death/cleanup asserted;
  no continuous breakup movie was reviewed in this task.
- Atmosphere: observed original slate battlefield, restrained palette, no new
  generic full-screen particle layer.
- Animation timing: native authored arrival/windup/release exercised, but sparse
  stills cannot establish continuous timing or audio quality.

Decision: integrate corrected source art and modular content with the stated
limits. This is the agent's inspected integration decision, not user approval of
all artwork or a claim that the entire repository's architecture is clean.

## Final real-sequence comparison and tooling limits

`expansion-bulwark-after/frame-01.png` (1.5 s) and `frame-02.png` (4.0 s) were
inspected against the same seed/8-second baseline. Frame 01 shows the much broader
illustrated body and wide committed amber tread; frame 02 shows its moved body,
open-plating state and actual four health damage after the player's defense.
The event trace includes Siege Bulwark's completed enemy action. Actor scale and
body geometry intentionally differ, so this is not an identical-mechanics claim.
The bounded capture exits during live work and reports renderer RID/shader leaks.
Those are retained diagnostics, not fixture failures or a clean shutdown pass.
The shared engine certificate-store diagnostic and UID fallback warnings also
remain in some logs. No backend was contacted.

Final structured outcomes: `.qa-tmp/expansion/verification.json`. The final card
suite also verifies independent effect resources between deck copies and a single
authoritative ConstructDefinition per summon. Art bindings use canonical names;
the validator reports only its previously documented retained-unused list.
