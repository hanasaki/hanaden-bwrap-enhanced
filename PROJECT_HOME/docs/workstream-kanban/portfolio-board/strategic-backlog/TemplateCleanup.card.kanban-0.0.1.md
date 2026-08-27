---
card-id: TMPL-FIX
card-type: task
title: "Update SpecificationTmpl — remove runtime tdd fields"
status: backlog
priority: P0
workstream: governance-cleanup
parent-card: null
sdlc-refs: []
blocked-by: null
blocked-reason: null
---

# TMPL-FIX: Update SpecificationTmpl — Remove Runtime Fields

## Description
Remove `state`, `last-run`, `iterations`, `coverage-lines` from the `tdd:` block
in the SpecificationTmpl. The `tdd:` block retains only `test-file:` (static reference).

## Scope
- 1 template file

## Acceptance Criteria
- [ ] `tdd:` block contains ONLY `test-file:` key
- [ ] No runtime fields remain in template

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | AI | Card created from TODO kanban migration |
