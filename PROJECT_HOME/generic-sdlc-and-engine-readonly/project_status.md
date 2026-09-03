# Bwrap-Enhanced: Where We Left Off

## Two Active Workstreams

---

### 1. [DONE] GenericSdlcEngine.strat -- COMPLETED & COMMITTED
**Conversation:** `3360c8d8` -- "Generic SDLC Engine Refactoring"
**Commit:** `a60004d` -- `feat(generic-sdlc): add GenericSdlcEngine.strat/ artifact tree (60 nodes)`

**What was done:** Created the complete `GenericSdlcEngine.strat/` directory tree inside `generic-sdlc-and-engine-readonly/` with all 60 Hanaden UUIDv7 Extended files:

| Node Type | Count |
|---|---|
| CORP-STRAT (L0) | 1 |
| T-DRIV (L1) | 6 |
| T-MOTI (L1) | 6 |
| FEAT (L2) | 14 |
| SPEC (L4) | 33 |
| **Total** | **60** |

**All 9 tasks completed** [DONE] -- verified: file counts, YAML parsing, parent refs, no dupes, no fabricated microseconds.

**Last user action:** Asked to `git commit` the tree -> committed as `a60004d`.

---

### 2. [WIP] Portability Sweep + SecurityIsolationMatrix -- PLAN CREATED, NOT EXECUTED
**Conversation:** `50873b18` -- "Reviewing Git File Changes"
**Status:** Implementation plan was written but **never approved/executed**.

**60 uncommitted modified files** currently in the working tree -- these appear to be **partial work from this conversation** (the portability sweep for test scripts).

#### What was planned (Part A -- Portability Sweep):
- **A1:** Fix `shared/env.sh` -- derive `WS` + `BWRAP_SH` portably from `BASH_SOURCE`
- **A2:** Fix `run_phase1.sh` -- same portable derivation
- **A3:** Fix **37 test scripts** -- replace hardcoded NFS paths with 4-line portable header
- **A4:** Rewrite `AutofsShadow.spec` -> `HostPathConfinement.spec` (remove all autofs/NFS knowledge)
- **A5:** Fix `UncontainedAgentExecution.driv` doc -- remove autofs/NFS references
- **A6:** Fix `bwrap-enhanced.sh` comments -- generalize

#### What was planned (Part B -- SecurityIsolationMatrix):
- Create new `SecurityIsolationMatrix.feat/` node under `NamespaceIsolatedSandbox.moti/`
- 6-tier security model (T0-T5) with capability matrix
- Test file: `test_security_isolation_matrix.sh`

#### Open Questions (unanswered):
> **Q1:** `AutofsShadow` -- is it live or dead behaviour? Audit `bwrap-enhanced.sh` L263-270 before rewriting.
>
> **Q2:** `SecurityIsolationMatrix` -- `.spec` under `GuiPassthrough.feat` vs `.feat` under `NamespaceIsolatedSandbox.moti`? Recommended: `.feat`.
>
> **Q3:** Walk-up sentinel -- `PROJECT_HOME/` dir vs `.git` dir vs `VERSION` file?

#### What was actually modified (uncommitted):
The 60 dirty files in `git status` are mostly the **A3 test script portability fixes** (37 test files) plus:
- `shared/env.sh` -- portable WS/BWRAP_SH derivation (A1)
- `bwrap-enhanced.sh` (both copies) -- comment generalization (A6)
- `CHANGELOG.md`, `VERSION` -- bumped
- 2 spec docs (GnomePassthrough, KdePassthrough)
- 1 DRIV doc (SdlcHierarchyOverview)
- 1 new untracked file: `MotivatorDriver-terms.analy.md`
- 1 new untracked dir: `brainstorming-ideas-only/`

#### Conversation ended with:
User told the agent it was "losing its mind" -- the agent was conflating `DriverVsMotivator-analysis.analys.md` (which is scoped only to `generic-sdlc-and-engine-readonly/`) with the broader BwrapEnhanced SDLC hierarchy. The conversation ended there with no further resolution.

---

### 3. [DIR] Currently Open Files
You have these files open right now:
- `SdlcEngineSpec.system-0.0.1.md` -- the system-level spec for the SDLC engine
- `BashTestSupportingLibs.feat-0.0.1.md` -- one of the newly created FEAT nodes from the completed tree

---

## Summary: What Needs Attention

| Item | State | Next Step |
|---|---|---|
| GenericSdlcEngine.strat tree | [DONE] Committed | Done |
| 60 uncommitted portability fixes | [WIP] In working tree | Review, decide: commit or reset |
| SecurityIsolationMatrix spec | [BLOCKED] Not started | Answer Q2, then create |
| AutofsShadow -> HostPathConfinement | [BLOCKED] Not started | Answer Q1, then rewrite |
| Open questions Q1-Q3 | [BLOCKED] Unanswered | Need your decisions |

---

## Outstanding Questions (Unanswered -- Blocking)

> **Q1 -- AutofsShadow: live or dead?**
> The `AutofsShadow.spec` says `--tmpfs /homes` is in the code, but code comments say it was *removed*. Need to audit `bwrap-enhanced.sh` lines 263-270 to determine if this spec describes live or dead behaviour. If dead -> delete or archive? If live -> rewrite as `HostPathConfinement.spec` (generic, no autofs/NFS knowledge).

> **Q2 -- SecurityIsolationMatrix hierarchy level?**
> Should `SecurityIsolationMatrix` be a `.spec` under `GuiPassthrough.feat` (narrower scope) or a `.feat` under `NamespaceIsolatedSandbox.moti` (cross-cutting, peers with `VfsIsolation`, `NetworkIsolation`, etc.)? Previous agent recommended `.feat` level since security tiers are cross-cutting, not just a GUI concern.

> **Q3 -- Walk-up sentinel for portable path discovery?**
> The portable header uses `while [[ ! -d "PROJECT_HOME" ]]` to find the repo root. Should the sentinel be:
> - `PROJECT_HOME/` directory (current -- descriptive, project-specific)
> - `.git` directory (standard, but breaks in worktrees/submodules)
> - `VERSION` file at root (unique to this project)

> **Q4 -- 60 uncommitted files: commit or reset?**
> The portability sweep (A1-A3, A6) appears to have been applied to the working tree before the plan was formally approved. These changes look correct (replacing hardcoded NFS paths with portable `BASH_SOURCE`-relative headers) but were never reviewed or committed. Decision needed: review and commit as-is, or reset and redo cleanly?

> **Q5 -- Untracked files: keep or discard?**
> Two new untracked items appeared during conversation `50873b18`:
> - `MotivatorDriver-terms.analy.md` -- ontology analysis document
> - `brainstorming-ideas-only/` -- brainstorming directory
>
> Were these intentional? Should they be committed, moved, or deleted?

> **Q6 -- DriverVsMotivator scope confusion**
> The previous agent conflated `generic-sdlc-and-engine-readonly/DriverVsMotivator-analysis.analys.md` (scoped ONLY to the generic SDLC engine) with the broader `BwrapEnhanced2026.strat` hierarchy. That confusion was flagged but never resolved. Any cleanup needed in the analysis doc from that session's edits?
