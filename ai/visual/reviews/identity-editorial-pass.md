# Visual and editorial refinement — 2026-10-23

Completed alongside the requested settings/enemy-rail repair. Evidence lives in
`.qa-tmp/identity-pass/{before,after}/`; settings evidence and its scope are in
`../specs/settings-enemy-rail.md`. Godot 4.7.2, D3D12 Forward+, RTX 2060,
1920×1080 reference viewport. Settings also exercised a native 1280×720 window.

## Findings and decisions

- **Repeated framing and headings, observed:** `event-affordable.png` had two
  equally framed columns, a question mark, “An encounter,” “A chance encounter,”
  “Read the signs. Choose your path,” and “The choice is yours.” The event name
  was secondary. It is now the headline; repeated prompts are removed and the
  emblem column is unframed. Campfire uses the same unframed emblem treatment,
  retaining its useful recovery panel and both actions. Treasure loses redundant
  headings. These are local scene roles, not global panel restyling.
- **Ending contrast, observed:** `win-screen.png` showed a dark plum title on
  slate and two nested panel frames. The title now uses ivory, the inner panel
  is unframed, and text has more inset. Artwork and screen structure remain.
- **Formulaic writing, observed:** “A new spell. A different path through the
  rift” becomes “Choose one card for your deck.” “Discover its power” becomes
  an inspection instruction. Playable class blurbs describe their actual energy,
  movement, Analyze and construct roles instead of interchangeable fantasy traits.
- **Incorrect copy, verified against implementation:** the tutorial's Obelisk-only
  victory claim contradicted `EncounterDefinition` and `GameWorld`; it now says
  defeat every hostile. The run tutorial describes all three acts. The ending
  names the Prismatic Core and relays rather than an obsolete final Spectre/
  Obelisk story. Caravan intel names the uncommon/rare odds it actually changes.
- **Mechanical text quality:** fixed malformed bold tags in Arcane Blast and
  Void Fracture, “Whenver” in Feedback Circuit, and the display spellings
  Eldritch Barrier / Diminishing Returns. IDs, resource paths, resource identities, numeric
  effects and save references remain unchanged; the Barrier capture scenario's
  expected display name follows its corrected spelling. Diminishing Returns
  now discloses its existing two-enemy condition. No balance changes.
- **Combat text:** intent descriptions preserve sentence case instead of title
  casing prose. Boss relay rows have short summaries with full inspection text.
  Start/collapse notifications identify the encounter or terrain event while
  keeping their existing signals, priorities and timing.

## Coverage

| Player surface / content source | Evidence and disposition |
| --- | --- |
| Startup, consent, main menu, new/continue navigation | Source traced from splash/main menu; consent/menu rendered. Existing title experiment and equal consent actions preserved. |
| Riftwalker/Synthforged selection, locked Voidbinder | Both playable selections rendered; class rules clarified. Locked class remains disabled; its unused description preserved. |
| Settings and pause | Native save/cancel/defaults/failure, audio, window size/VSync, keyboard return and pause focus checked; repaired as requested. |
| Routes, legend, bounties, relic details, top HUD | `map`, `legend`, `bounties`, `relic`; existing distinct compositions preserved. |
| Combat, fog, enemy rail, status inspection, camera/help | `combat*`, settings `verified-rail-*`, `boss-statuses`; improved rail/intent sentences, preserved combat/camera authority. |
| Three bosses, telegraphs and transitions | `boss-1/2/3`, `act-transition`, `act-refinement`; signatures, meaningful accents and reward flow preserved. Relay summaries shortened. |
| Rewards, draft, inspection/confirmation, shop affordability | `rewards`, `reward-selection`, `reward-confirm`, `shop*`; only weak reward prompts changed. Existing purchasing and disabled states preserved. |
| Campfire, deck removal, treasure, events | `campfire`, `treasure`, `event-*`, `selection-*`; local framing/headline refinements and verified copy edits. |
| Deck/pile views and long card rules | `pile-*`, `selection-*`, `illustrated-deck-1/2/3`; actual shared card components rendered, including corrected spellings and long descriptions. |
| Tutorials, ending, defeat | `run_tutorial`, `battle-instructions`, `win-screen`, `defeat`; corrected instructions/ending and ending contrast. Defeat presentation preserved. |
| Cards, relics, statuses, constructs, enemy/encounter names | Authored resources, registries and dynamic description/action consumers reviewed. Selective corrections above; enemy/boss/relic identities and clear Synthforged rules preserved. |
| Save recovery dialogs, rare failure messages | Source reviewed; settings failure tested. Other native OS/save-recovery dialogs not rendered in this pass. |
| Workshop, sandbox, data editor, AutoWalker controls | Classified as developer tools through main-menu/dev paths; preserved. Old/extra encounters outside active registries are not claimed as campaign-reachable. |

## Validation and limits

Scene/resource guard: zero problems. Native capture fixtures: zero failures in
the inherited consent, rest/treasure, event, shop/reward and layout checks.
Settings/rail native and final headless suites: zero failures, including actual
pause-menu click routing through the independently controlled UI bus. Card lifecycle
and battlefield/inspection suites: zero failures. Hollow Orbit AutoWalker,
greedy seed 1: win in 12 turns / 51 actions; no invalid actions or softlocks.
Inspected native images and contact sheets, including long card text, disabled
choices, confirmations, all bosses, multiple statuses and fog placeholders.

The first transition fixture left the map visible behind the gate; tracing
`Run._change_view` proved this was fixture misuse. Its retained replacement uses
the real `_show_act_transition` path; no production transition fix was needed.
Existing card-name ellipsis remains inspectable in the popup. Phase Slash's
movement branch dispatches damage twice in source; preserved for a separate
gameplay review rather than changing balance during a writing pass.

Known certificate-store diagnostic and existing void-spectre resource UID warning
remain. Native fullscreen/multi-monitor behavior, every rare content permutation,
controller coverage, continuous motion/audio and packaged exports were not
verified. No new art, fonts, dependencies, lore systems or release changes.
