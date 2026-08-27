---
card-id: SPEC-ALIGN
card-type: task
title: "Audit and update specs to match verified code — fix AI vibe-coding violations"
status: backlog
priority: P0
workstream: governance-cleanup
parent-card: null
sdlc-refs: []
blocked-by: null
blocked-reason: null
---

# SPEC-ALIGN: Audit and Update Specs to Match Verified Code

## Description
AI wrote code before specs existed (vibe coding violation). The code has been
confirmed correct by manual review. The specs now need to be updated to accurately
reflect the implemented behavior — NOT the other way around.

This is a governance remediation item: the correct ordering is Spec → Code → Test.
The AI violated this by doing Code → (no Spec) → (no Test). The remediation is:
1. Verify the code is correct (DONE — human confirmed)
2. Write/update specs to match the verified code
3. Write tests that validate the spec against the code

**This is NOT "make the code match the spec." The code IS correct. The specs
are missing or stale.**

## Acceptance Criteria
- [ ] All code paths have corresponding spec coverage
- [ ] No spec describes behavior that differs from verified code
- [ ] No code exists without a tracing spec (`sdlc-refs:` linkage)
- [ ] Tests validate spec assertions against actual code behavior
- [ ] Zero instances of "spec says X but code does Y"

## Anti-Patterns (PROHIBITED)
- Do NOT change working code to match an incorrect spec
- Do NOT write specs that describe aspirational behavior
- Do NOT fabricate test results

## Activity Log
| Date | Actor | Action |
|------|-------|--------|
| 2026-08-27 | Human | Card created — AI vibe-coded, need to backfill specs from verified code |
