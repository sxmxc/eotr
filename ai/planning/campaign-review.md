# Multi-act and boss review

The multi-act/boss overhaul remains an active project requirement. BKL-031 and its
handoff mark integration complete; that label does not close remaining review or
supersede the requirement. This documentation overhaul changes no task statuses.

Established direction: three distinct acts, optional Elites with alternatives,
one mechanically distinct boss per act, persistent act transitions and meaningful
rewards. The current behavior is documented in [campaign](../../docs/campaign.md).
Historical Triune/Core Nexus ladder proposals do not describe the current bosses.

Remaining acceptance work includes human counterplay/pacing and difficulty,
continuous animation/music review, release exports and broader branch/save-resume
coverage. The seed-2 45-floor bot completion predates final preview, registry and
relay-placement edits; focused tests cover those adjustments. Use the
[implementation handoff](../state/journal-bkl-031.md) for exact evidence.

One design discrepancy needs explicit review rather than editorial resolution:
older Spectre rationale excluded healing/deck pollution; current code includes
Memory Anchor healing and conditional Void Residue. Developer docs describe the
actual mechanics without asserting that this discrepancy received design approval.
