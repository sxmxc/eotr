# Bulwark baseline at normal gameplay scale — expansion-bulwark-after

Status: reviewed with shutdown limitations; see [final review](card-expansion-final.md).

Evidence: `.qa-tmp/visual/expansion-bulwark-after`; 3 frames.
Expected event observed: True.

## Inspection
Record files/timestamps actually inspected and video/frame limitations.

## Findings
For each: severity, time, observation, intended result, correction.

## Regression checks
Hit reactions; combat feedback; spell identity; camera impulses; targeting highlights; tile edge synchronization; collapse; atmosphere; animation timing. Mark each observed / failed / not exercised.

## Decision
Frames 01 and 02 inspected. Wide committed threat and actual moved/recovering body observed. Native log has renderer RID/shader leaks at bounded shutdown; this capture is not a clean-engine-shutdown pass.
