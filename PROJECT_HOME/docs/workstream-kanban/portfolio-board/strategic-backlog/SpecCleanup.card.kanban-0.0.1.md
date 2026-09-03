---
card-id: SPEC-CLEAN
card-type: task
title: "Remove fabricated runtime fields from all spec frontmatter"
status: backlog
priority: P0
workstream: governance-cleanup
parent-card: null
sdlc-refs: []
blocked-by: TMPL-FIX
blocked-reason: "Template must be fixed before sweeping 55 specs"
---

# SPEC-CLEAN: Remove Fabricated Runtime Fields from 55 Specs

## Description
Remove `state`, `last-run`, `iterations`, `coverage-lines` from `tdd:` block in all
55 specs. The `tdd:` block retains only `test-file:` (static reference).

## Scope
- 55 spec files under `BwrapEnhanced2026.strat/`

## Acceptance Criteria
- [ ] Zero specs contain `state:`, `last-run:`, `iterations:`, or `coverage-lines:` in `tdd:` block
- [ ] All specs retain `test-file:` reference

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | AI | Card created from TODO kanban migration |
