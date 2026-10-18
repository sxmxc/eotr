# Godot architecture cleanup — 2026-10-17

This is a focused first pass, not a claim that the whole game has been reviewed or rewritten. Existing uncommitted work and third-party addons were preserved.

## Oversized scenes: fixed

Seven screens each serialized two identical 2048 × 81 RGFloat particle emission images as decimal `PackedByteArray` text. All fourteen images had identical content. This was the cause of the approximately 9.44 MiB scene warnings; the warning itself does not establish runtime generation.

- Saved the emission texture once as `resources/vfx/menu_emission_points.res` using Godot's `ResourceSaver.FLAG_COMPRESS`: 197,940 bytes. Reloaded it and verified image bytes against the original.
- Extracted the duplicated six-emitter hierarchy and its materials/textures into `ui/fx/ambient_particles.tscn`.
- Instanced that scene in main menu, map, rest, shop, treasure, battle rewards, and win screen. Preserved each screen's layer and emitter positions with instance overrides.
- Removed all 114 direct `.godot/imported` dependencies from first-party text resources. Referenced source PNGs instead. This includes two unrelated cache references in movement target selection and spark FX.
- Kept the floating point emission coordinates in a binary resource rather than converting them to a color image format or changing the emission shape.

The seven parent scenes are now approximately 3–15 KB each. Their original total was approximately 66 MiB; the replacement scenes plus the shared scene and binary texture total less than 0.3 MiB. The `.tscn` parents remain readable and editable.

Follow-up: after the run scene was converted from binary to `scenes/run/run.tscn`, its pause menu exposed another two copies of the same emission image and sixteen generated-cache references. Reused the existing binary emission texture and original star PNGs. The run scene shrank from 9,916,548 to 35,936 bytes. Every node and connection section remained unchanged, preserving pause visibility, processing, layout, and particle settings; the original emission arrays were verified against the shared texture's source.

## Fixed UI constructed at runtime: first conversion complete

`BattlePresentation` created a ColorRect, Label, and ShaderMaterial in code. They now live in `ui/world_ui/battle_presentation.tscn`, instanced directly in `game_world.tscn`. Its script handles the animations and text. The shader material is local to each scene instance so one battle's tint cannot affect another. The overlay ignores mouse input and starts hidden.

## Follow-up status

The list below records the original audit findings. The subsequent implementation resolved items 1–5: owned enemy queue entries; recoverable atomic saves with fresh independent loads; a monotonic active-play clock; node-bound local-space shakes; and a small legend toggle. Board presentation now lives in `board_overlay.gd` with authored highlight/outline/label scenes. The run and battle composition roots have also been split into focused UI/tutorial scenes and shared theme variations. Current details and verification limits are in `continuous-improvement.md` and `ui-authoring.md`. Particle profiling and further separation of board simulation remain opportunities, not completed performance work.

### Original findings

1. **Enemy queue signal ownership and repeated setup.** `scripts/nodes/enemy_handler.gd::_build_queue_button()` tests `is_connected()` with a fresh anonymous callable, then connects a different anonymous callable. These cannot identify the same connection. The callback captures a button whose lifetime is controlled elsewhere. Move the queue entry into a small scene with a script-owned update method and explicit enemy/stats binding. Verify enemy death, repeated encounter setup, stats changes after a button is freed, and scene teardown. `setup_enemies()` and `add_enemy()` also duplicate queue/floating-UI setup; consolidate that after preserving the obelisk-specific hooks.
2. **Save loading cache behavior and write failure handling.** `scripts/resources/save_game.gd::load_data()` uses ResourceLoader's default cache behavior for a mutable save path. Test reading, overwriting, and reading again in the same process, and choose explicit cache semantics for the save graph. `save_data()` reports failure only through `assert`, which is unsuitable for release error handling. Add a user-visible recoverable failure path and consider atomic replacement. Do not change the save format incidentally.
3. **Run clock accuracy and scene ownership.** `ui/run_ui/run_time_ui.gd` creates its Timer in code and adds a fixed 0.1 seconds per timeout. Delayed frames undercount elapsed time, and global time scaling affects the timer. Define whether the clock measures active gameplay time or wall time, then accumulate the appropriate elapsed duration and keep the label refresh separate. Put the fixed timer in the scene if still needed. Cover pause, hit-stop, save/resume, and long frames.
4. **Shake lifetime and coordinate consistency.** `scripts/autoloads/utils.gd::shake()` captures `global_position` but tweens local `position`, owns the tween on a persistent autoload, and leaves per-shake `tree_exiting` callbacks attached after completion. Bind effects to the affected node, use one coordinate space, and handle overlapping shakes. Test transformed parents and deletion during a shake.
5. **Large copied folding component in gameplay code.** `scenes/run/legend_content.gd` is a roughly 68 KB copy of a third-party CollapsibleContainer, including its original API and documentation. It is not evidence of AI-generated code. Replace its use deliberately with the smallest scene/script that the legend needs, or restore a clearly maintained dependency with its attribution and license. Check references inside `run.tscn` before changing the class.
6. **Tilemap responsibilities.** `scripts/nodes/proc-gen-tilemap.gd` combines board generation, fog, highlights, coordinate/range calculations, resource labels, and console commands. It already uses native TileMapLayers. Separate presentation from board state incrementally; verify layout/orientation before substituting native TileMapLayer coordinate/neighborhood APIs. The roguelike's procedural board generation and dynamic entity spawning are legitimate requirements.
7. **Particle budget.** The shared effect still has six 1,000-particle emitters, long lifetimes, and sub-emission. Sharing its scene/resources does not remove simulation cost. Profile the target renderer/hardware before reducing counts or replacing the effect; this pass preserves its appearance/settings.

## Verification

- Baseline and updated offline compatibility smoke runner cover resource loading, menu, sandbox, new run, save/load, and combat startup.
- Added checks for all seven screens' particle layers/positions/counts and shared floating point texture; overlay animation completion and per-instance shader isolation; binary `.res` loading.
- Fixed the smoke runner's RNG seed for reproducible generated encounters and added a `--verbose` diagnostic option. Final normal and verbose runner executions both exited 0 with 490 resources loaded and zero failed assertions.
- One-time migration comparison verified every serialized particle property and referenced resource definition against the pre-extraction scenes, with instance overrides resolved.
- `python tools/check_scene_resources.py` checks first-party `.tscn`/`.tres` resources for generated-cache dependencies and large embedded byte arrays. The compatibility runner executes it before Godot.
- Existing headless shader-compiler diagnostics, Windows certificate-store access failure, and retained `MapNode` resources at shutdown remain. One intermediate run reported extra retained resources; the verbose diagnostic run and subsequent full smoke run returned to the baseline count. These diagnostics must not be described as a clean shutdown.
- No visual approval, renderer performance benchmark, packaged export, or complete campaign playthrough was performed. In the editor, reopen changed scenes from disk before saving an older open copy. Check the seven screen backgrounds and battle intro/victory/defeat presentation visually.

Godot documentation: [resource saving and external resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html), [scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html), [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html).
