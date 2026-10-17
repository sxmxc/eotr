# Rift UI / UX overhaul

## Corrective pass following rejected presentation

The first visual pass was rejected. Passing resource/logic checks did not make its
presentation adequate. The supplied playthrough shows large empty panels, a
washed-out battlefield, illegible floating enemy panels, aiming cards obscuring
targets, and relic/bounty overlays with no deliberate composition.

Recompose around these concrete constraints:
- Combat: a dark, quiet field; a full-size hand in a dedicated bottom zone; a
  narrow enemy rail; compact round/collapse text; one contextual terrain line.
  Keep card energy beside the hand. Bounties remain available in a compact line.
- Cards: native dark faces, ivory rules, legible names and cost medallions. Replace
  the meme placeholder with existing semantic game icons, preserving authored art.
  Aim from the bottom hand zone, never from the center of the battlefield.
- Enemy inspection: screen-space detail in the rail, never a scaled world panel
  over a target. Keep status ownership and gameplay connections intact.
- Character selection: readable left column, uncovered character art on the right,
  compact named class choices, explicit locked states and a prominent embark action.
- Map: a restrained route canvas with a bounded legend and a small progression
  heading. Relic/bounty inspection becomes a centered opaque modal over a quiet scrim.
- Rewards: content-sized collection rows, a clear completion action and no empty
  700-pixel-tall list. Use the same ink, brass and teal visual language throughout.

Validate the actual aim, inspection and modal states shown in the rejection,
including a progressed encounter and varied card counts. Screenshots of idle
startup are insufficient evidence of interaction quality.

## Experience and audit

Deckbuilder first: inspect a readable hand, assess the hex field, aim, resolve, repeat.
Preserve the existing card resolver, costs, keyword tooltips, targeting cache, hex
coordinates, weighted/conditional AI, fog, collapse damage, and Obelisk hooks.
Existing art, semantic intent icons, impact profiles, and pooled target sprites are
useful foundations. Current weaknesses: competing left/right panels, tiny queue
entries without intent context, handwritten body text, opaque repeated borders,
fixed hand geometry, abrupt hover, uninspectable unaffordable cards, and a collapse
counter labelled only “Void”. A one-card hand samples curves with division by zero.

## Concrete visual direction

Use ink-blue surfaces (#111923), warm ivory text (#ede6d6), muted slate secondary
text, rift teal (#66d9c7) for available actions, gold (#d9b76f) for objectives,
coral (#ef887a) for danger. Retain rarity colors. Body typography uses Godot's
readable fallback font; Cinzel remains available for thematic headings. Use 24–28
logical-pixel body text at the existing 1920×1080 design size, 8/16/24 spacing,
thin edges and restrained shadows. Keyboard focus must remain visible. No new art
dependency. Motion: 100–150 ms hover, 180 ms hand settling, short impact response;
never delay effect resolution for cosmetic motion.

## Combat composition and interaction

Reserve the bottom center for full-size cards; expand its width and dynamically
overlap larger hands. Lift the inspected card above its neighbors with a stable
hit region; unaffordable cards remain inspectable. Keep energy/health beside the
hand and end turn at its right edge. Keep piles peripheral. Reduce queue width
competition and put known intent beside health/block; distinguish the Obelisk as
OBJECTIVE. Queue order follows actual handler order; intents are current plans,
may change with position/status, and must never be advertised as guaranteed.
Only show enemy information when the corresponding entity is visible under fog.
Aim uses teal legal hexes; right click cancels. Preserve target validation and
previews, fix screen-relative cancellation, and route played/exhausted cards to
their actual pile. Decorative layers ignore input.

## Battlefield and encounter information

Preserve terrain art and fog semantics. Separate target visualization from board
generation with a focused overlay node, keeping existing coordinates and pooling.
Collapse warnings use coral outlines on visible endangered hexes, an explicit
round countdown, and a personal danger message when the player is on the edge.
Do not reveal hidden tiles or enemies. Explain lethal collapse using actual rules.
The Obelisk remains mechanically unchanged and gets a gold objective label.
Keep status and contextual inspection available rather than duplicating it everywhere.

## Supporting screens

Apply the same readable typography, surfaces, button states and focus treatment to
menus, rewards, relics and settings. Main menu keeps one clear continue/new-run
choice; character selection must retain locked states and descriptions. Encounter
map keeps route generation, selectable/current/completed states and encounter
icons. Replace the unused oversized legend script only after checking serialized
references; a native button/content toggle is sufficient for folding content. Sandbox
and editor stay practical developer utilities.

## Correctness and implementation order

1. Save safely to a sibling temporary resource, check errors, replace the old file
   only after a successful write; preserve `.res` format. Reload the save graph
   without cached save/subresources, isolating mutable dependencies. Report failures
   in a persistent dialog.
2. Give queue entries their own scene, named signal handlers and explicit binding;
   consolidate enemy setup while retaining Obelisk death/spawn behavior.
3. Improve hand/HUD composition, hover, targeting cancellation and pile feedback.
4. Extract target rendering and add visibility-respecting collapse presentation.
5. Fix shake ownership/coordinates and active run timing, then shared styling and
   supporting-screen refinements. Time counts unpaused run time including hit-stop
   and encounter transitions, excludes paused time and offline save time.
6. Run targeted persistence/lifecycle checks and the existing integration validator.
   Inspect actual rendered combat; headless validation cannot establish appearance.

## Audit tracking and validation

| Finding | Status | Delivered / limit |
| --- | --- | --- |
| A: Queue ownership | Resolved | Dedicated scene owns selection, hover, focus and named connections; explicit enemy/stats binding and disconnect on exit. Shared encounter/spawn setup retains Obelisk hooks, disconnecting objective teardown during resets. Enemy selection now pins the existing contextual stats display; end-turn closes it. |
| B: Save reliability | Resolved | Checked sibling `.pending.res` write and replacement, boolean result, persistent wrapped error dialog, recoverable load failure, and quit stays in the run on failure. `CACHE_MODE_IGNORE` reloads embedded state, then `duplicate_deep(DEEP_DUPLICATE_ALL)` isolates external mutable resources while preserving graph aliases. External authored dependency loading retains the normal cache; deep-ignore loading caused an engine crash during initial validation. Existing save fields/formats are retained. |
| C: Run clock | Resolved | Monotonic microseconds count active unpaused run time, including hit-stop and scene transitions; getter samples current elapsed time independently of the scene-owned 250 ms refresh timer. Save/resume excludes offline time. Final victory/death stops the clock. |
| D: Shake | Resolved | Node-owned tweens use local coordinates, restore origins on overlap, and shake unit sprites rather than authoritative unit positions. No per-shake lifecycle signal callbacks. |
| E: Legend | Resolved | Copied script was already absent in this checkout; removed its stale metadata and installed a small native button/content toggle. Scene paths remain intact. Six icon/label rows use readable colors and smaller icons. |
| F: Tile responsibilities | Partially resolved | Focused `board_overlay.gd` owns existing pooled target sprites, highlight assets/cache and collapse outlines. Board generation, coordinates and fog authority remain unchanged. Both combat and sandbox use it; rendering filters hidden cells and refreshes on fog changes. Resource labels and other presentation still live in the board script. |
| G: Particles | Deferred with justification | Counts/lifetimes unchanged. Shared six-emitter effect appears in menu/map/rest/shop/treasure/rewards/win; run pause retains another six-emitter set. Map plus encounter/reward screens can coexist in the run tree. No controlled representative GPU/overdraw benchmark was captured, so no budget/performance claim is made. GL reported unsupported sub-emission. |

## Corrective implementation and rendered review

- Reauthored native card faces: dark frame, separate art well, readable effect text,
  compact type/rarity, and cost badge. Existing authored art stays; placeholder art
  uses the established sword, wingfoot, shield and skill icons. Long effects can
  expose their complete text on inspection; ordinary rules are not repeated in a
  second popup. Keyword explanations remain available.
- Combat reserves a bottom hand zone and frames the field above it. Energy and
  end turn sit beside the hand; collapse, turn instructions, announcements and
  terrain stay in the left rail. The right rail holds five compact enemy rows and
  a screen-space inspector with HP, block, statuses and the full current plan.
  Drag/aim suppresses inspection panels. Aiming cards stay at the hand edge.
- Fixed a presentation defect uncovered by rendered interaction checks: target
  overlays had applied the movement free-cell predicate to occupied enemy hexes.
  They now respect the supplied card targets, board existence and fog, without
  substituting movement legality. Hex outlines also use local quad coordinates
  instead of atlas sheet UVs. Neither change alters the authoritative target rules.
- Character selection has a readable left column and exposed character art;
  locked classes remain disabled. Relic and bounty inspection use centered opaque
  modals with local close controls. Three bounty contracts fit without clipping.
  The route heading and folding legend occupy the left margin, away from nodes.
  Map particle-layer visibility now follows map visibility.
- Victory has a bounded outcome panel. Rewards use content-sized collection rows
  and a prominent return action. Fixed the empty-state label appearing alongside
  uncollected rewards. Both layouts retain the existing reward handlers.
- Reviewed rendered menu, character, settings, map, expanded legend, relic,
  bounties, fog, combat, aim, enemy inspection, hover, ten-card unaffordable hand,
  victory and rewards. Captures live under
  `build/compatibility-validation/overhaul-*.png`; the capture fixture now uses the
  real battle-over handler before moving to rewards. Native Forward+ checks
  verify the aiming card position, targeting arc, occupied target outlines and
  screen-space inspection ownership. This is a focused encounter fixture, not a
  full campaign playthrough or user acceptance.

## Delivered experience and checks

- Shared ink surfaces, thin borders, visible keyboard focus and readable gameplay
  fonts; Cinzel menu title preserved with a lighter outline. Run top bar follows
  the same type/color direction. Character transitions cancel previous tweens;
  locked classes retain their lock/tooltip. Settings now observe changes without
  per-frame polling and load controls without firing user-action signals.
- Wider, resize-aware hand, safe zero/one-card geometry, 180 ms settling, 120 ms
  lifted inspection, inspection of unaffordable cards, responsive tooltip dismissal,
  click-without-drag recovery, viewport-relative aim cancellation, invalid-release
  feedback, and actual Control pile centers for play/discard/reshuffle animations.
  End turn disables during card drag/aim. Existing card validation/effects stay intact.
- Compact fog-filtered enemy plans include HP/block, meaningful intent text and a
  gold Obelisk objective. Current plans remain conditional. Collapse uses the actual
  round counter, coral visible edge outlines, lethal-consequence tooltip and a
  player-edge warning. Announcements no longer cover the objective queue.
- Encounter map zoom shows more route context. Available/current/cleared labels,
  hover encounter names and route accents complement the existing art and paths.
  Sandbox exported references and pile counters were repaired during validation.
- Extended the existing smoke runner with focused checks: same-process overwrite
  and nested-state independence, shared map-node identity, repeated queue binding,
  freed entry followed by stats changes, repeated encounter setup/teardown, clock
  delayed frames/pause/hit-stop/resume, overlapping shake beneath transformed parents
  and deletion, card press/release/drag/cancel, pinned enemy inspection, and fog-safe
  queue/target overlays. No new test framework or golden-image suite.
- Integration command: `python tools/validate_project.py --godot
  D:/Godot-Editors/current/Godot_v4.7.2-stable_win64.exe`. Normal and diagnostic
  runs load 494 first-party resources and report zero failed checks. Existing
  shader-compiler/certificate diagnostics and retained `map_node.gd` at exit remain;
  one intermediate shutdown retained eight scripts, while the verbose audit and
  subsequent checks returned to the one-resource baseline. No clean-shutdown claim.
- Optional `--capture-ui` on the isolated smoke scene renders menu, character,
  settings, map, expanded legend, combat/fog/hover and a ten-card, zero-energy hand.
  HDR viewport captures encode linear pixels to sRGB before reducing to 8-bit color,
  preserving dark gradients. Native review
  ran at 1280×720 with default D3D12 Forward+ and 960×540 with GL Compatibility,
  against the existing 1920×1080 logical viewport. The feature tag says GL but the
  current configuration actually defaults to Forward+; renderer selection was
  preserved. Native rendering additionally reports texture RID cleanup diagnostics at
  shutdown; GL also warns about unsupported sub-emission. These are limitations, not evidence of performance improvement.
- Optional `--exercise-save-failure`, guarded to the isolated validation project,
  makes the pending file unwritable, checks a false return, unchanged previous-save
  SHA-256 and visible error dialog, then removes the fixture. Its expected engine
  I/O error is separate from the normal successful integration run.

Remaining review: a full campaign/controller pass, long localized descriptions,
ultrawide displays, multi-status crowded combat, OS replacement failure and power
loss. Sibling rename avoids exposing incomplete serialization but is not a promise
of power-loss durability on every filesystem.

API references: [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html),
[DirAccess](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html),
[HDR viewport captures](https://docs.godotengine.org/en/4.7/classes/class_viewporttexture.html).
