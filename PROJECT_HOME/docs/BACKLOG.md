<!-- (c) 2026-* Frederick Bloom -- BACKLOG.md -- Hanaden AI -->

# Backlog — bwrap-enhanced

> **Single Source of Truth:** `CONSTITUTION.md`
> **Current Release:** `0.4.1` (branch `0.4.1-a`)

Items deferred from the current release are tracked here with version tags.
Each item includes the context and rationale for deferral.

---

## 0.4.2 (deferred from 0.4.1)

### From: CLI Revision Collab Doc (Item 6 Phases 2-4)

**Rationale:** Phase 1 (read-only audit) is sufficient for 0.4.1. The remap
and new spec/test writing is substantial scope — 40 untested specs, 167
organic tests. Doing this in 0.4.1 risks scope creep.

- [ ] **Item 6 Phase 2:** Remap 14 Category A tests to correct spec paths
- [ ] **Item 6 Phase 3:** Write specs for core untested features
  - `Provision.feat` — 14 test specs, 80+ test cases
  - `Fsck.feat` — 14 test specs, 60+ test cases
  - `CliContract.feat` — 18 test specs, 30+ test cases
  - `Dispatch.feat` — 5 test specs, 10+ test cases
  - Per-flag `Flag*.feat` specs
- [ ] **Item 6 Phase 4:** Write tests for untested specs
  - `ForegroundHold.feat` (4 specs, 0 tests — orphan reaper)
  - `PassthroughArgs.feat` (5 specs, 0 tests)
  - Remaining GUI/identity/network specs

### From: CLI Revision Collab Doc (Item 4 — future seeds)

**Rationale:** Only `antigravity-ide` and `antigravity-cli` exist today for
0.4.1. Adding future seed types now means implementing code with no tests
and no users. Ship what exists, add others when they have real content.

- [ ] **--seed gemini-cli:** Seed Gemini CLI config (`.gemini/` only)
- [ ] **--seed** additional future tools as they become available

### From: CLI Revision Collab Doc (general)

- [ ] **--force-seed:** Optional override for seed corruption FATAL
  (only if users request it; unlikely to be needed)

---

## Origin

This backlog was created from the 0.4.1 CLI Revision collab doc:
`PROJECT_HOME/docs/ai-hitl-collab/20260909-013323-963842-7df1-b8be-96373f8cac1e-CliRevision.ai-hitl.collab.md`

Items were deferred by mutual HITL/AI agreement during the COLLABORATING phase.
When 0.4.1 merges to main, this file seeds the 0.4.2 planning process.
