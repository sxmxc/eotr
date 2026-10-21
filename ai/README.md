# Agent workspace

Start with [AGENTS.md](../AGENTS.md). Human-facing setup, systems, tooling and
operator guides live in [docs/](../docs/README.md); do not maintain copies here.

- [Development workflow](workflows/development.md) explains backlog-driven work.
- [Grafana access](workflows/grafana-access.md) records the agent connection setup.
  Query semantics and backend operation belong to [telemetry](../docs/telemetry.md).
- [Campaign review](planning/campaign-review.md) retains the ongoing multi-act/boss
  requirement, acceptance work and design questions.
- `planning/todo.yaml` tracks tasks. Older completed entries retain historical
  wording; verify current behavior and respect the ongoing campaign requirement.
- `state/` contains handoffs and implementation evidence, not game specifications.
  The main journal has known invalid UTF-8; use existing separate handoffs when
  needed rather than silently re-encoding the whole file.
- `visual/workflows/` contains discovery, direction, implementation and critique
  instructions. `visual/specs/` records event-specific direction; `visual/reviews/`
  records what was inspected and its limits. Later corrections supersede earlier
  proposals; read the final correction before reusing a treatment.
- [Visual reference](visual/reference/README.md) holds retained tool inputs,
  inventories and provenance. Generated movies/captures go under `.qa-tmp/`.

Use [next-task-prompt.md](next-task-prompt.md) only for a requested backlog session;
an explicit user task takes priority. `ci-agent.md` describes autonomous improvement
sessions when invoked, not standing authorization to change balance or commit.
