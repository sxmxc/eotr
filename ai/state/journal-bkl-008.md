# 2026-10-20 - BKL-008 relic acquisition investigation

- Plan: audit event/identity coverage, compare acquisitions by source/build/outcome,
  then record measurement gaps before balance changes.
- Read-only Grafana audit completed against telemetry.events_deduplicated with a
  fixed event/ingestion cutoff. Evidence, extraction SQL, cohort criteria, outcome
  tables and floor coverage: ai/docs/relic-acquisition-baseline.md and .sql.
- Eligible cohort has 24 human-labelled development runs and 236 run-mode bot
  identities; all 30 claims and 8 purchases reconcile. Bots cannot buy at shops.
- Exact floor curves and purchases per shop visit are unavailable; resumed run
  IDs are not persisted. No balance or runtime code changes. BKL-008 remains
  in_progress for measurement follow-up and a supported tuning decision.
- Confidence 9/10 that the sample does not justify reducing shop stock now.
- Verification: live query succeeded, cohort/source totals reconciled; formatting
  and progress JSON checked. Runtime tests omitted for docs/query-only changes.
- Sidecar journal follows the documented invalid UTF-8 issue in journal.md;
  no unrelated journal content rewritten. No unexpected workspace changes seen.
- Follow-up: complete room/floor attribution, persist run identity, collect human
  histories; scope bot purchases separately if automated economy testing is wanted.
