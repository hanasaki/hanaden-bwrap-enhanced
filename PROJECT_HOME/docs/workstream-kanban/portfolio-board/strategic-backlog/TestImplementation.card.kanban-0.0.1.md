---
card-id: TEST-IMPL
card-type: task
title: "Implement or remove 260 NOT_STARTED test cases"
status: backlog
priority: P1
workstream: test-engineering
parent-card: null
sdlc-refs: []
blocked-by: "SPEC-DBUS, HARNESS"
blocked-reason: "D-Bus specs and harness output format required before test implementation"
---

# TEST-IMPL: Implement or Remove 260 NOT_STARTED Test Cases

## Description
260 test cases across 45 contradictory specs currently list `NOT_STARTED`. Each case
must be implemented with honest RED→GREEN TDD or explicitly removed with rationale.

## Scope
- 260 test cases across 45 specs

## Acceptance Criteria
- [ ] Every NOT_STARTED test case is either implemented (RED→GREEN) or removed with documented rationale
- [ ] Zero NOT_STARTED test cases remain

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | AI | Card created from TODO kanban migration |
