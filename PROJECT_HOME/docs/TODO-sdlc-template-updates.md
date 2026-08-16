<!-- (c) 2026 Hanaden - Frederick Bloom -- TODO-sdlc-template-updates.md -->
---
title: "TODO: SDLC Template Updates for TDD-Driven Hierarchy"
status: pending
created: 2026-08-16T14:15:00-04:00
conversation: 99799dc8-b3ac-4ccf-b994-e6ebe8feb21d
priority: HIGH
---

# TODO: SDLC Template Updates for TDD-Driven Hierarchy

> [!IMPORTANT]
> These design decisions were made during the bwrap-enhanced reverse-engineering session
> (conversation `99799dc8`). Templates MUST be updated to reflect this approach BEFORE
> writing the actual SDLC docs for bwrap-enhanced.

---

## Design Decisions (Locked)

### 1. Directory Structure — Hierarchical, Mirrors Parent-Child Graph

The filesystem path IS the traceability chain. `cd ..` walks up one parent pointer.
Every `parent:` YAML field resolves to the document one directory up.

```
architecture-design-features-specs/
└── Slug.class/              ← L0
    └── Slug.class/          ← L1
        └── Slug.class/      ← L1
            ├── Slug.class/  ← L2 Feature
            │   └── Slug.class/  ← L4 Spec
            └── Slug.class/  ← L3 Architecture
```

### 2. Directory Naming — `Slug.class/` (No UUIDv7)

- Directories are structural containers, not versioned artifacts
- UUIDv7 naming belongs exclusively on files
- The `.class` suffix (`*.feat/`, `*.spec/`, `*.arch/`, `*.strat/`, `*.driv/`, `*.moti/`) self-documents the node type
- Tab-completion friendly: `cd VfsI<tab>` works

**Valid class suffixes for directories:**
- `.strat/` — Layer 0 Strategy
- `.driv/`  — Layer 1 Driver
- `.moti/`  — Layer 1 Motivator
- `.feat/`  — Layer 2 Feature
- `.arch/`  — Layer 3 Architecture (cross-cutting, sibling of features)
- `.spec/`  — Layer 3-4 Specification

### 3. File Naming — Drop Redundant Class Prefix from Slug

Since `.feat-0.0.1.md` carries the class, the slug drops the class prefix:

| Old (redundant) | New (clean) |
|:----------------|:------------|
| `FeatVfsIsolation.feat-0.0.1.md` | `VfsIsolation.feat-0.0.1.md` |
| `TDrivUncontainedAgentExecution.driv-0.0.1.md` | `UncontainedAgentExecution.driv-0.0.1.md` |
| `SpecFuncReadOnlyRoot.spec-0.0.1.md` | `ReadOnlyRoot.spec-0.0.1.md` |
| `CorpStratBwrapEnhanced2026.strat-0.0.1.md` | `BwrapEnhanced2026.strat-0.0.1.md` |

### 4. Specs as Directory-Level Nodes

Every node is a directory. No exceptions. Even leaf specs.
This enables test co-location and consistent tree structure.

### 5. ARCH Placement — Sibling of Features Under Motivator

The Architecture doc describes the entire `exec_sandbox()` function across ALL features.
It is NOT subordinate to a single feature. It sits as a peer of features under TMoti.

### 6. Test Tree — `src/test/` Mirrors Doc Hierarchy

```
docs/architecture-design-features-specs/
└── .../VfsIsolation.feat/ReadOnlyRoot.spec/
    └── ReadOnlyRoot.spec-0.0.1.md              ← WHAT to test

src/test/hanaden-bwrap-enhanced/
└── .../VfsIsolation.feat/ReadOnlyRoot.spec/
    └── test_readonly_root.sh                    ← HOW to test
```

One test suite per doc. Suites compose: parent suite runs child suites first
(depth-first), then runs its own assertions. Results bubble up.

### 7. Ordering — Always Semantic Reinterpretation (NO Metadata)

**NO `children-order:` in parent frontmatter.**
**NO `depends-on:` in child frontmatter.**
**NO `order:` integer on children.**

The AI agent semantically reads the full content of all sibling documents each time,
infers the dependency DAG from engineering content, and computes topological sort.

Rationale:
- `depends-on` is hardcoded/static — can drift from content
- Document content IS the dependency declaration
- Forces documentation quality — if AI can't infer order, docs are ambiguous
- Dynamic — as features evolve, inferred dependencies update automatically
- Aligns with AI agent's core capability (semantic reasoning)

### 8. Ties — FATAL

Non-determinism in ordering is a logic FATAL that must be flagged and resolved
by improving document content — NOT by tiebreak rules, NOT by alphabetical
fallback, NOT by sweeping it under a rug. Ambiguity is a document quality defect.

### 9. TDD Cycle — Docs Are Executable Specifications

Each SDLC doc simultaneously defines:
1. **The requirement** (what to build)
2. **The test definition** (what to verify)
3. **The ordering basis** (semantic content for AI inference)

AI TDD workflow per node (depth-first, bottom-up):
```
depth_first_tdd(node):
    for child in ai_inferred_order(node.children):
        depth_first_tdd(child)                    # leaves first
    read(node.doc)                                 # understand WHAT
    write(node.test)                               # RED
    write_or_modify(src/main/bwrap-enhanced.sh)    # minimal impl
    run(node.test)                                 # GREEN?
    if GREEN: refactor_if_needed()
    update(node.doc.tdd_status = GREEN)
```

---

## Template Updates Required

### [ ] 1. ALL TEMPLATES — Add `tdd:` Block to Frontmatter Schema

```yaml
tdd:
  state: NOT_STARTED     # NOT_STARTED | RED | GREEN | REFACTOR
  test-file: null         # relative path to test script in src/test/
  last-run: null          # ISO 8601 timestamp of last test execution
  iterations: 0           # RED→GREEN cycle count
  coverage-lines: null    # source lines in bwrap-enhanced-wip.sh this node covers
```

Affects: GoalStrategyTmpl, DriverMotivationTmpl, FeatureTmpl,
         ArchitectureTmpl, SpecificationTmpl

### [ ] 2. ALL TEMPLATES — Add `TDD` Column to Test Suite Tables

Current:
```markdown
| ID | Description | Method | Pass Criteria |
```

Updated:
```markdown
| ID | Description | Method | Pass Criteria | TDD |
|....|.............|........|...............|-----|
| ROR-001 | Write to /etc fails | touch /etc/test | EROFS | RED |
```

Affects: All 5 templates (all have `## Test Suite` sections)

### [ ] 3. ALL TEMPLATES — Add `test-file:` to Test Suite Header

```markdown
## Test Suite

> **Suite ID:** [filename-id]-SUITE
> **Suite name:** [Human-readable name]
> **Test file:** `src/test/.../Slug.class/test_slug.sh`
> **Integration test boundary:** ...
> **Unit test boundary:** ...
```

### [ ] 4. ALL TEMPLATES — Document Hierarchical Directory Convention

Add a section or note explaining:
- Directory naming: `Slug.class/`
- File slug drops class prefix
- Parent resolves to `../`
- Filesystem path = parent chain

### [ ] 5. ALL TEMPLATES — Remove Any `children:` or `children-order:` References

Ensure NO template suggests adding ordering metadata.
The ordering approach is semantic inference — document this explicitly.

### [ ] 6. SdlcHierarchyOverview Template — Major Update

- Document the `Slug.class/` directory convention
- Document the semantic inference ordering approach
- Document the test tree mirroring convention
- Document the TDD cycle
- Add example of the full tree structure

### [ ] 7. SpecificationTmpl — Verify `status:` Does Not Conflict with `tdd.state:`

Current `status: Draft | Review | Accepted | Implemented | Superseded` is document lifecycle.
New `tdd.state: NOT_STARTED | RED | GREEN | REFACTOR` is test lifecycle.
These are independent axes — document this distinction clearly.

### [ ] 8. DriverMotivationTmpl — Verify Body Templates Work with New Naming

The template examples use `B-DRIV-100`, `T-DRIV-200` style IDs.
These should be updated to use the `Slug.class` naming convention.

---

## Templates NOT Needing Updates

| Template | Reason |
|:---------|:-------|
| LessonsLearnedUniversalTmpl | Not part of the SDLC hierarchy |
| DecisionRecordTmpl | Not part of the hierarchy (standalone records) |
| ExampleProjectHierarchyTree | Needs update — see item 6 above |

---

## Conversation Artifacts (Reference)

| Artifact | Location |
|:---------|:---------|
| Full re-analysis | `~/.gemini/.../brain/99799dc8.../bwrap_sdlc_reanalysis.md` |
| TDD gap analysis | `~/.gemini/.../brain/99799dc8.../sdlc_tdd_gap_analysis.md` |
| This TODO | `PROJECT_HOME/docs/TODO-sdlc-template-updates.md` |

---

## Changelog

| Date | Author | Changes |
|:-----|:-------|:--------|
| 2026-08-16 | Frederick Bloom + AI | Initial — captured all design decisions from reverse-engineering session |
