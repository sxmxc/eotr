# Development setup and daily work

Use Godot **4.7.2**, matching the release workflow and existing project checks.
The feature tag in `project.godot` includes GL Compatibility, but that tag alone
does not select the active renderer. Inspect the engine startup log when reporting
rendered results; existing native QA has used Forward+ on D3D12 as well as GL.
Use the same renderer when comparing captures.

Open the original checkout in the editor and wait for imports. Launchers rely on
`.godot/global_script_class_cache.cfg` and imported textures. Missing class names,
UIDs or textures often mean import has not finished. Keep source references pointed
at assets, never `.godot/imported` cache paths. Reopen externally edited scenes
before saving an older editor copy.

Developer Python tools use Python 3.10+ and the standard library except image
packaging/art validation, which require Pillow (`python -m pip install Pillow`).
The visual capture pipeline additionally needs a full FFmpeg installation and a
working native display/graphics driver. Each launcher exposes `--help`. Examples
in these guides run from the repository root unless stated otherwise.

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe'
& $godot --version
python tools/check_scene_resources.py
python tools/validate_project.py --godot "$godot"
```

The resource guard checks first-party scene/resource authoring constraints; the
validator runs offline runtime checks. Use a real executable path, rather than
the local `godot.cmd` wrapper, for the validator. [Testing](testing.md) explains
results and focused alternatives.

## Choose an entry point

**F5** runs `scenes/splash_screens/splash_screen.tscn`, then the menu and class/run
flow. Use this path for persistence, progression and menu interaction.

**F6** on `scenes/sandbox/gameworld_sandbox.tscn` opens the developer sandbox. Its
panel can regenerate the map, spawn enemies, add cards to piles, refill stats,
toggle fog and adjust the camera. Sandbox setup differs from a production Run;
use AutoWalker encounter mode for production victory/lifecycle investigation.

The LimboConsole input action is `limbo_console_toggle` (inspect the addon input
configuration for its current key). Commands register only when their owning scene
is active. `draw_card` belongs to PlayerHandler; `hide_fog`, `show_fog`,
`show_resources` and `hide_resources` belong to the board; `add_gold`,
`add_resources` and `yeet_em_all` belong to Run. Console use is diagnostic activity
and may be instrumented; it is not evidence of normal player balance.

For repeatable combat, use [AutoWalker](autowalker.md). For screenshots/movies that
must survive process exit, use [visual QA](visual-production.md). Compatibility
captures are disposable and removed with their system-temp directory.

## Saves, telemetry and generated data

Ordinary gameplay uses Godot `user://`, including `savegame.res`. The project
name is `echoes_of_the_rift`, so look for that name under Godot’s app_userdata
directory when locating local saves. Direct editor
scene runs use those settings/saves. Python validation and AutoWalker launchers
redirect user-data environment directories into automatically cleaned system temp
storage so they do not overwrite the player's run. Never duplicate the project
or make nested test-project junctions for this purpose.

AutoWalker and capture artifacts live in `.qa-tmp/`, ignored by Git and Godot
imports and excluded from exports. Use a descriptive new subdirectory for evidence
you need to compare. AutoWalker retention is local to its selected output directory;
see its guide before relying on old files. Source scenarios in
`tools/visual_pipeline/scenarios/` and fixtures in `scripts/tests/` are maintained
resources, not disposable output.

Production telemetry configuration currently points to a LAN HTTP endpoint.
Gameplay can run without it. Use the offline launchers for QA; see
[telemetry](telemetry.md) before enabling uploads or changing instrumentation.

## Backend checkout and exports

The telemetry backend is an independent Git submodule. If needed, populate it with
`git submodule update --init backend/telemetry` (its SSH URL requires access).
Ordinary play and offline game tests do not require it. Backend edits belong to
that repository; a game commit records a backend revision through its gitlink.

`export_presets.cfg` defines Windows Desktop, Linux and macOS exports. Install the
matching Godot export templates before local export. After creating
`build/windows/`, for example:

```powershell
& $godot --headless --path . --export-release 'Windows Desktop' build/windows/eotr.exe
```

The release workflow `.github/workflows/build_release.yml` runs on four-component
version tags (`v*.*.*.*` and suffixed variants), exports all three platforms and
uploads their build artifacts. Publishing/tagging is a separate release action.
Resource/runtime checks do not establish that packaged exports work. Keep release
outputs under `build/`, separate from `.qa-tmp/`.
