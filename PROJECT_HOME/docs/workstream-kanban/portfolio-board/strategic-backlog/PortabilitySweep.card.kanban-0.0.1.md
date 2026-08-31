---
card-id: PORTABILITY
card-type: task
title: "HostCoupledDevelopment driver sweep"
status: backlog
priority: P1
workstream: portability
parent-card: null
sdlc-refs:
  - "NoHardcodedHostPaths.spec"
  - "NoHostTopologyInSpecs.spec"
  - "RelativeResourceDiscovery.spec"
blocked-by: null
blocked-reason: null
---

# PORTABILITY: HostCoupledDevelopment Driver Sweep

## Description
3 specs under HostCoupledDevelopment driver:
- **RelativeResourceDiscovery** — PASS (2/2 cases implemented)
- **NoHardcodedHostPaths** — PARTIAL (1/2 cases, NHP-002 regression test missing)
- **NoHostTopologyInSpecs** — RED (58 autofs/NFS hardcoded path violations remain)

Includes the relative path fix (SCRIPT_DIR traversal) and hardcoded path elimination.

## Acceptance Criteria
- [ ] NoHostTopologyInSpecs: 0 autofs/NFS path violations (currently 58)
- [ ] NoHardcodedHostPaths: NHP-002 regression test implemented
- [ ] RelativeResourceDiscovery: maintained at PASS
- [ ] All 3 specs GREEN

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | AI | Card created from TODO kanban migration — was "In Progress" |
