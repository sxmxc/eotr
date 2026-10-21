# Agent development workflow

Follow the root [repository instructions](../../AGENTS.md) and the relevant
[developer guide](../../docs/README.md). An explicit user task takes precedence
over selecting unrelated backlog work.

For a backlog session, inspect `ai/planning/todo.yaml` and recent task handoffs.
Choose a ready item with no blockers, prioritizing urgency and concrete impact.
The file uses `ready`, `complete`, `in_review` and other historical labels; do not
invent a status migration during an unrelated task. Old context/next_steps may
predate later code. Treat proposals as candidates, not approved mechanics.

Inspect the implementation and describe the intended behavior before editing.
Use current Godot API documentation when needed; local project version and code
remain the compatibility target. Preserve existing changes and scope. Keep fixed
UI in scenes and shared theme resources. Use existing effects/turn/occupancy paths.

Choose bounded checks from [testing](../../docs/testing.md). Use AutoWalker for
actual action sequences, not as a replacement for targeted lifecycle assertions.
For visual changes use [the production workflow](../../docs/visual-production.md)
and `ai/visual/workflows/`; record only evidence actually inspected.

Update the task's existing tracking/handoff when it needs continuity. Keep the
result concise: implemented change, validation command/outcome, material limits
and actionable remaining work. Routine conversations/captures need not become
permanent Markdown. Update developer docs when behavior changes. Do not bump
release versions, commit, push or deploy unless requested.
