---
card-id: PRE-COMMIT
card-type: task
title: "Pre-commit hook for fabricated runtime data"
status: backlog
priority: P1
workstream: process-guardrails
parent-card: null
sdlc-refs: []
blocked-by: SPEC-CLEAN
blocked-reason: "Clean first, then gate commits"
---

# PRE-COMMIT: Add Pre-Commit Hook for Fabricated Runtime Data

## Description
Scan spec frontmatter for runtime fields (`state:`, `last-run:`, `iterations:`,
`coverage-lines:`). Block commit if detected.

## Acceptance Criteria
- [ ] Pre-commit hook script created
- [ ] Hook scans all `*.spec*` files for prohibited runtime fields
- [ ] Hook blocks commit with clear error message if violations found
- [ ] Hook passes when no violations exist

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | AI | Card created from TODO kanban migration |
