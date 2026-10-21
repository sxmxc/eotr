# Repository instructions

- Read [docs/README.md](docs/README.md) and the guide relevant to the task.
  `docs/` owns developer documentation; `ai/` owns agent workflows and planning.
  Verify implementation before trusting an old journal, proposal or backlog note.
- Use Godot **4.7.2**, typed GDScript, tabs and existing signal/effect patterns.
  Keep resource loading deterministic. Avoid unrelated gameplay, balance or
  dependency changes. Treat `addons/` as vendor code unless the task explicitly
  concerns the maintained telemetry addon.
- Fixed UI belongs in scenes; styles belong in `resources/themes/rift_ui.tres`.
  Follow [UI authoring](docs/ui-authoring.md). Preserve feedback, input, fog and
  gameplay authority when changing presentation.
- Run checks against the original project. Never copy, clone or junction it into
  a nested test workspace. Launchers isolate disposable saves in system temp;
  retained QA evidence belongs under `.qa-tmp/`. Do not prune source fixtures,
  intentional baselines or unrelated evidence.
- Use [testing.md](docs/testing.md) to choose bounded checks. Use rendered evidence
  for visual claims and [AutoWalker](docs/autowalker.md) for real gameplay sequences.
  Offline checks must not contact the backend. Report actual outcomes and limits;
  bot losses, configured aborts and engine failures are different results.
- Preserve user edits. Do not commit, push, deploy services or change release versions unless requested. When authorized to commit, follow Conventional Commits (type(optional-scope): imperative description), using a meaningful type and subject that describes the actual change. Keep commits logically focused; do not bypass commit validation. Report tooling defects outside the task scope.
- Update the authoritative guide when changing behavior. Update a planning item
  only when working on that item; do not mark unrelated work done.

For backlog-driven sessions, follow [ai/workflows/development.md](ai/workflows/development.md).
For visual agent work, begin with [discovery](ai/visual/workflows/discover.md).
