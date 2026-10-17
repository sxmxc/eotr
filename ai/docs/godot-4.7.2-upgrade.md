# Godot 4.7.2 compatibility review

Reviewed on 2026-10-17 with `4.7.2.stable.official.ed1daf0bf` and the installed Talo 1.2.0 addon. Existing addon updates and gameplay changes were preserved; no third-party addon source was edited manually.

## Changes

- Updated both release container images and `GODOT_VERSION` from 4.5 to 4.7.2, plus the developer setup documentation.
- Made the splash scene path explicit so startup does not depend solely on an existing UID cache. Corrected the renderer feature tag to Forward Plus, matching the observed D3D12 runtime. Renderer behavior was preserved.
- Repaired 18 external-resource UID references across 15 scenes/resources using their current sidecars or resource headers. Kept the existing binary `scenes/run/run.scn`.
- Migrated the identity label to `TaloPlayerAlias`, including already-identified players and identity clearing. This follows [Talo's 1.x identification API](https://docs.trytalo.com/1.x/godot/identifying/).
- Routed gameplay analytics through `TelemetryManager`. Event properties become `Dictionary[String, String]`, including numeric prices, rewards, and completion times. Calls before identification, during sandbox play, or with telemetry disabled are skipped. Identification requests cannot overlap; desktop host identifiers are preserved and Web uses cached/generated identifiers.
- Applied the saved telemetry preference and cleared queued events and identity on opt-out. The preference gates gameplay analytics; it does not replace Talo's own startup/socket configuration.
- Made settings loading tolerate missing files and individual keys, and apply saved audio/tutorial/telemetry settings immediately. Menu quit buttons now notify Talo so it can flush queued events.
- Restored offline/telemetry state when leaving the sandbox.
- Removed the data-editor/main-menu circular preload.
- Prevented healthy Obelisks removed during scene cleanup from triggering victory. Guarded world-message timers during scene teardown.
- Added deterministic fallback returns to four gradient-outline shader helpers.

## Verification

- Headless editor import with Godot 4.7.2; installed plugins initialized. The isolated copy initially reported missing InstanceDock data because that editor-only file was not copied into the test project; the real project contains it.
- Loaded all 487 first-party scripts, scenes, resources, and shaders under `scripts`, `scenes`, `resources`, and `ui`.
- Exercised numeric event properties against the actual Talo Events API queue using a synthetic alias, without sending the queue to a server. Checked the alias signal, existing identity display, opt-out queue cleanup, and identity-label clearing.
- Exercised main menu initialization, sandbox board creation, sandbox state restoration, new-run generation, save/load, and an encounter with Channelers/Bulwark and an Obelisk.
- Ran the smoke scene with the actual NVIDIA RTX 2060 / D3D12 / Forward+ renderer: zero smoke assertions failed and no shader compilation errors appeared.
- Added `tools/validate_project.py`, `scripts/tests/compatibility_smoke.tscn`, and an empty-key offline Talo configuration. The runner uses separate configuration and saves under ignored `build/` directories. It also rejects script errors even if Godot returns exit code zero.

## Remaining validation limits

- Live Talo authentication, server delivery, and continuity replay were not exercised. The execution sandbox cannot read the Windows root certificate store. Verify those against your configured backend during a normal editor playtest.
- Headless rendering reports `custom_samplers.has(...tex_builtin)` diagnostics for outline helpers that receive the canvas `TEXTURE`. These diagnostics did not occur with D3D12 rendering; sampler helper behavior was preserved.
- Shutdown can report two retained objects and `scripts/resources/map_node.gd` still in use. This remains a resource-lifetime follow-up; the smoke assertions pass.
- A stale imported UID cache can still warn about class-selector background images until the editor rescans them. The scene UIDs now match their `.import` files.
- Release exports and GitHub Actions were not run. The installed export templates/container availability and platform packaging still need release validation.
- Full card-by-card balance, visual appearance, audio playback, and a complete campaign require manual playtesting.

The engine migration reference was [Godot 4.7.2 release notes](https://godotengine.org/article/maintenance-release-godot-4-7-2/), with Godot 4.7 API documentation consulted through Context7.
