<!-- (c) 2026 Frederick Bloom -->
# Project Constitution — hanaden-ai-booter

* **Effective Date:** 2026-07-01
* **Project Name:** `hanaden-ai-booter`
* **Project Name Short:** `Hanaden.AI.Booter`
* **Copyright:** (c) 2026 — **Frederick Bloom**. All riyou ghts reserved.

---

## Article I — Purpose & Vision

`hanaden-ai-booter` is the **Canonical AI Boot Loader & Governance System** for AI coding assistants and autonomous agents.

### §1. Primary Purpose

The primary purpose of `hanaden-ai-booter` is to provide a standardized, deterministic entry point (`PROJECT_HOME/boot/BOOTSTRAP.md`) for AI agents and coding assistants across all supported IDEs, tools, and execution environments (Gemini, Antigravity, Claude, Cursor, Windsurf, Cline, Amazon Q, GitHub Copilot, Continue, JetBrains Junie).

### §2. Reusable Template

`hanaden-ai-booter` is designed as a **reusable project template**. Any new project MAY clone this repository and inherit the complete AI agent bootstrapping infrastructure, directory conventions, multi-agent redirect architecture, and governance structure without modification to the core engine. The canonical directory layout (Article III) is intentionally generic and project-agnostic.

### §3. Core Capabilities

The system provides:

1. **Deterministic Agent Bootstrapping**: A mandatory boot sequence (`BOOTSTRAP.md`) that executes identically on every session start, restart, or context reload, regardless of agent or IDE.

2. **Self-Monitoring & Turn Gate Architecture**: A mandatory pre-turn gate (`Step 0`) executed prior to every AI response turn. The gate monitors workspace changes through stat-based catalog diffing (`build_catalog()`, `compare_snapshot()`), ensuring real-time tracking of created, modified, and deleted instructional files with O(1) per-file overhead.

3. **AI Executable Directives & Shebang Processing**: Interpretation of markdown-embedded AI executable directives (`<!-- #!ai-exec -->`), auto-classification of content into execution flow types (`UML-ACTIVITY-DIAGRAM`, `RAW-DATA`, `UML-MSC`, `UML-SEQUENCE-DIAGRAM`, `TREE`, `GRAPH`, `GRAPH-WITH-STATE`, `SCRIPT`), and validation of advisory parameters against auto-detected flows.

4. **Universal Agent Redirect Architecture**: A uniform set of agent/IDE configuration files that all redirect to the single `PROJECT_HOME/boot/BOOTSTRAP.md` entry point, ensuring consistent behavior across 11 supported agents.

### §4. Intellectual Property

This project is the research and development creation of Frederick Bloom and the sole intellectual property of Frederick Bloom.

---

## Article II — Core Invariants

The following invariants are non-negotiable. RFC 2119 keywords (MUST, SHOULD, MAY) apply throughout.

### §1. Mandatory Turn Gate

- The AI agent MUST execute `Step 0` (`turn_monitor`) prior to generating any output turn.
- Catalog state comparison MUST use stat-based O(1) file checks (`mtime` and `size`).
- If `PROJECT_HOME/boot/BOOTSTRAP.md` is detected in `modified` or `created` diff sets, the agent MUST immediately invoke `reboot_fresh()` and re-run the full boot sequence.

### §2. Deterministic Boot Sequence & Re-entry

- Boot sequences MUST prioritize `PROJECT_HOME/CONSTITUTION.md` and `PROJECT_HOME/README.md` (seeds) before initiating BFS tree walks across `PROJECT_HOME/` and `docs/`.
- Tree scans MUST respect `WALK_DEPTH = 6` and filter exclusively for `*.md` files (`.fsm.md` double-extension for state machine files).
- Context lost or session restart MUST yield identical execution ordering and behavior (stateless re-entry).

### §3. Shebang & Flow Classification

- AI executable directives (`<!-- #!ai-exec [params] -->` or `<!-- #!/usr/bin/env ai-exec [params] -->`) MUST appear on file line 1 to be recognized.
- Content analysis (`determine_flow_type()`) MUST execute unconditionally for all flagged files.
- When an explicit `flow_type=<type>` parameter is present, it takes advisory precedence; if it differs from auto-detection, a `[WARN]` level event MUST be emitted.

### §4. Telemetry, Logging & Identity

- All logs, echos, and stdout emissions MUST adhere to the format:
  `[<ISO8601_UTC_TIMESTAMP>] [<LOG_LEVEL>] [<PROJECT_NAME_SHORT>.<FILE_NAME>.<FUNCT_NAME>.<LINE_NUMBER>]`
- Output formatting MUST conform to standard C print semantics (`emit`, `puts`, `println`, `printf`).
- All session logs, audit trails, work items, and telemetry records MUST use hybrid **UUIDv7** identifiers formatted as `YYYYMMDD-HHMMSS-mmm-7xxx-Nxxx-xxxxxxxxxxxx`.

### §5. Reboot Clean State Guarantee

- On `reboot_fresh()`, all in-memory file representations, cached summaries, and CATALOG entries MUST be completely cleared before re-executing `main()`, preventing stale reference leaks.

### §6. RTK Proxy

- All shell commands executed during an AI session MUST be prefixed with `$RTK_BIN` (transparent proxy) when available, to reduce token output and improve session efficiency.

---

## Article III — Canonical Directory Layout

The following layout is the reusable template structure. It is project-agnostic — any project adopting `hanaden-ai-booter` inherits this layout.

```
<project-root>/
├── PROJECT_HOME/                          ← Agent entry point & core engine
│   ├── BOOTSTRAP.md                       ← AI bootloader & turn gate engine
│   ├── CONSTITUTION.md                    ← Project governance & invariants (this file)
│   ├── README.md                          ← Operational reference for PROJECT_HOME
│   ├── *.md                               ← AI executable shebang scripts
│   ├── boot/                              ← Runtime bootloader scratch / state
│   ├── docs/                              ← Agent operational documentation
│   └── src/                               ← Project source tree (optional)
├── AGENTS.md                              ← Universal agent bootstrap redirect
├── GEMINI.md                              ← Gemini / Google AI redirect
├── CLAUDE.md                              ← Claude / Anthropic redirect
├── README.md                              ← Repository overview
├── .gitignore                             ← Git ignore rules
├── VERSION                                ← Single source of truth for version
├── mise.toml                              ← Task lifecycle manager
├── docs/                                  ← Workspace-level documentation
├── history/                               ← Project history archive
├── src/                                   ← Application source
│   ├── main/                              ← Main source
│   └── test/[projectname]/                ← Tests
└── target/                                ← Build output (gitignored)
```

> **Note:** The `src/` and output directories (`target/`, `build/`, `dist/`, etc.) shown above are representative. Source code, scripts, configs, and output directories MUST use the natural language/tool naming conventions for your specific tech stack. The strict domain boundary applies only to SDLC `.md` artifacts.

Agent redirect files reside in dotfile directories matching each agent's convention (`.cursor/`, `.windsurf/`, `.claude/`, `.amazonq/`, `.continue/`, `.github/`, `.junie/`, `.agents/`).

---

## Article IV — Agent Bootstrap Redirect Architecture

All supported AI agents and IDEs MUST be bootstrapped through a uniform redirect pattern. Each agent's configuration file contains an identical directive pointing to `PROJECT_HOME/boot/BOOTSTRAP.md`.

| Agent / IDE         | Configuration File                           |
|---------------------|----------------------------------------------|
| Universal           | `AGENTS.md`                                  |
| Gemini / Google AI  | `GEMINI.md`                                  |
| Claude / Anthropic  | `CLAUDE.md`, `.claude/CLAUDE.md`             |
| Cursor IDE          | `.cursor/rules/00-hanaden-bootstrap.mdc`     |
| Windsurf            | `.windsurfrules`, `.windsurf/rules/00-bootstrap.md` |
| Cline               | `.clinerules`                                |
| Continue            | `.continue/rules/00-hanaden-bootstrap.md`    |
| Amazon Q            | `.amazonq/rules/00-hanaden-bootstrap.md`     |
| GitHub Copilot      | `.github/copilot-instructions.md`            |
| JetBrains Junie     | `.junie/AGENTS.md`                           |
| Devin / Generic     | `.agents/AGENTS.md`                          |

New agents SHOULD be added to this table and a corresponding redirect file created following the same pattern.

---

## Article V — Quality & Verification

### §1. Maven-Style Lifecycle

Task execution targets standard Maven lifecycle phases via `mise.toml`:
- `validate`: Structure, directory existence, and version consistency check.
- `compile`: Syntax validation.
- `test`: Unit testing. Test files MUST be placed under `src/test/[projectname]`.
- `package`: Artifact archiving (`target/<project-name>-${VERSION}.tar.gz`).
- `verify`: Integration & end-to-end verification.

> [!WARNING]
> The current `mise.toml` and `bunfig.toml` contain legacy task definitions
> inherited from a prior project. They reference files that do not exist in this
> repository. These files require a full rewrite to align with the current
> project before any lifecycle commands are functional.

---

## Article VI — SDLC Engine Instantiation

### §1. Governing Engine
`PROJECT_HOME/docs/20260818-033649-124680-7266-a219-84d3929f1e0a-SdlcEngineSpec.system-0.0.1.md`
READ-ONLY. Project-agnostic generic SDLC engine. This article provides the project-specific input data to that engine.

### §2. Spec Tree Root
`PROJECT_HOME/docs/architecture-design-features-specs/BwrapEnhanced2026.strat/`

### §3. Navigation Map
Node count determined dynamically at doc-consumption time by walking the spec tree.
`PROJECT_HOME/docs/architecture-design-features-specs/20260816-171937-121071-7f00-a05f-7ea9697692bc-SdlcHierarchyOverview.overview-0.0.1.md`

### §4. TDD Implementation Order
Per SdlcEngineSpec §2: BOTTOM-UP — leaf SPECs → FEATs → MOTI → DRIV → STRAT.
Phase 0 (Preflight gate) → Phase 1 (45 SPECs) → Phase 2 (Feature integration) → Phase 3 (E2E strategy).

### §5. Phase Gate Rule
Phase 0 BwrapMinimalSmoke MUST pass before any Phase 1 tests run.
If BwrapMinimalSmoke fails: record BLOCKED, halt, report.

### §6. Code as SST
During reverse engineering: bwrap-enhanced.sh is the Single Source of Truth.
Spec parent assignments confirmed from code context, not spec metadata.
