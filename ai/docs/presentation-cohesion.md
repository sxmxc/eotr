# Presentation cohesion — 2026-10-20

Implemented a shared slate/ivory/brass direction while preserving the illustrated
world, current “The Rift” title experiment, card art and existing combat effects.
No balance, progression, TileMap coordinates, pathfinding or collapse rules changed.

Changes:
- Removed bright inset resource polygons that made the field read as tokens;
  reduced the landmark glyphs, retained target masks and collapse fractures.
- Added stable broad mineral staining to the existing terrain shader. Exposed
  edges have deeper varied stone strata and contact shadows. The existing cached
  geometry rebuilds from the authoritative TileMap and its presentation events.
- Existing PhantomCamera framing reserves vertical space for tall actors and
  permits large boards to fit at a lower tactical zoom. Manual controls remain.
- Shared primary hover/pressed surfaces, aged-gold headings/energy, reward rows,
  per-type reward accents, and a short nonblocking reward-page reveal.
- Reused existing illustration as a subdued backdrop for rewards, shop, events,
  campfire and treasure. No new bitmap assets or third-party dependencies.
- Menu title/actions share a left composition, preserving the gateway on the
  right. Consent is centered and content-sized with equally weighted choices.
- Shortened the route sidebar and quieted camera help. Card names can wrap;
  enemy queue plans wrap instead of truncating meaningful clauses.
- Purchases confirm the item in the existing shop footer. Obsolete gate effects
  now release on tile-type changes. Unresolved intent templates render an action
  label rather than `%s`; known amounts are preserved.

## Native evidence

Paths below are temporary ignored artifacts; all userdata suffixes are
`Godot/app_userdata/echoes_of_the_rift/`.

| Screen | Before under `.qa-tmp/cohesion/` | After under `.qa-tmp/cohesion/` |
| --- | --- | --- |
| Battlefield, same fixture | terrain-before/…/battlefield.png | final-battle/…/battlefield.png |
| Main menu | before/…/overhaul-menu.png | after/…/overhaul-menu.png |
| Route | before/…/overhaul-map.png | after/…/overhaul-map.png |
| Rewards | before/…/overhaul-rewards.png | final-ui/…/overhaul-rewards.png |
| Shop (different inventory) | before/…/overhaul-shop.png | final-ui/…/overhaul-shop.png |
| Consent | source baseline inspected | rooms-after/…/overhaul-telemetry-disclaimer.png |
| Campfire / treasure / event | baseline event screenshot | rooms-after/…/overhaul-*.png |

Existing production pipeline: `.qa-tmp/visual/cohesion-combat` and `cohesion-final`
contain 12-second, 30 fps native captures, at most 18 sampled frames each,
timestamp metadata and an incremental comparison video. Both are after initial
edits; original-before evidence consists of native screenshots, not a video.
See `ai/visual/reviews/cohesion-final.md` for exact inspected timestamps and limits.

## Validation

- Resource/scene authoring guard: zero problems; whitespace check clean.
- Full headless combat automation: zero failures. Focused final headless
  battlefield checks also pass the new unresolved/resolved intent assertions.
- Native D3D12 terrain: zero failures, including two real shrinks, exact surviving
  edge count, rim/void separation, debris cleanup and unchanged gameplay RNG.
- Native battlefield at 1280×720 window: zero failures; targeting, camera ownership,
  gate transition cleanup and all 29 signature lifetimes exercised.
- Native consent/supporting rooms/events and reward/shop transactions: zero
  failures at 1280×720 window; inspection, affordability, purchase, skip and claim
  behavior preserved. Screenshots remain native 1920×1080 viewport renders.
- Full native UI before and after: same two existing failures for positions of
  hidden route particle emitters. Not caused or changed by this pass.
- Seed-42 tier-1 AutoWalker: 10 turns, 30 card plays, normal loss, zero failures,
  invalid card actions, softlocks, timeouts or aborts; two AI fallback decisions.
- Incremental seeded video comparison: matching setup, 10 identical actions with
  zero start drift and matching final observation. Not full mechanics equivalence.

Continuous video/audio, hardware profiling, ultrawide, exports and full campaign
were not reviewed. Large boards trade actor scale for initial spatial context;
existing zoom/pan and automatic actor-follow remain available. Sparse frames
cannot prove camera impulses or animation quality. The final placeholder guard
was tested after capture and is not shown in the movie. The shrink fixture keeps
actors on erased cells deliberately; floating actors in that screenshot are test
setup, not proof that production collapse ignores occupancy.
