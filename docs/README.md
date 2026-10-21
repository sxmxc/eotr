# Developer documentation

The Rift is a tactical deckbuilding roguelite built with Godot. These guides
cover the game systems, content authoring, development tools and operations.

Start with [development setup](development.md), then read the
[architecture](architecture.md) and [combat guide](combat.md). For a specific task:

| Task | Guide |
| --- | --- |
| Understand acts, bosses, rewards or save/resume | [Campaign and progression](campaign.md) |
| Add cards, relics, enemies or encounters | [Content authoring](content-authoring.md) |
| Choose a check and investigate failures | [Testing and QA](testing.md) |
| Reproduce a battle, watch bot decisions or compare seeds | [AutoWalker](autowalker.md) |
| Modify automation or interpret replay boundaries | [AutoWalker internals](autowalker-internals.md) |
| Instrument gameplay, query events or operate analytics | [Telemetry](telemetry.md) |
| Capture and compare actual rendered effects | [Visual QA and production](visual-production.md) |
| Change UI layout or shared styling | [UI authoring](ui-authoring.md) |

[AGENTS.md](../AGENTS.md) is the coding-agent entry point. Agent workflows,
planning and visual critique instructions live in [ai/](../ai/README.md).
The backend and reusable telemetry addon retain their own package references;
the telemetry guide explains how they connect to this game.

## Maintaining these guides

Update the guide that owns a subject when changing its behavior. Verify commands
against the launcher and claims against scripts and authored resources. Explain
purpose, prerequisites, expected output and failure investigation where relevant.
Link to another guide instead of maintaining a second account of its rules.

Keep game rules and operating procedures here. Track unfinished work in
`ai/planning/` and distinguish approved direction from proposals there.

Routine logs, movies, generated reports and experiments belong in ignored
`.qa-tmp/` subdirectories. A reusable scenario, test fixture, intentional baseline,
source manifest or approved direction is source material and must not be pruned
as a temporary capture. Session notes do not automatically need permanent docs.
Use version control for superseded explanations.

