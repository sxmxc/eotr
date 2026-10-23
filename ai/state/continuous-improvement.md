# Continuous improvement

## 2026-10-22 - Stop queued statuses at enemy death

- The shared Enemy death boundary now cancels its status batch before occupancy removal and death feedback. Ordinary enemies and Obelisks preserve already applied effects/duration changes; queued effects and batch completion stop without changing death presentation.
- Regression fixtures reproduced 12 failed assertions before the fix. Focused `--combat-automation --attack-cancellation-only` checks pass headlessly and with native D3D12 rendering (zero failures, exit 0), covering death before playback and at the first applied status, unchanged pending durations and eventual node cleanup. Full headless combat automation also passes (zero failures, exit 0). Resource reference and whitespace checks pass.
- Limits: native checks are offscreen assertions, not visual inspection; no campaign/export QA. Existing certificate-store diagnostic and Void Spectre resource UID fallback warning remain. Independently dispatched asynchronous effects are not rolled back.
- Next: multi-floor save/resume; investigate independently dispatched effects only if a concrete lifecycle failure is observed.

## 2026-10-20 - Stop player turn work at battle shutdown

- Battle shutdown now cancels pending player draws, statuses and relic activation, disables the hand and releases player camera priority. RelicHandler owns/cancels its activation tween on replacement and tree exit. Applied effects remain committed; victory can start its normal end-of-combat relic batch after cancellation.
- Regression checks reproduced player status/draw work surviving shutdown and relic completion restarting statuses. Focused headless and native D3D12 checks pass, including partial relic application, no stale completion, and a fresh end-of-combat batch. Full headless combat, resource reference and whitespace checks pass.
- Limits: native checks use offscreen assertions, not human visual review; no campaign/export QA. Existing Windows certificate-store diagnostic remains. Cancellation stops queued handler callbacks, not asynchronous effects already dispatched by a relic.
- Next: multi-floor save/resume; enemy death during status resolution; inspect asynchronous relic-owned effects if a concrete shutdown failure is observed.

## 2026-10-20 - Cancel queued enemy statuses

- Enemy turn cancellation now kills its active status application tween before releasing action/movement work. Pending effects, duration consumption and completion signals stop; effects already applied remain committed. StatusHandler owns its tween, replaces pending batches and cancels on tree exit.
- Reproduced queued effects and completion after cancellation before the fix. Focused headless and native D3D12 cancellation/reuse checks pass, alongside existing lunge/movement checks. Tests cancel before playback and at the first applied effect, checking remaining duration and subsequent normal completion. Full headless combat, resource reference and whitespace checks pass.
- Limits: native checks are offscreen assertions, not human visual review. No campaign/export QA. Existing Windows certificate-store diagnostic remains. Already dispatched damage is preserved; player status/relic shutdown remains separate work.
- Next: multi-floor save/resume; inspect player status/relic continuations during battle shutdown and enemy death during status resolution.

## 2026-10-20 - Cancel pending enemy movement

- Turn cancellation invalidates action continuations before releasing movement waiters. Blob, Horror, Bat, Wasp, Spectre, collapse escape and tactics movement reject stale completion; Horror cannot continue its second move after cancellation. Tactics also rejects cancellation during its between-hit wait.
- MovingEnemy cancels native tweens and deferred headless destinations, restores scale and the last committed tile, and supports subsequent movement. No-path moves use the same cancellable pending state. Existing movement rules and pacing remain.
- Focused headless and native D3D12 checks pass: real mid-tween interruption, restoration, new destination commit, six action cancellation/reuse cases and cancelled completion delays. Full headless combat passes. Final no-path waiter adjustment has a separate focused headless check. Validation includes resource references; whitespace checks pass.
- Limits: native assertions ran offscreen; no human visual review, campaign or export QA. Existing Windows certificate-store diagnostic remains. Already dispatched effects are preserved; status-owned effects still need investigation.
- Next: multi-floor save/resume; status effects during battle shutdown; focused tactics coverage between multi-hit damage resolutions.


## 2026-10-20 - Cancel pending lunges; test the original project

- Seven enemy lunge actions now own cancellable tweens. Cancelling a turn stops pending hits, completion and Void Residue, restores sprite/idle state, and handles changed intent. Between-hit Horror cancellation preserves the first hit; normal effects/timings remain.
- Six baseline assertions failed. Focused headless/native D3D12 checks pass on the original project; full headless combat passed before runner replacement. Telemetry tests, nine Python tests, syntax, resource and whitespace checks pass afterward.
- User requirement: never copy/clone/junction the project for tests. Removed duplicate-project setup from validation, AutoWalker, visual capture and telemetry runners and removed obsolete guidance. Disposable saves/logs/captures use auto-cleaned system temp/user storage. Removed this session's .qa-tmp workspace; verified it stays absent.
- Limits: no manual visual review, full post-runner-change combat suite, campaign or export QA. Existing certificate-store diagnostic remains. Already dispatched damage is preserved; movement/status coroutines remain separate work.
- Next: movement/status cancellation and multi-floor save/resume. Historical artifact paths below describe old runs, not current testing instructions.


## 2026-10-20 - Escape respects active card inspection

- Shop/reward inspection consumes cancel before the run pause fallback. Escape closes inspection; the next press pauses, and another resumes. Pause uses native unhandled input so existing modal handlers get first refusal.
- Actual Escape dispatch reproduced four failed assertions before the fix. Focused shop/reward transaction checks pass headlessly and with native D3D12 rendering (zero failures, exit 0), including purchases and reward confirmation after cancellation.
- Investigated the enemy ward report: this checkout already uses target-agnostic spell_signature.gd, not the reported Player-only script. Added shared BlockEffect coverage for player/enemy block, native anchor placement, advancing illustration and cleanup. Native utility checks pass (zero failures, exit 0). Inspected .qa-tmp/compatibility-validation/combatant-wards.png showing both barriers. No ward runtime change was needed.
- Limits: no full campaign/export validation; existing Windows certificate-store diagnostic remains. Ward checks exercise the shared BlockEffect path, not each tactics decision branch.
- Next candidates: multi-floor save/resume; action/status effects during battle shutdown. Existing local event HP-cost changes preserved.


## 2026-10-20 - Rift Echo honors its HP cost

- Fixed the advertised four-HP cost being absorbed by leftover combat block. Events now use the existing direct-damage API, preserving block and run damage accounting. Authored cost and reward values are unchanged.
- Real event-button checks at zero, two and ten block cover HP loss, preserved block, damage accounting and repeated callbacks. Baseline reproduced eight failed assertions; focused Godot 4.7.2 headless event checks pass (zero failures, exit 0).
- Broader compatibility smoke loaded 654 resources and reported two unrelated map ambient-emitter position assertion failures; the unchanged map scene/test expects different coordinates. Resource reference guard and git diff --check pass.
- Limits: no visual changes or rendered inspection; no full campaign/export QA. Existing Windows certificate-store diagnostic remains.
- Next candidates: verify low-health event/death resolution end to end before changing lethal-cost rules; exercise multi-floor save/resume; inspect action/status-owned effects during battle shutdown.


## 2026-10-18 � Authored encounters, roster and coherent final art

- Consolidated typed encounter definitions/registry; removed the pool selector and migrated map, sandbox, tools and bounties. Preserved tier two and all original compositions. Added eight enemy roles, twelve behavioral variants and twenty encounters using existing rules.
- Replaced battlefield, 29 card illustrations, UI/map symbols, terrain, main menu and all three class backgrounds. Fixed class masters preserve costume identity. Removed rejected alternatives, 88 obsolete sources and 438 old import cache files; final image sources total about 5.5 MB.
- Offline combat/native compatibility and asset/alpha/hex/reference checks pass. 27 headless battles plus a rendered elite and run-mode progression executed with no runtime failures or softlocks. Full report and limits are in [rift-overhaul.md](../../docs/content-authoring.md). Full human balance/campaign and release export remain future validation.

## 2026-10-18 — Event choices preserve player agency

- Caravan trades show their currency requirements and use native disabled states when unaffordable. Currency changes update availability immediately. An unsuccessful attempt no longer consumes both event choices; exact-price purchases retain the authored costs, healing and card reward weights.
- Event choices commit once before currency signals/reward callbacks, preventing repeated callbacks from granting extra rewards. Successful choices move keyboard focus to Leave. Costs now live alongside their event option and are checked and charged in the same path.
- Added focused checks to the existing offline runner (`--event-room-only`); reproduced eleven failed assertions before the fix. Targeted headless and native D3D12 checks pass, including actual button activation, currency thresholds, failed alternatives, repeat callbacks and free rewards. Compatibility smoke passed with 531 resources and zero failures (exit 0); resource guard and whitespace checks passed. Inspected native `overhaul-event-{unaffordable,affordable,resolved}.png` captures under `qa/compatibility-validation/`.
- Limits: no full campaign or packaged export; existing Windows certificate-store and headless shader diagnostics remain. The save/resume inspection did not establish a new persistence defect.
- Next candidates: investigate event HP costs with leftover combat block/low health; exercise multi-floor campaign save/resume; inspect action/status effects surviving battle shutdown.

## 2026-10-18 — Reliable relic interactions with the hand

- Feedback Circuit now resets at the actual player-turn start, rather than whenever a draw completes. Drawing extra cards preserves accumulated skills, so the third skill still deals the authored five damage to every enemy. Acquisition/removal clears its transient counter and UI reference; obsolete map/draw subscriptions are removed.
- CardUI now refreshes affordability when its card is reassigned. Instability Emulator's randomized costs immediately update selection and cost styling, fixing free cards remaining unselectable and newly unaffordable cards retaining a playable appearance. Costs, damage and trigger thresholds are unchanged.
- Regression checks reproduced eight Feedback Circuit assertions and thirteen cost/selection assertions failing before their respective fixes. Final Godot 4.7.2 combat automation passed headlessly and with native D3D12 rendering (zero failures, exit 0), including extra DrawEffect draws, actual turn resets, relic removal/reacquisition, cost changes in both directions and mouse selection. Inspected `qa/compatibility-validation/relic-costs.png`: free cards appear active and paid cards unavailable at zero energy. Compatibility smoke passed (531 first-party resources, zero failures, exit 0); resource guard and whitespace checks passed.
- Limits: no full campaign or packaged-export QA. Existing Windows certificate-store and headless shader diagnostics remain. The suspected old map-callback leak did not reproduce; teardown checks passed before the change too.
- Next candidates: long campaign/save-resume sequences; action/status effects surviving battle shutdown; verify Instability Emulator with card selection/sacrifice flows and large hands.

## 2026-10-18 — Cancel stale enemy turn continuations

- Battle shutdown now cancels the active enemy and releases its camera/focus. Starting another enemy turn invalidates prior work; sandbox board resets use the same cancellation path.
- Fixed status/action callbacks resuming into a later activation of the same enemy, pacing timers emitting extra turn-end events after cancellation, and deferred death continuations surviving a turn reset. Reused the existing generation counter; combat balance and pacing durations are unchanged.
- Regression checks reproduced seven failed assertions before the fix. Offline Godot 4.7.2 combat automation now passes with zero failures, including cancellation during camera/status/damage waits, stale pacing rejection, and normal completion advancing the round and drawing the next hand. The compatibility smoke check also passed (531 first-party resources, zero failures, exit 0). Resource guard and whitespace checks passed.
- Limits: headless validation only; no rendered inspection or full campaign. Cancellation rejects handler continuations; it does not cancel every tween already executing inside an enemy action or status. Existing certificate-store and headless shader diagnostics remain.
- Next candidates: exercise long campaign/save-resume sequences; inspect action/status-owned effects when ending a battle mid-animation; profile particles on target hardware.

## 2026-10-17 — Native UI composition, themes, rewards/shop and transitions

- Centralized first-party typography, spacing, panels, icons, palettes and interaction states in `resources/themes/rift_ui.tres`; selected named variations instead of local overrides, duplicated styleboxes or runtime style construction. Fixed controls, status sizes and board presentation primitives are authored scenes/resources.
- Fixed the card visuals' missing intrinsic minimum size, which let containers overlap reward actions and shop prices/buttons. CardMenuUI now owns its input/focus area; decorative children do not swallow activation. Rebuilt pile, selection, reward and inspection dialogs with native containers. Popup confirmation belongs to CardPopup; repeated purchases remove complete shop item instances.
- Split the run HUD, map legend, pause menu, run tutorial, battle HUD, battle tutorial and sandbox panel into owned scenes. StatsUI owns its StatusHandler; pile buttons own their counters. Removed private hierarchy injection, generated attachment artifacts, sandbox editable-child overrides and UI group searches. Composition roots bind gameplay dependencies; EnemyHandler receives a typed rail. Required sandbox controls use scene-local unique names.
- Fixed fullscreen shaders ignoring animated alpha, the inverted outcome vignette edge, scaling the entire outcome screen from its origin, and introduction effects freezing over paused tutorials. Victory awaits presentation completion instead of an unrelated timer. Removed competing global music-volume tweens and detach outgoing views before replacements enter the tree.
- Validation covers native scene pack/save/reload ownership, paused intro completion, independent shader materials, rendered alpha at zero/half/full opacity, responsive pile/selection layouts, reward confirm/skip, shop inspection/affordability/repeated card and relic purchases, final victory, plus existing hand, save, clock, shake, editor and sandbox cases. Native captures are under `qa/compatibility-validation/overhaul-*.png`.
- Final headless runner: 518 resources loaded, zero failed assertions, exit 0. Final native D3D12 runner: 518 resources loaded, zero failed assertions, exit 1 due to texture/resource shutdown diagnostics. Resource guard: zero problems; diff whitespace check passed. The restored 2,212-byte run composition remained intact through the final checks.
- Limits: no full campaign or packaged-export QA and no performance benchmark. Windows certificate-store, headless shader compiler and shutdown resource-retention diagnostics are tracked separately from failed assertions; native runs additionally report texture shutdown diagnostics. These are not a clean shutdown claim.
- Further opportunities: profile particle costs on target hardware and exercise long campaign/save-resume sequences. Procedural generation, repeated card instantiation and hand/aim geometry remain dynamic behavior; they are not fixed UI construction.

## 2026-10-17 — Reliable hand cleanup and exhausted decks

- Fixed empty-pile draws creating null CardUI instances and raising script errors. Overdraw safely skips unavailable cards while completing the draw phase; zero-card draws complete without an empty tween.
- Discard now commits cards and detaches/disables controls before notifying the next turn phase. Interrupted animations cannot lose cards, and an immediate reshuffle sees the complete discard pile. Existing animation timings are preserved.
- Regression checks reproduced four failed assertions, null-card script errors, and the empty-tween error before the fix. Updated offline Godot 4.7.2 smoke checks passed with 494 resources loaded and zero failed assertions; resource guard also passed. Tests cover interrupted/completed animations, empty/repeated cleanup, immediate reshuffle, empty/overdrawn decks, zero-card phase completion, and standalone discard.
- Limits: no rendered visual inspection or full campaign playthrough. Existing headless shader, Windows certificate-store, and shutdown retention diagnostics remain. Existing local run.tscn edits were preserved.
- Next candidates: verify asynchronous card resolution cannot overlap end-turn cleanup; investigate enemy-turn progression when no living enemies remain; manually inspect discard transitions in combat. Review current behavior before choosing a fix.
