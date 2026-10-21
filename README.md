# Echoes of the Rift

[![Release build](https://github.com/sxmxc/eotr/actions/workflows/build_release.yml/badge.svg)](https://github.com/sxmxc/eotr/actions/workflows/build_release.yml)

The Rift is a tactical deckbuilding roguelite built with Godot. Spend energy on attacks, defense, movement and gathering
across a hex battlefield. Fog hides threats and periodic collapse removes outer
cells. Between battles, choose routes, acquire cards and relics, and manage health
through three acts.

## Run the project

1. Install **Godot 4.7.2** and open `project.godot`. Let resource imports finish.
2. Press **F5** for the splash/menu/new-run flow. For combat experimentation,
   open `scenes/sandbox/gameworld_sandbox.tscn` and press **F6**.
3. Drag cards to aim; right-click cancels aiming. End Turn starts the enemy phase.
   The sandbox panel can add cards, spawn enemies and regenerate the battlefield.

Python is needed for developer launchers and validators, not ordinary play.
From PowerShell in the repository root, run an offline compatibility check:

```powershell
$godot = 'D:/Godot-Editors/current/Godot_v4.7.2-stable_win64_console.exe'
python tools/validate_project.py --godot "$godot"
```

Replace the executable path with your installation. This runs the actual project
with disposable saves and Null telemetry. See [setup](docs/development.md) for
dependencies, sandbox use, troubleshooting and release builds.

## Developer guides

The [documentation index](docs/README.md) covers architecture, combat, campaign,
content authoring, testing, telemetry and visual production. Start with the
[AutoWalker guide](docs/autowalker.md) to watch or repeat real battles with bot
policies. Generated evidence goes under `.qa-tmp/`; `build/` is for game exports.
Gameplay and offline QA do not require an analytics backend.

Coding agents should begin with [AGENTS.md](AGENTS.md). Active planning and
specialized agent workflows remain under [ai/](ai/README.md).

Created by Voidmoose. Inspired by *Slay the Spire*, *Into the Breach*,
*Griftlands*, and *Settlers of Catan*.
