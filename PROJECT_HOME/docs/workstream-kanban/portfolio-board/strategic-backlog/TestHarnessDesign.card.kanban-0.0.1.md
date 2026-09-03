---
card-id: HARNESS
card-type: task
title: "Design test harness output format (JSONL/XML)"
status: backlog
priority: P1
workstream: test-engineering
parent-card: null
sdlc-refs: []
blocked-by: SPEC-CLEAN
blocked-reason: "Clean specs enable harness design"
---

# HARNESS: Design Test Harness Output Format

## Description
Choose JSONL or XML for machine-readable test results. Align with GenericSdlcEngine.strat
standard for Bash testing (bats-core + JSONL). Separate runtime results from static spec
documents (JUnit/JaCoCo pattern).

## Acceptance Criteria
- [ ] Output format chosen and documented
- [ ] Separation of runtime results from static specs defined
- [ ] Aligns with SDLC engine standard

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | AI | Card created from TODO kanban migration |
