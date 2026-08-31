<!-- (c) 2026-* Frederick Bloom -- Bwrap-Enhanced Kanban Instantiation -- Hanaden AI -->

# Bwrap-Enhanced Kanban Instantiation

> **Status:** DRAFT — Design Only
> **Project:** `hanaden-bwrap-enhanced`
> **Source:** `PROJECT_HOME/docs/20260826-TODO-kanban.md`
> **Target:** `PROJECT_HOME/docs/workstream-kanban/`
> **Filename:** `20260827-032356-af5cec-af5c-ec44-9d64407d8eb0-BwrapEnhancedKanbanInstantiation.kanban-0.0.1.md`
> **Engine:** `PROJECT_HOME/generic-sdlc-and-engine-readonly/20260827-032351-153784-198a-2703-3f584ebf95d7-GenericWorkstreamKanbanEngine.kanban-0.0.1.md`
> **Processing Model:** Daemon-style backlog pull

---

## 1. Overview

This document defines how the hanaden-bwrap-enhanced project **instantiates**
the Generic Workstream Kanban Engine. Every item from the existing
`20260826-TODO-kanban.md` starts in the **strategic backlog**. The directory
tree is empty (`.gitkeep` only) until items are pulled and processed — like
a daemon processing a work queue.

```mermaid
flowchart LR
    subgraph SOURCE["20260826-TODO-kanban.md<br/>(All Items)"]
        direction TB
        BP0["Backlog P0: 3 items"]
        BP1["Backlog P1-P2: 4 items"]
        PLAN["Planned: 5 items"]
        INPR["In Progress: 1 item"]
        DONE["Done: 4 releases"]
        KI["Known Issues: 6 items"]
    end

    subgraph TARGET["workstream-kanban/ (Initial State)"]
        direction TB
        PB_SB["portfolio-board/strategic-backlog/<br/>◄ ALL active items land HERE first"]
        PB_DL["portfolio-board/delivered/<br/>◄ Done items land here"]
        TK["tracking/bugs/triage/<br/>◄ Known Issues land here"]
        WS["execution-board/workstreams/<br/>◄ EMPTY (.gitkeep only)<br/>Daemon pulls from backlog"]
    end

    BP0 -->|"→ backlog"| PB_SB
    BP1 -->|"→ backlog"| PB_SB
    PLAN -->|"→ backlog"| PB_SB
    INPR -->|"→ backlog"| PB_SB
    DONE -->|"→ delivered"| PB_DL
    KI -->|"→ triage"| TK

    classDef src fill:#78350f,stroke:#f59e0b,color:#fefce8
    classDef tgt fill:#1e3a5f,stroke:#3b82f6,color:#eff6ff
    class BP0,BP1,PLAN,INPR,DONE,KI src
    class PB_SB,PB_DL,TK,WS tgt
    style SOURCE fill:#1a0f00,stroke:#f59e0b,color:#fde68a
    style TARGET fill:#001033,stroke:#3b82f6,color:#93c5fd
```

---

## 2. Daemon-Style Backlog Processing

The backlog is processed like a daemon's work queue — items are **pulled**,
not pushed. The AI orchestrator (or future Rust engine) acts as the daemon:

```mermaid
sequenceDiagram
    participant BL as strategic-backlog/ (Queue)
    participant ORCH as Orchestrator (Daemon)
    participant WS as workstreams/ (Workers)
    participant IB as integration-buffer/

    loop Daemon cycle
        ORCH->>BL: ls *.kanban-*.md (scan queue)
        ORCH->>ORCH: Sort by priority (P0 first)
        ORCH->>ORCH: Check WIP capacity per workstream

        alt Workstream has capacity
            ORCH->>BL: Read top-priority item
            ORCH->>ORCH: Decompose → child cards
            ORCH->>BL: mv item → in-flight/
            ORCH->>WS: Write child cards to ws/ready/
            ORCH->>WS: Dispatch agents
        else All workstreams at WIP limit
            ORCH->>ORCH: Wait (backpressure)
        end

        WS->>WS: Agent pulls ready/ → in-progress/
        WS->>WS: Work → review/ → done/
        WS->>IB: Submit done card to queue/
    end
```

**Key principle:** The dirtree starts empty. Workstream directories contain
only `.gitkeep` until the daemon pulls items from the backlog and routes them.
This is a **pull system**, not push.

---

## 3. Workstream Definitions

Workstream directories are **created empty** and populated only when the
daemon routes cards to them. Derived from TODO kanban phase groupings:

| Workstream Slug | Owner | Type | WIP Limit | Source Phase |
|-----------------|-------|------|-----------|-------------|
| `governance-cleanup` | Human/Agent | mixed | 3 | Phase 1 + Phase 2 (partial) |
| `test-engineering` | Human/Agent | mixed | 2 | Phase 2 (partial) + Phase 3 |
| `process-guardrails` | Human | human | 1 | Phase 4 |
| `portability` | Human/Agent | mixed | 2 | Parallel Track |

**Future workstreams** (created when initiatives move to in-flight):

| Workstream Slug | Source |
|-----------------|--------|
| `architecture` | Phase 5 (ARCH-PLANES, ARCH-VROOT) |
| `cli-redesign` | Phase 6 (CLI-REDESIGN, CLI-TIERS, PROVISION-SCHEMA) |

### Instantiated `wip-config.yaml`

```yaml
---
version: 1
project: hanaden-bwrap-enhanced
default-wip-limit: 3

workstreams:
  governance-cleanup:
    wip-limit: 3
    owner: "Frederick Bloom"
    type: mixed
  test-engineering:
    wip-limit: 2
    owner: "Frederick Bloom"
    type: mixed
  process-guardrails:
    wip-limit: 1
    owner: "Frederick Bloom"
    type: human
  portability:
    wip-limit: 2
    owner: "Frederick Bloom"
    type: mixed

integration-buffer:
  wip-limit: 1
  verification-timeout-hours: 4
---
```

---

## 4. Phase-to-Workstream Routing

The existing TODO kanban has 6 sequential phases + 1 parallel track. The
daemon will route backlog items to workstreams based on this mapping:

```mermaid
flowchart TD
    subgraph PHASES["Original Phase Model (Sequential)"]
        P1["Phase 1: Foundation Cleanup<br/>TMPL-FIX → SPEC-CLEAN"]
        P2["Phase 2: Governance Hardening<br/>SPEC-DBUS, HARNESS, PRE-COMMIT"]
        P3["Phase 3: Test Implementation<br/>TEST-IMPL"]
        P4["Phase 4: Process Guardrails<br/>AUDIT-BRANCH"]
        PT["Parallel Track<br/>PORTABILITY"]
        P5["Phase 5: Architecture<br/>ARCH-PLANES → ARCH-VROOT"]
        P6["Phase 6: CLI Redesign<br/>CLI-REDESIGN → CLI-TIERS, SCHEMA"]

        P1 --> P2 --> P3 --> P5
        P2 --> P4
        PT --> P5
        P5 --> P6
    end

    subgraph WORKSTREAMS["Workstream Model (Parallel)"]
        WS_GC["governance-cleanup/<br/>TMPL-FIX, SPEC-CLEAN,<br/>SPEC-DBUS"]
        WS_TE["test-engineering/<br/>HARNESS, TEST-IMPL,<br/>PRE-COMMIT"]
        WS_PG["process-guardrails/<br/>AUDIT-BRANCH"]
        WS_PT["portability/<br/>PORTABILITY"]
        WS_AR["architecture/ (future)<br/>ARCH-PLANES, ARCH-VROOT"]
        WS_CL["cli-redesign/ (future)<br/>CLI-REDESIGN, CLI-TIERS,<br/>PROVISION-SCHEMA"]
    end

    P1 -->|"route"| WS_GC
    P2 -->|"SPEC-DBUS"| WS_GC
    P2 -->|"HARNESS, PRE-COMMIT"| WS_TE
    P3 -->|"route"| WS_TE
    P4 -->|"route"| WS_PG
    PT -->|"route"| WS_PT
    P5 -->|"route"| WS_AR
    P6 -->|"route"| WS_CL

    classDef phase fill:#2c3e50,stroke:#566573,color:#ecf0f1
    classDef ws fill:#8e44ad,stroke:#6c3483,color:#fff
    classDef future fill:#3b0764,stroke:#a855f7,color:#faf5ff,stroke-dasharray:5 5

    class P1,P2,P3,P4,PT,P5,P6 phase
    class WS_GC,WS_TE,WS_PG,WS_PT ws
    class WS_AR,WS_CL future

    style PHASES fill:#1a1a1a,stroke:#566573,color:#aabbcc
    style WORKSTREAMS fill:#1a0a2a,stroke:#8e44ad,color:#d8b4fe
```

---

## 5. Item-by-Item Migration — All to Backlog

**Everything starts in `portfolio-board/strategic-backlog/`.**
The daemon will decompose, prioritize, and route.

### 5.1 Backlog P0 (Critical) → Strategic Backlog

| Item | Card File | Initial Location | SDLC Ref | Priority |
|------|-----------|------------------|----------|----------|
| **TMPL-FIX** | `TemplateCleanup.card.kanban-0.0.1.md` | `strategic-backlog/` | `SpecificationTmpl` template | P0 |
| **SPEC-CLEAN** | `SpecCleanup.card.kanban-0.0.1.md` | `strategic-backlog/` | 55 specs under `BwrapEnhanced2026.strat/` | P0 |
| **SPEC-DBUS** | `DbusSpecCreation.card.kanban-0.0.1.md` | `strategic-backlog/` | `UncontainedAgentExecution.driv` D-Bus path | P0 |

### 5.2 Backlog P1–P2 → Strategic Backlog

| Item | Card File | Initial Location | SDLC Ref | Priority |
|------|-----------|------------------|----------|----------|
| **HARNESS** | `TestHarnessDesign.card.kanban-0.0.1.md` | `strategic-backlog/` | `GenericSdlcEngine.strat` test output | P1 |
| **TEST-IMPL** | `TestImplementation.card.kanban-0.0.1.md` | `strategic-backlog/` | 260 NOT_STARTED cases, 45 specs | P1 |
| **PRE-COMMIT** | `PreCommitHook.card.kanban-0.0.1.md` | `strategic-backlog/` | Governance audit §11 | P1 |
| **AUDIT-BRANCH** | `BranchAudit.card.kanban-0.0.1.md` | `strategic-backlog/` | CONTRIBUTING.md / AGENTS.md | P2 |

### 5.3 In Progress → Strategic Backlog (re-queued)

| Item | Card File | Initial Location | SDLC Ref | Priority |
|------|-----------|------------------|----------|----------|
| **PORTABILITY** | `PortabilitySweep.card.kanban-0.0.1.md` | `strategic-backlog/` | `HostCoupledDevelopment.driv` (3 specs) | P1 |

> [!NOTE]
> Even though PORTABILITY was "In Progress" in the flat file, it starts in
> the backlog here. The daemon will re-pull it based on priority. The card's
> frontmatter will note `previously-in-progress: true` to preserve history.

### 5.4 Planned (Brainstorm) → Strategic Backlog

| Item | Card File | Initial Location | SDLC Ref |
|------|-----------|------------------|----------|
| **ARCH-PLANES** | `TwoPlaneArchitecture.init.kanban-0.0.1.md` | `strategic-backlog/` | New `.arch` node |
| **ARCH-VROOT** | `VirtualRootOverlay.init.kanban-0.0.1.md` | `strategic-backlog/` | New `.arch` node |
| **CLI-REDESIGN** | `CliModuleRedesign.init.kanban-0.0.1.md` | `strategic-backlog/` | New `.feat` node |
| **CLI-TIERS** | `SecurityTierModel.init.kanban-0.0.1.md` | `strategic-backlog/` | New `.feat` node |
| **PROVISION-SCHEMA** | `ProvisionJsonSchema.init.kanban-0.0.1.md` | `strategic-backlog/` | New `.spec` node |

### 5.5 Done → Portfolio Delivered

| Version | File | Location |
|---------|------|----------|
| **v0.2.2** | `Release-v0.2.2.init.kanban-0.0.1.md` | `portfolio-board/delivered/` |
| **v0.2.1** | `Release-v0.2.1.init.kanban-0.0.1.md` | `portfolio-board/delivered/` |
| **v0.2.0** | `Release-v0.2.0.init.kanban-0.0.1.md` | `portfolio-board/delivered/` |
| **v0.1.0** | `Release-v0.1.0.init.kanban-0.0.1.md` | `portfolio-board/delivered/` |

### 5.6 Known Issues → Tracking Bugs (triage)

| KI ID | Bug File | Location | Affected Spec | Severity |
|-------|----------|----------|---------------|----------|
| **KI-001** | `X11AuthorityBug.bug.kanban-0.0.1.md` | `tracking/bugs/triage/` | `X11Socket.spec` | Medium |
| **KI-002** | `SandboxExecNoTest.bug.kanban-0.0.1.md` | `tracking/bugs/triage/` | `SandboxExecEngine.arch` | Low |
| **KI-003** | `BwrapPreflightNoIntTest.bug.kanban-0.0.1.md` | `tracking/bugs/triage/` | `BwrapPreflight.feat` | Low |
| **KI-004** | `FabricatedTimestamp49Specs.bug.kanban-0.0.1.md` | `tracking/bugs/triage/` | 49 specs (audit §2.4) | P0 |
| **KI-005** | `AutofsNfsPathViolations.bug.kanban-0.0.1.md` | `tracking/bugs/triage/` | `NoHostTopologyInSpecs.spec` | Medium |
| **KI-006** | `UnresolvedSecurityBulletins.bug.kanban-0.0.1.md` | `tracking/bugs/triage/` | `security-bulletins/` | Review |

> [!NOTE]
> ALL Known Issues start in `triage/` — even KI-004 which was previously
> marked P0/confirmed. The daemon processes triage → confirmed → assigned.

---

## 6. Cross-Workstream Dependency Graph

These `blocked-by:` frontmatter edges are encoded in the card files sitting
in the backlog. The daemon uses them to determine routing order:

```mermaid
flowchart TD
    subgraph WS_GC["→ governance-cleanup/"]
        TMPL["TMPL-FIX<br/>P0 · backlog"]
        CLEAN["SPEC-CLEAN<br/>P0 · backlog<br/>blocked-by: TMPL-FIX"]
        DBUS["SPEC-DBUS<br/>P0 · backlog<br/>blocked-by: TMPL-FIX"]
    end

    subgraph WS_TE["→ test-engineering/"]
        HARNESS["HARNESS<br/>P1 · backlog<br/>blocked-by: SPEC-CLEAN"]
        PRECOMMIT["PRE-COMMIT<br/>P1 · backlog<br/>blocked-by: SPEC-CLEAN"]
        TESTIMPL["TEST-IMPL<br/>P1 · backlog<br/>blocked-by: SPEC-DBUS, HARNESS"]
    end

    subgraph WS_PG["→ process-guardrails/"]
        AUDIT["AUDIT-BRANCH<br/>P2 · backlog<br/>blocked-by: PRE-COMMIT"]
    end

    subgraph WS_PT["→ portability/"]
        PORT["PORTABILITY<br/>P1 · backlog"]
    end

    subgraph WS_ARCH["→ architecture/ (future)"]
        PLANES["ARCH-PLANES<br/>backlog<br/>blocked-by: TEST-IMPL, PORTABILITY"]
        VROOT["ARCH-VROOT<br/>backlog<br/>blocked-by: ARCH-PLANES"]
    end

    subgraph WS_CLI["→ cli-redesign/ (future)"]
        CLIREDESIGN["CLI-REDESIGN<br/>backlog<br/>blocked-by: ARCH-VROOT, ARCH-PLANES"]
        CLITIERS["CLI-TIERS<br/>backlog<br/>blocked-by: CLI-REDESIGN"]
        SCHEMA["PROVISION-SCHEMA<br/>backlog<br/>blocked-by: CLI-REDESIGN"]
    end

    TMPL -->|"template fixed"| CLEAN
    TMPL -->|"enables new specs"| DBUS
    CLEAN -->|"cross-ws"| HARNESS
    CLEAN -->|"cross-ws"| PRECOMMIT
    DBUS -->|"cross-ws"| TESTIMPL
    HARNESS -->|"cross-ws"| TESTIMPL
    PRECOMMIT -->|"cross-ws"| AUDIT
    TESTIMPL -->|"cross-ws"| PLANES
    PORT -->|"cross-ws"| PLANES
    PLANES --> VROOT
    VROOT --> CLIREDESIGN
    PLANES --> CLIREDESIGN
    CLIREDESIGN --> CLITIERS
    CLIREDESIGN --> SCHEMA

    classDef p0 fill:#7f1d1d,stroke:#dc2626,color:#fef2f2
    classDef p1 fill:#78350f,stroke:#f59e0b,color:#fefce8
    classDef p2 fill:#14532d,stroke:#22c55e,color:#f0fdf4
    classDef active fill:#1e3a5f,stroke:#3b82f6,color:#eff6ff,stroke-width:3px
    classDef future fill:#3b0764,stroke:#a855f7,color:#faf5ff,stroke-dasharray:5 5

    class TMPL,CLEAN,DBUS p0
    class HARNESS,TESTIMPL,PRECOMMIT p1
    class AUDIT p2
    class PORT active
    class PLANES,VROOT,CLIREDESIGN,CLITIERS,SCHEMA future

    style WS_GC fill:#1a0000,stroke:#dc2626,color:#fca5a5
    style WS_TE fill:#1a0f00,stroke:#f59e0b,color:#fde68a
    style WS_PG fill:#001a1a,stroke:#14b8a6,color:#99f6e4
    style WS_PT fill:#001033,stroke:#3b82f6,color:#93c5fd,stroke-width:3px
    style WS_ARCH fill:#0f001a,stroke:#a855f7,color:#d8b4fe,stroke-dasharray:5 5
    style WS_CLI fill:#0f001a,stroke:#a855f7,color:#d8b4fe,stroke-dasharray:5 5
```

### Critical Path

```
TMPL-FIX → SPEC-CLEAN → HARNESS → TEST-IMPL → ARCH-PLANES → ARCH-VROOT → CLI-REDESIGN → CLI-TIERS / PROVISION-SCHEMA
```

---

## 7. Gap Analysis — Project-Specific

What the **existing** `20260826-TODO-kanban.md` cannot do that this
instantiation enables:

```mermaid
flowchart TD
    subgraph TODAY["Current State"]
        F1["Flat markdown file"]
        F2["No ownership/assignment"]
        F3["Known Issues = static table"]
        F4["Phase dependencies = prose"]
        F5["No WIP enforcement"]
        F6["No agent dispatch tracking"]
        F7["Done items = flat checklist"]
    end

    subgraph AFTER["After Instantiation"]
        A1["Filesystem-native kanban"]
        A2["Cards in workstream swimlanes"]
        A3["Bugs with full lifecycle"]
        A4["blocked-by: frontmatter FKs"]
        A5["wip-config.yaml + hooks"]
        A6["subagent-dispatch/ per ws"]
        A7["Delivered = versioned initiatives"]
    end

    F1 -->|"replaces"| A1
    F2 -->|"replaces"| A2
    F3 -->|"replaces"| A3
    F4 -->|"replaces"| A4
    F5 -->|"replaces"| A5
    F6 -->|"replaces"| A6
    F7 -->|"replaces"| A7

    classDef today fill:#7f1d1d,stroke:#dc2626,color:#fef2f2
    classDef after fill:#14532d,stroke:#22c55e,color:#f0fdf4
    class F1,F2,F3,F4,F5,F6,F7 today
    class A1,A2,A3,A4,A5,A6,A7 after
    style TODAY fill:#1a0000,stroke:#dc2626,color:#fca5a5
    style AFTER fill:#0a1a00,stroke:#22c55e,color:#bbf7d0
```

---

## 8. Instantiated Directory Tree — Initial State

**Everything in backlog. Workstream dirs are EMPTY (`.gitkeep` only).**
The daemon populates workstreams as it pulls items from the backlog.
Relative to `PROJECT_HOME/docs/workstream-kanban/`:

```
workstream-kanban/
├── README.md
├── CONVENTIONS.md
│
├── portfolio-board/
│   ├── README.md
│   ├── strategic-backlog/                 ◄── ALL ACTIVE ITEMS START HERE
│   │   ├── TemplateCleanup.card.kanban-0.0.1.md         (P0, TMPL-FIX)
│   │   ├── SpecCleanup.card.kanban-0.0.1.md             (P0, SPEC-CLEAN)
│   │   ├── DbusSpecCreation.card.kanban-0.0.1.md        (P0, SPEC-DBUS)
│   │   ├── TestHarnessDesign.card.kanban-0.0.1.md       (P1, HARNESS)
│   │   ├── TestImplementation.card.kanban-0.0.1.md      (P1, TEST-IMPL)
│   │   ├── PreCommitHook.card.kanban-0.0.1.md           (P1, PRE-COMMIT)
│   │   ├── BranchAudit.card.kanban-0.0.1.md             (P2, AUDIT-BRANCH)
│   │   ├── PortabilitySweep.card.kanban-0.0.1.md        (P1, PORTABILITY)
│   │   ├── TwoPlaneArchitecture.init.kanban-0.0.1.md    (brainstorm)
│   │   ├── VirtualRootOverlay.init.kanban-0.0.1.md      (brainstorm)
│   │   ├── CliModuleRedesign.init.kanban-0.0.1.md       (brainstorm)
│   │   ├── SecurityTierModel.init.kanban-0.0.1.md       (brainstorm)
│   │   └── ProvisionJsonSchema.init.kanban-0.0.1.md     (brainstorm)
│   ├── in-flight/
│   │   └── .gitkeep                      ◄── EMPTY (daemon populates)
│   ├── delivered/
│   │   ├── Release-v0.2.2.init.kanban-0.0.1.md
│   │   ├── Release-v0.2.1.init.kanban-0.0.1.md
│   │   ├── Release-v0.2.0.init.kanban-0.0.1.md
│   │   └── Release-v0.1.0.init.kanban-0.0.1.md
│   └── archive/
│       └── .gitkeep                      ◄── EMPTY
│
├── execution-board/
│   ├── README.md
│   ├── wip-config.yaml
│   ├── workstreams/
│   │   ├── README.md
│   │   ├── _template-workstream/
│   │   │   └── (see Engine doc)
│   │   │
│   │   ├── governance-cleanup/            ◄── EMPTY (daemon populates)
│   │   │   ├── README.md
│   │   │   ├── ready/
│   │   │   │   └── .gitkeep
│   │   │   ├── in-progress/
│   │   │   │   └── .gitkeep
│   │   │   ├── blocked/
│   │   │   │   └── .gitkeep
│   │   │   ├── review/
│   │   │   │   └── .gitkeep
│   │   │   ├── done/
│   │   │   │   └── .gitkeep
│   │   │   ├── subagent-dispatch/
│   │   │   │   ├── pending/ + active/ + completed/ + failed/
│   │   │   │   └── README.md
│   │   │   ├── worktree-branches/
│   │   │   │   ├── active-branches/ + merged-branches/
│   │   │   │   └── README.md
│   │   │   └── artifacts/
│   │   │       └── scratch/ + deliverables/
│   │   │
│   │   ├── test-engineering/              ◄── EMPTY (daemon populates)
│   │   │   └── (same structure as governance-cleanup, all .gitkeep)
│   │   │
│   │   ├── process-guardrails/            ◄── EMPTY (daemon populates)
│   │   │   └── (same structure, all .gitkeep)
│   │   │
│   │   └── portability/                   ◄── EMPTY (daemon populates)
│   │       └── (same structure, all .gitkeep)
│   │
│   └── integration-buffer/
│       ├── queue/ + active-merge/ + verification/ + integrated/
│       └── README.md
│
│
├── release-pipeline/
│   ├── staging/ + canary/ + production/ + rollback-log/
│   └── README.md                         ◄── ALL EMPTY
│
├── sdlc-specs/
│   ├── spec-requests/ + spec-reviews/ + spec-approvals/ + spec-change-proposals/
│   └── README.md                         ◄── ALL EMPTY
│
├── tracking/
│   ├── bugs/
│   │   ├── triage/                        ◄── ALL KIs START HERE
│   │   │   ├── SandboxExecNoTest.bug.kanban-0.0.1.md           (KI-002)
│   │   │   ├── BwrapPreflightNoIntTest.bug.kanban-0.0.1.md     (KI-003)
│   │   │   ├── FabricatedTimestamp49Specs.bug.kanban-0.0.1.md   (KI-004)
│   │   │   ├── AutofsNfsPathViolations.bug.kanban-0.0.1.md     (KI-005)
│   │   │   └── UnresolvedSecurityBulletins.bug.kanban-0.0.1.md (KI-006)
│   │   ├── confirmed/ + assigned/ + in-progress/ + fixed/ + wont-fix/
│   │   └── README.md                     ◄── All other columns EMPTY
│   ├── enhancements/ + incidents/ + rfcs/
│   └── README.md                         ◄── ALL EMPTY
│
├── ceremonies/ + metrics/ + governance/   ◄── ALL EMPTY (.gitkeep)
│
├── agent-orchestration/
│   ├── SPAWN-POLICY.md
│   ├── agent-registry/ + dispatch-log/ + escalation-log/ + conversation-index/
│   └── README.md                         ◄── ALL EMPTY
│
└── templates/
    ├── README.md
    └── (12 template files — see Engine doc)
```

---

## 9. Enhancements This Enables for Bwrap-Enhanced

| # | Enhancement | Concrete Impact |
|---|-------------|------------------|
| 1 | **KI lifecycle** | KI-001–KI-006 gain `triage/ → confirmed/ → assigned/ → fixed/` flow instead of static table rows |
| 2 | **Parallel workstreams** | `governance-cleanup` and `test-engineering` and `portability` work concurrently |
| 3 | **Agent dispatch for SPEC-CLEAN** | 55-spec cleanup parallelized across agents (budget-gated by depth) |
| 4 | **Agent dispatch for TEST-IMPL** | 260 NOT_STARTED test cases batched and dispatched across agents |
| 5 | **Integration buffer** | Multiple spec cleanup PRs → serial merge via buffer |
| 6 | **Release tracking** | v0.3.0 tracked through `staging/ → canary/ → production/` |
| 7 | **Cross-workstream deps** | SPEC-CLEAN → HARNESS is now a machine-readable `blocked-by:` FK |
| 8 | **Metrics** | Cycle time per card — how long from `ready/` to `done/` |

---

## 10. Relationship to Existing TODO File — RESOLVED

The existing `20260826-TODO-kanban.md` becomes a **materialized view**:

- The **filesystem** is the source of truth (the database)
- The flat `.md` file is **auto-generated** from filesystem state
- Future Rust engine will produce this view; for now AI can generate it
- The flat file is **read-only** — all mutations go through the filesystem

```mermaid
flowchart LR
    FS["workstream-kanban/<br/>(source of truth)"] -->|"find + grep<br/>→ generate"| VIEW["20260826-TODO-kanban.md<br/>(materialized view, read-only)"]
    VIEW -.->|"NEVER write back"| FS

    classDef src fill:#14532d,stroke:#22c55e,color:#f0fdf4
    classDef view fill:#78350f,stroke:#f59e0b,color:#fefce8
    class FS src
    class VIEW view
```

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| DRAFT | 2026-08-27 | Frederick Bloom + AI | Initial project-specific instantiation — full migration map, 4 workstreams, 6 bugs, dependency graph |
| DRAFT v2 | 2026-08-27 | Frederick Bloom + AI | Everything starts in backlog, empty dirtree, daemon-style processing, `.{type}.kanban` suffix, resolved TODO file question (materialized view), all KIs to triage/ |

