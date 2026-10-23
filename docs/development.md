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

### Bumping export versions

Use the standard-library Python tool to synchronize `export_presets.cfg` and
the displayed version in `project.godot`:

```powershell
python tools/bump_version.py patch --dry-run
python tools/bump_version.py patch
# Another build of the same patch:
python tools/bump_version.py revision
```

Choose `patch` for Conventional Commit `fix:` changes, `minor` for `feat:`,
and `major` for breaking changes (`type!:` or a `BREAKING CHANGE:` footer).
Choose the highest applicable level across the changes being released. Other
commit types do not require a bump by themselves. The tool takes an explicit
level; it does not infer releases from Git history. Use `revision` for another
build of the same patch.

Versions use the project's four-number convention, `MAJOR.MINOR.PATCH.REVISION`,
with SemVer-style bump rules (this is not strict three-component SemVer). Each
invocation increments the selected component and resets every lower component:

| Command | Starting at `0.3.1.2` |
| --- | --- |
| `major` | `1.0.0.0` |
| `minor` | `0.4.0.0` |
| `patch` | `0.3.2.0` |
| `revision` | `0.3.1.3` |

The current numeric version comes from Windows `application/file_version`.
All three export filenames are synchronized, including stale Linux/macOS presets.
The existing Windows filename suffix (for example `alpha`) is preserved by
default. Use `--prerelease alpha.1` to set a label or `--stable` to remove it.
Labels follow SemVer prerelease identifier syntax and are not incremented
automatically. For example, a patch bump from `0.3.0.1-alpha` produces
`0.3.1.0-alpha` and suggests release tag `v0.3.1.0-alpha`.

Windows file/product metadata and `project.godot`'s `config/version` use the full
four-number numeric version. AutoExportVersion reads the first nonempty preset
version (currently Windows file version), so its generated game version matches
that project setting. The addon continues to manage the Git build hash separately.
macOS native short/build metadata uses `MAJOR.MINOR.PATCH`; its filename retains
the full revision. Prerelease labels appear in filenames and suggested tags only,
keeping native metadata and the displayed game version numeric. Other settings
and each file's line endings are preserved. Close the Godot editor before
applying a bump, or reload changed files before saving them in the editor.

The command prints a suggested Conventional Commit and release tag. `--dry-run`
validates both configuration updates without writing either file. Review the diff
before committing. It does not commit, tag, publish or
change release workflow triggers. Run its offline checks with
`python -m unittest discover -s tools -p test_bump_version.py`.

The release workflow `.github/workflows/build_release.yml` runs on four-component
version tags (`v*.*.*.*` and suffixed variants), exports all three platforms and
uploads their build artifacts. Publishing/tagging is a separate release action.
Resource/runtime checks do not establish that packaged exports work. Keep release
outputs under `build/`, separate from `.qa-tmp/`.
