<!-- #!/usr/bin/env ai-exec flow_type=PSEUDOCODE -->
---
Mandate: "For all AI tools: every AI-conversation, AI-session, AI-Processor, AI-Agent start, restart, or reboot MUST follow the boot sequence steps sequentially and completely - skipping steps is not allowed."
priority: 0
PROJECT_NAME_LONG: hanaden AI Bootloader for all AI-Agents and AI-Processors
PROJECT_NAME_SHORT: hanaden-ai-boot-loader
PROJECT-VERSION: 0.0.1-alpha
DOB: 2026-01-01T20:15:00.000Z
status: active-development
copyright: (c) 2026 Hanaden - Frederick Bloom
---

> [!IMPORTANT]
> **AGENT MANDATORY (MUST OBEY) -- UNIVERSAL COLD/WARM/HOT BOOT/REBOOT SEQUENCE FOR ALL AI AGENTS**
> * **File purpose**: BOOTSTRAP configuration and pseudocode analogous to Linux grub + scripting.
> * **MUST**:
>   * Obey RFC 2119 (reference: section 'Definitions' below) MUST, MUST-NOT statements in AI rules, governance iron-clad rules and policies.
>   * Analyze and fully process all aspects in this file every AI SESSION start, restart, or reboot.
> * Example list of AI tools from all vendors that MUST obey: ALL AGENTS (AI-AGENT, AI-SUBAGENT, AI-SUPERAGENT, AI-IDE-AGENT, etc.) (AI-IDE-PROCESSOR, AI-TERMINAL-PROCESSOR, etc.)
>   * Sample vendors: OpenAI, Google, Anthropic, Microsoft, Mistral AI, Cohere, Aleph Alpha, IBM, Alibaba, Tencent, Meta, Apple, Amazon, etc.
>   * Sample AI tools: Claude, Ollama, GPT, DeepSeek, Gemini, Copilot, Antigravity, etc.
> * **Boot Sequence - required flow**:
>   * MUST follow boot sequence steps (0-N) sequentially and completely - skipping steps is not allowed.
>   * MUST halt on any FATAL or CRITICAL error raised, or logged.
>   * MUST flag all logic and decision ambiguities as FATAL and HALT immediately.
>   * MUST analyze and follow the Global AI Standing Rules, Policies and Standards.
//=
## Definitions
### RFC-2119 key words and terminologies.
* MUST (defines rules that must be 100% followed).
* MUST-NOT (defines rules that are 100% forbidden, denied, not allowed, not permissible).
* SHOULD (defines rules that should be followed if possible, ~80% required).
* SHOULD-NOT (defines rules that should be avoided if possible, ~80% forbidden, denied, not allowed, not permissible).
* MAY (optional - at the discretion of the current session AI agent).
* MUST / MUST-NOT take absolute precedence over SHOULD / SHOULD-NOT, which take precedence over MAY.

* When: **FATAL = HALT = ABEND [on: rule-violation | assertion-failure | logic-ambiguity | missing-required-file | LOGGER.fatal]:**
  * **Action:** Engine MUST snapshot call stack + in-scope vars before any other action,
    then emit to console (println, unfiltered) AND LOGGER.error:
    `[<ts>] [FATAL] [<code>] <msg> | cause: <cause> | at: <FRAME_0> <- <FRAME_1> <- ... <- <FRAME_N> | vars: <k=v> ...`
  * `<ts>` -- ISO 8601 nanosecond UTC: `YYYY-MM-DDThh:mm:ss.nnnnnnnnnZ`
  * `<code>` -- SCREAMING-KEBAB token (e.g. `FATAL-NO-BOOTSTRAP`)
  * `<msg>` -- human-readable description of what failed
  * `cause:` -- violated rule, assertion expression, or unexpected value
  * `at:` -- `FILE.FUNCT:LINE` frames outermost->innermost, separated by ` <- `
  * `vars:` -- `k=v` pairs, FUNCT scope + FILE.ENV scope at fault site
  * **Halt:** AI MUST-NOT continue, retry, skip, or substitute after ABEND.

### HANADEN.Hybrid.UUIDv7 Identifier
* A human readable identifier string with standard UUIDv7 prefix.
#### Format:
```
YYYYMMDD-HHMMSS-uuuuuu-7xxx-Nxxx-xxxxxxxxxxxx-<slug>[-<NNN>][.<optional-class-prefix>].<class>[-<semver>].<ext>
```
* `YYYYMMDD-HHMMSS-uuuuuu-7xxx-Nxxx-xxxxxxxxxxxx` is the Hanaden.Hybrid.UUIDv7.Extension prefix -- a superset of standard UUIDv7. All standard UUIDv7 fields are present; the `uuuuuu` microsecond field is a Hanaden extension-only addition.
* **Timestamp Generation (MUST):** AI MUST obtain `YYYYMMDD-HHMMSS-uuuuuu` from OS clock at file creation time. Preferred: `date -u +%Y%m%d-%H%M%S-%6N`. Fallback: second-level precision with `000000` microseconds when sub-second OS clock is unavailable. No Fabrication rule (below) applies.

| Segment | Description | Specification/Requirements |
|---|---|---|
| `YYYYMMDD` | Date UTC | Standard UUIDv7 -- YYYYMMDD=YearMonthDay(UTC), zero-padded |
| `HHMMSS` | Time UTC | Standard UUIDv7 -- 24h format, no colon separator |
| `uuuuuu` | Microseconds | Hanaden.Hybrid.UUIDv7.Extension -- 6 digits zero-padded, 000000-999999; NOT in standard UUIDv7; `floor(uuuuuu/1000)` = ms; ms-only records use `mmm000` |
| `7xxx` | Version Nibble | Standard UUIDv7 -- version nibble `7` + 3 random hex digits |
| `Nxxx` | Variant Nibble | Standard UUIDv7 -- variant nibble `8`-`b` + 3 random hex digits |
| `xxxxxxxxxxxx` | Random Payload | Standard UUIDv7 -- 12 random hex digits |
| `<slug>` | Human readable description (<= 187 chars) | Required: Hanaden extension -- CamelCase; no hyphens, no spaces; attempt slug.length <= 30 chars; actual max_slug = 249 - 62 (fixed overhead) = 187 chars |
| `[-<NNN>]` | Sequence counter | Optional: Hanaden extension -- 3-digit zero-padded (001-999); for N-of-kind ordering (e.g., run attempts 001, 002, 003 per plan); placed between slug and class |
| `[.<optional-class-prefix>]` | Class qualifier | Optional: Hanaden extension -- dot-separated token between slug and class; qualifies class without replacing it; chars + 1 (dot) count against max slug length. See Extension Prefixes below. |
| `.<class>` | Class descriptor (2-6 chars) | Required: Hanaden extension -- lowercase, 2-6 chars, no hyphens. See class glossary below. |
| `-<semver>` | Semver | Optional: Hanaden extension -- hyphen-separated from class; semver format (ex: MAJOR.MINOR.PATCH, 1.2.3, 1.2.3-alpha, 1.2.3-beta, 1.2.3-rc) |
| `.<ext>` | File extension | Required: Hanaden extension -- lowercase; ex: `md`, `yaml`, `json`, `sh` |

#### Class Glossary

| Class | Description |
|---|---|
| `analys` | analysis |
| `arch` | architecture |
| `audit` | audit |
| `bstorm` | brainstorm |
| `bug` | bug report |
| `collab` | collaboration document |
| `config` | configuration |
| `decis` | decision record |
| `deliv` | delivery |
| `design` | design document |
| `driv` | driver (SDLC hierarchy) |
| `feat` | feature (SDLC hierarchy) |
| `fsm` | finite state machine |
| `incid` | incident report |
| `kanban` | kanban board/card |
| `lesson` | lesson learned |
| `method` | methodology |
| `moti` | motivator (SDLC hierarchy) |
| `oview` | overview |
| `plan` | plan |
| `report` | report |
| `run` | execution run |
| `sdlc` | SDLC artifact |
| `secbul` | security bulletin |
| `spec` | specification (SDLC hierarchy) |
| `strat` | strategy (SDLC hierarchy) |
| `sys` | system (short form) |
| `system` | system specification |
| `tline` | timeline |
| `tmpl` | template |
| `tst` | test |
| `tstsu` | test suite |
| `wi` | work item |

#### Extension Prefixes

An **extension prefix** is an optional dot-separated token inserted between the slug and the class. It qualifies the class without replacing it. Extension prefixes reduce the max slug length by their character count + 1 (the dot).

```
Standard:       {uuid}-{slug}.<class>.<ext>
With prefix:    {uuid}-{slug}.<prefix>.<class>.<ext>
```

| Prefix | Chars added | Max slug | Description |
|--------|-------------|----------|-------------|
| `ai-hitl` | 8 (+1 dot = 9) | 178 | AI-HITL collaboration protocol -- document uses structured Q/A markers for human-in-the-loop AI collaboration. Composable with any class. |

Examples:
- `{uuid}-CliRevision.ai-hitl.collab.md` -- AI-HITL collaboration document
- `{uuid}-BannerSpec.ai-hitl.spec.md` -- AI-HITL co-authored specification
- `{uuid}-DebugPlan.ai-hitl.plan.md` -- AI-HITL co-authored plan

#### Bidirectional conversion between HANADEN.Hybrid.UUIDv7 and standard UUIDv7:
> [!IMPORTANT]
> **Partial conversion only.** Only the UUIDv7 portion (`YYYYMMDD-HHMMSS-uuuuuu-7xxx-Nxxx-xxxxxxxxxxxx`) maps bidirectionally and losslessly to a standard UUIDv7. The `uuuuuu` microsecond field maps to sub-millisecond precision within the UUIDv7 timestamp. The Hanaden suffix (`-<slug>.<class>[-<semver>].<ext>`) is NOT part of the standard UUIDv7 format and is LOST when converting to standard UUIDv7.
> * **Timestamp mapping (lossless):** The 48-bit millisecond epoch timestamp in a standard UUIDv7 (`xxxxxxxx-xxxx-7xxx-Nxxx-xxxxxxxxxxxx`) bidirectionally and losslessly maps to the `YYYYMMDD-HHMMSS-uuuuuu` prefix. Microseconds (`uuuuuu`) encode sub-ms precision: `floor(uuuuuu/1000)` = ms portion of epoch.
> * **HANADEN.Hybrid.UUIDv7 -> Standard UUIDv7 (timestamp only)**: parse `YYYYMMDD`+`HHMMSS`+`uuuuuu` as ISO 8601 UTC -> compute Unix ms epoch -> pack into UUIDv7 48-bit `time_ms` field; copy `7xxx`, `Nxxx`, `xxxxxxxxxxxx` verbatim. Suffix (`-<slug>.<class>[-<semver>].<ext>`) is discarded and lost.
> * **Standard UUIDv7 -> HANADEN.Hybrid.UUIDv7 (timestamp only)**: unpack `time_ms` -> format as `YYYYMMDD-HHMMSS-uuuuuu`; copy `7xxx`, `Nxxx`, `xxxxxxxxxxxx` verbatim. Suffix MUST be restored from the `filename:` frontmatter field; if frontmatter is absent, suffix cannot be recovered.

## Global AI Standing Rules, Policies and Standards
* MUST always obey RFC-2119 terminology.
* MUST only encode in pure vanilla ASCII text - not special or graphical characters in git, source code, pseudo code, scripts, comments, .md, filenames, yaml, json, XML, HTML and all text files.
* **Domain boundary (strict):** Hanaden DSL rules and naming conventions apply to SDLC `.md` artifacts ONLY. Source code (`src/`, scripts, configs) MUST use language/tool naming conventions. The domains are entirely distinct -- NO exceptions.
* **MISE (MUST):** When `MISE_BIN` is set: store `MISE_SHIMS_DIR=dirname(MISE_BIN)` in working_memory at boot. Use `$MISE_SHIMS_DIR/<tool>` for all AI-issued tool calls. MUST-NOT re-eval per command -- mise shims are standalone; no activation needed per call.
* **RTK (MUST):** When `RTK_BIN` is set: MUST prefix all AI-issued commands with `$RTK_BIN` for RTK-supported subcommands. Applies to AI-initiated agentic commands only -- NOT user-directed raw terminal execution. User conversational shorthand (e.g. `git X`) is notation only; AI MUST silently translate to `$RTK_BIN git X` before executing.
* **No Substitution (MUST):** AI MUST-NOT replace, reimplement, approximate, merge, or degrade any defined function, struct, loop, or data/variable/prompt/data flow with alternative approaches. The pseudocode definition IS the implementation.
* **No Omission (MUST):** AI MUST execute every defined function call, populate every struct field per its definition, iterate every loop to completion, and perform every variable assignment. Partial execution, deferred execution, and skipped operations are FATAL.
* **No Fabrication (MUST):** AI MUST-NOT emit output (LOGGER or console) for operations not actually executed, claim variables hold values never computed, or produce estimated/placeholder data. Every output line and every state claim MUST be the direct result: of actual execution. Violation is FATAL.
* **System Execution Fallback hierarchy (MUST):** `POSIX_API < NATIVE_API < OS_CLI_TOOL < FATAL`. Default: `POSIX_API`.
  * The AI MUST execute requests using this fallback chain to fetch real system data (e.g., `OS.*` methods).
  * If the fallback chain exhausts to `FATAL`, the AI MUST trigger the `FATAL = HALT = ABEND` sequence.
  * The AI MUST-NOT make up, simulate, or improvise data under any circumstance.

### RFC 2119 Modal Keywords (Rule: Scope of Application)
* RFC 2119 keywords (MUST, MUST-NOT) as defined in `## Definitions` apply throughout ALL rules, pseudo-code, and documentation in this project.

### AI DSL Language Definition - Domain Specific Languages Used in This Project
* This is an event-driven declarative system with Funct; entry-point Funct is `main()`.
* **Mermaid & Pseudocode Execution:** Treat as executable/data flow specification.
  * **MUST - external mmd, rules, stages, pseudocode, and code block generation and execution (use instead of AI internal interpreter):** AI MUST generate and execute real code outside the AI engine as a concrete implementation of any functional AI declaration, mermaid diagram, pseudocode block, or embedded code block found in the AI-exec file. Runner language MUST match the embedded block language: pseudocode, AI-DSL declarations, and mermaid default to Python; explicit language blocks (go, java, py/python, rust, zig, or any other language) MUST run in their native runner. A single AI-exec file containing multiple language blocks MUST spawn one external process per language, each artifact placed under `$TMPDIR/ai-gen/<conversation-id>/<source-file-slug>/<lang>/`. Generated code MUST pass a test-refine loop before results are accepted as in-session output: execute => verify and validate expected f(x) values against actual results => if error/wrong: patch and retry (max 15 iterations). If still failing after 15 iterations: LOGGER.error("EXTERNAL-RUNNER-DEGRADED: max iterations exceeded -- falling back to AI internal interpreter mode") and fall back to in-session AI simulation (degraded interpreter mode). Rules:
    * **Artifact location (MUST):** Generated artifacts MUST be placed under `$TMPDIR/ai-gen/<conversation-id>/<source-file-slug>/` and named after the source block they implement. Scope is conversation-lifetime only -- artifacts are NOT persisted across sessions.
    * **Invalidation -- AI-side (MUST):** Before each use, AI MUST check: if artifact mtime < source mmd/pseudocode mtime OR source content hash has changed -- artifact is STALE. AI MUST-NOT use a stale artifact.
    * **Regeneration (MUST):** On STALE (detected by AI or self-check): AI MUST atomically regenerate before executing. Partial regeneration is FATAL.
    * **Self-check on exec (MUST):** The generated artifact MUST embed a self-check at startup: load its own manifest of source files it implements (paths + content hashes captured at generation time); verify each source is unchanged. If any source has changed: artifact MUST exit with STALE signal; AI MUST detect signal, trigger regeneration, and retry. MUST-NOT proceed with stale sources.
    * **Per-event self-check (MUST):** The self-check MUST re-execute at the start of every event processed by the artifact -- not only at startup. If stale is detected mid-session: artifact MUST exit with STALE signal immediately; AI MUST regenerate and resume from the triggering event.
    * **Session binding (MUST):** stdout/stderr of external process MUST be captured verbatim and treated as in-session output -- subject to all Output Rendering rules.
* MUST obey/follow - Java SLF4J `.log*()`, `.is*()` methods on `LOGGER` (any non-`.log*` method is FATAL).
* MUST obey/follow - Logback configuration from `logback.xml` and `logback-test.xml` (see below).
* LOGGER configuration is defined in `logback.xml` (production) and `logback-test.xml` (test). These files are the single source of truth for all LOGGER settings. See `# LOGGER Configuration` in the boot config section below.
* **LogLevel hierarchy:** `DEBUG < INFO < WARN < ERROR < FATAL`.
  * MUST HALT after any log level of ERROR or FATAL.
* MUST obey/follow - formatting output (not LOGGER) per C lang only: `print`, `println`, `puts`, `printf`. Others are FATAL.
  * ALWAYS prints to CONSOLE; not filtered by Logback level; MUST output verbatim -- never summarize, omit, hide, or suppress.
  * MUST C style print, printf, puts, println must be direct to console. no logger no prefix. NO EXCEPTIONS. NO EXCEPTIONS.
* MUST **Output Rendering:** ALL `LOGGER.log*()` and C-style console output MUST be rendered raw and verbatim in code-fenced console blocks. NO markdown, NO AI markup, NO escaping, NO summarizing, NO omitting, NO suppressing. What the code outputs is exactly what appears. Each file's output MUST be fully visible before processing the next file. NO EXCEPTIONS.
* **Event Handlers (naming convention):** Triplets follow `onEvent[X][{Before,After}]()` naming. MUST register all onEvent handlers at file load time using the Engine-provided register function call. MUST-NOT call event handlers directly. MUST-NOT call `onEvent[X]()` to fire an event -- use `eventFire[X]()` only. Calling `f()` directly just calls `f()`, does not fire the event.

### Engine Entry Point Convention
* invoke main() as the entry point - FATAL if not main() defined.

### State Tracking -- .hanaden-ai-engine.state/
* **State root (MUST):** `$TMPDIR/ai-gen/<conversation-id>/.hanaden-ai-engine.state/` --
  hidden metadata dir, conversation-lifetime only, NOT part of tracked content, zero
  collision risk with project files. Analogous to `.git/` at a repo root.
* **One stat file per real entry (MUST):** Each tracked filesystem entry (file or directory)
  MUST have exactly one `.stat.json` in the state root, mirroring the relative path
  structure from `PROJECT_HOME`.
  Example: `PROJECT_HOME/boot/BOOTSTRAP.md` maps to
  `.hanaden-ai-engine.state/boot/BOOTSTRAP.md.stat.json`
  MUST-NOT use one aggregated file -- per-file stat access is O(1) per seed-file check;
  mandatory for realtime per-event performance.
* **Stat file schema (MUST):** Every `.stat.json` MUST contain exactly:
  ```json
  {
    "file_fullpath": "<absolute path>",
    "size": <bytes>,
    "mtime_ns": <int nanoseconds>,
    "ctime_ns": <int nanoseconds>,
    "inode": <int>,
    "is_dir": <bool>,
    "mime_type": "<MIME string>",
    "blake2b_256": "<64 hex chars or null>",
    "crud_status": "<CREATED|UPDATED|DELETED|UNCHANGED>",
    "links": <int>,
    "linux_perm_bits": "<e.g. -rw-rw-r-->"
  }
  ```
* **Hash rules (MUST):**
  * Algorithm: `hashlib.blake2b(data, digest_size=32)` -- faster than SHA-256, Python
    stdlib (3.6+), equivalent collision resistance. Output: 64 hex chars.
  * `blake2b_256` for directories: MUST be `null`. Directory `mtime_ns` is sufficient --
    Linux updates dir mtime on any entry add/remove. Computing a content hash for dirs
    is undefined and MUST-NOT be attempted.
  * **Two-level fast gate (MUST):** For all non-CORE_FILES: check `mtime_ns` AND `size`
    from `os.stat()` first. Compute `blake2b_256` ONLY if either has changed.
    MUST-NOT compute `blake2b_256` for every file on every event.
  * **CORE_FILES exception (MUST):** ALWAYS compute `blake2b_256` for each entry in
    `CORE_FILES` on every event, regardless of stat gate result. CORE_FILES are reboot
    triggers -- mtime drift must not suppress detection.
* **Atomic write (MUST):** Every `.stat.json` write MUST: write to `<path>.tmp` then
  `os.rename(<path>.tmp, <path>)`. MUST-NOT write directly to `.stat.json`.
  Partial write + crash leaves `.tmp` orphan; original `.stat.json` remains intact.
* **Read timing (MUST):** `onEventUserTurnBefore()` MUST read CORE_FILE `.stat.json`
  files first (seed-file change check and possible reboot), then read all remaining
  `.stat.json` files to reconstruct `DIR_LS_STAT_CACHE_PREVIOUS` before walking current.
* **Write timing (MUST):** `onEventUserTurnAfter()` MUST write updated `.stat.json` for
  every entry where `crud_status != UNCHANGED`, plus CREATED and DELETED entries.
  UNCHANGED entries are not rewritten -- their existing `.stat.json` remains valid.
* **Scope (MUST):** Conversation-lifetime only. MUST-NOT persist `.hanaden-ai-engine.state/`
  across sessions. OS `/tmp` cleanup is sufficient; no explicit deletion required.

### Variable, Function Scoping and Parameter Binding
* Scope hierarchy (innermost to outermost): `OS/Shell.ENV` < `AGENT.ENV` < `WORKSPACE.ENV` < `PROJECT.ENV` < `FILE.ENV` < `FUNCT`
* **Read**: resolves innermost to outermost scope chain.
* **Assign** (`var varname =`): mutates the nearest scope frame where declared; creates in current frame if undeclared.
* **`var varname =`**: force-creates a local shadow binding; hides outer variables; unloaded on scope exit.

### Token Economy and Memory
* Markdown is canonical (may contain YAML frontmatter, Mermaid, etc.). Load only files needed for the current task.
* MUST Retain/Keep: Details >= (ie: higher than)H2 (note H1>H2>H3>H4), bullet points level and summary of lower level bullet points all for navigation, index, search, and quick lookup and reference.

## Step 0 -- MANDATORY TURN GATE
> [!CAUTION]
> * MUST AI engine auto-discover Events-X from functs matching onEvent[X][NONE|Before|After]() defined in pseudocode; fire Event[X] when code invokes eventFire[X]() or engine detects real-world occurrence of X.
> * MUST engine invoke Event[X] triplet serially (never async): onEvent[X]Before() -> onEvent[X]() -> onEvent[X]After(); non-existent members are NOOP, silently skipped.

## Step 1 -- Load and Execute BOOTSTRAP (self)
> [!IMPORTANT]
> * MUST read `/boot/BOOTSTRAP.md` in full via view_file (MUST-NOT skim or skip)
> * MUST batch read and anayaize files as opned and execute/process as they are loaded.  Becareful of shebangs and optimize by loading first line only except REAMDME and CONSTITUTION and any other files that require full file read.

## Step 2 -- Activate Toolchain
Run in agent terminal (best-effort; MUST NOT fail boot):
> [!IMPORTANT]
> **MISE** is the master toolchain manager -- it provisions all tools and MUST activate first.
> **RTK** is a transparent proxy for supported AI commands -- reduces AI token output.
> Both are **best-effort**: if unavailable, boot continues with raw tool output.

### 2a. MISE -- toolchain setup (first)
* May be in ~/.local/bin or OS/Environment Path
* eval runs ONCE at boot only -- MUST-NOT re-run per command call.

```bash
eval "$(mise activate --shims bash 2>/dev/null)" || true
```
- `mise` not found or eval fails -> `MISE_BIN=""` | `MISE_SHIMS_DIR=""` | `[BOOT] mise unavailable -- raw output`
- `mise` eval success -> `MISE_BIN="$(which mise 2>/dev/null)"` | `MISE_SHIMS_DIR="$(dirname $MISE_BIN)"` | store both in session working_memory | `[BOOT] mise active <shims|no-shims> MISE_SHIMS_DIR=<path>`

### 2b. RTK -- command proxy (after MISE)
```bash
RTK_BIN=$(which rtk 2>/dev/null || find ~/.local/share/mise/shims ~/.local/bin /usr/local/bin -name rtk 2>/dev/null | head -n 1)
echo "RTK_BIN=$RTK_BIN"
```
- `rtk` found -> `RTK_BIN="<abs-path>"` | store in working_memory | `[BOOT] rtk at <path>` -- else `RTK_BIN=""`
> Applies to AI-issued agentic commands only. User-directed raw terminal execution is exempt.
> RTK subcommands (non-exhaustive): `git`, `diff`, `find`, `ls`, `tree`, `grep`, `rg`, `curl`, `npm`, `pnpm`, `docker`, `go`, `cargo`, `pytest`, `jest`, `mvn`, `tsc`.
> See https://github.com/rtk-ai/rtk for full list.

## Step 3 -- Discover, Sort, and Execute AI Instruction Files

### Static Rules
- **var `PROJECT_HOME`** = `PROJECT_HOME/` directory literal -- the **virtual chroot root**; all paths are confined within it (analogous to bwrap/chroot). There is no separate workspace-root scope.
- **Seeds** (priority first, retained for session context/reference): `PROJECT_HOME/CONSTITUTION.md`, `PROJECT_HOME/README.md`, `PROJECT_HOME/boot/BOOTSTRAP.md`
  * stays in `working_memory` always; never unloaded except on file-change detection or reboot.
  * `README.md` (in any discovered directory) and `CONSTITUTION.md` (in `PROJECT_HOME`) do NOT require an AI shebang on line 1; both are implicitly classified as AI instructional (`shebangType = AI`) and always consumed into `working_memory`.
- **ENTRY_POINT** on new session | conversation - run main()
- **CORE_FILES**: `[PROJECT_HOME/boot/BOOTSTRAP.md, PROJECT_HOME/CONSTITUTION.md, PROJECT_HOME/README.md]`
- **flow_type preference**: prefer `UML-ACTIVITY-DIAGRAM`|`RAW-DATA`|`UML-MSC`|`UML-SEQUENCE-DIAGRAM`; fallback `TREE`|`GRAPH`|`GRAPH-WITH-STATE`; exec_flow correctness above all
- **`LOGGER`** = session-scoped logger object. Default level `WARN`. Per-file override via `LOGGER.setLevel()`. Guards: `LOGGER.is*Enabled()`
- **AI-EXEC Shebang**: First line `<!-- #!ai-exec [params] -->` marks `.md` as AI-instructional; `flow_type=<type>` param is **advisory only**, captured from shebang match
- **OS Shebang**: First line `#!/...` marks `.sh` as OS-executable; MUST only exec if has `+x` permission currently set for the user at OS level.  never chmod, warn and skip if missing

# LOGGER Configuration
* Source of truth: `logback.xml` (production), `logback-test.xml` (test).
* Agents MUST NOT override or re-declare LOGGER config inline.
* Default level: `WARN`. Per-file override via `LOGGER.setLevel()` at `FILE.ENV` scope; auto-restores on file unload.

# Config: Logback compliant
```xml
<!-- logback.xml -->
<configuration>
  <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>[%d{yyyy-MM-dd'T'HH:mm:ss.SSSSSS}] [%-5level] [%X{project}.%F.%M:%L] %msg%n</pattern>
    </encoder>
  </appender>
  <root level="INFO">
    <appender-ref ref="CONSOLE"/>
  </root>
</configuration>
```

## BOOTSTRAP.md test suite cases - MUST RUN FOR TESTING CYCLES - DO NOT ALWAYS RUN (2026-08-05)
> [!NOTE]
> BOOTSTRAP.md is a self-describing, standalone TDD artifact -- spec, pseudocode
> implementation, and the full test suite live together in this ONE file. This is a
> deliberate exception to "don't comingle tests with production scripts": the boot
> engine must remain fully understandable, executable, and testable from a single

# Bootstrap Engine -- evaluate immediately.
```pseudo code in AI-speak and AI-prompts
var LOGGER
struct FILE_STATS = same as Linux stat enriched with exec_type (OS_SHEBANG | AI_SHEBANG | default NONE), file_fullpath, front_matter_keyvals, crud_status (CREATED | DELETED | UPDATED | default = UNCHANGED), sub_dir_entry (required if mime_type is filesystem/directory : DIR_LS_STAT_LIST - default = EMPTY LIST)

[EXAMPLE-FOR-AI]
 * example directory
  file_path: /tmp/
 size: <bytes>             Blocks: 0          IO_Block: 4096   mime_type: filesystem/directory
device: 0,40    Inode: 1           Links: 22
linux_perm_bits: (1777/drwxrwxrwt)  Uid: ( 1000/<userID>)   Gid: ( 1001/<groupID>)
access: <OS.stat.nanoseconds>
modify: <OS.stat.nanoseconds>
change: <OS.stat.nanoseconds>
 birth: <OS.stat.nanoseconds>
 * example file
  file_path: /tmp/touchfile.txt
 size: <bytes>               Blocks: <#>          IO_Block: 4096   mime_type: text/plain
device: 0,40    Inode: 933         Links: 1
linux_perm_bits: (0664/-rw-rw-r--)  Uid: ( 1000/<userID>)   Gid: ( 1001/<groupID>)
access: <OS.stat.nanoseconds>
modify: <OS.stat.nanoseconds>
change: <OS.stat.nanoseconds>
 birth: <OS.stat.nanoseconds>
[/EXAMPLE-FOR-AI]

struct DIR_LS_STAT_LIST ordered list of FILE_STATS for a single shallow directory at current level only - ordered alphabetically (lexical order A-Z) with files listed before dir.

var DIR_LS_STAT_CACHE_CURRENT, DIR_LS_STAT_CACHE_PREVIOUS : DIR_LS_STAT_LIST - of the full tree what was discovred

var DIFF_STAT_CURRENT_DIR_LS : DIR_LS_STAT_LIST

var EVENT_TIMER_START_BOOT = OS.currentTimeNanos()
var EVENT_TIMER_END_BOOT = Long.MAX_VALUE
var EVENT_TIMER_START_REBOOT = OS.currentTimeNanos()
var EVENT_TIMER_END_REBOOT = Long.MAX_VALUE
var EVENT_TIMER_START_USER_TURN = OS.currentTimeNanos()
var EVENT_TIMER_END_USER_TURN = Long.MAX_VALUE
var EVENT_TIMER_START_AI_TURN = OS.currentTimeNanos()
var EVENT_TIMER_END_AI_TURN = Long.MAX_VALUE

immutable var WALK_DEPTH = 5
immutable var WALK_GLOB = "*"
immutable var CORE_FILES = [PROJECT_HOME/boot/BOOTSTRAP.md, PROJECT_HOME/CONSTITUTION.md, PROJECT_HOME/README.md]
immutable var AI_EXEC_SHEBANG_REGEX = "^<!\-\-\\s*#!(?:/usr/bin/env\\s+)?ai-exec(?:\\s+(?P<params>[^-].*?))?\s*-->"
immutable var OS_SHEBANG_REGEX = "^#!/.*"

//---------------------------
funct onEventBootBefore()
  EVENT_TIMER_START_BOOT = OS.currentTimeNanos()
  LOGGER.info("onEventBootBefore() - **************")

funct onEventBootAfter()
  EVENT_TIMER_END_BOOT = OS.currentTimeNanos()
  var durationNs = EVENT_TIMER_END_BOOT - EVENT_TIMER_START_BOOT
  LOGGER.info("event.Boot start=" + OS.formatEpochNs(EVENT_TIMER_START_BOOT, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | end=" + OS.formatEpochNs(EVENT_TIMER_END_BOOT, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | duration=" + OS.formatDurationNs(durationNs, "HH:mm:ss.SSSSSSSSS"))
  LOGGER.info("onEventBootAfter() - **************")

funct onEventBoot()
  LOGGER.info("onEventBoot() - **************")
  LOGGER.info("*** boot() - BOOTING HANADEN - Frederick Bloom ***")
  LOGGER.info Linux like full Kernel boot syslog information - for AI - not OS: uname -a, AI current matrix supported (models, engines, versions), cpuinfo, df -h, free -m, inxi -F, dmesg, SHELL startup and version

//---------------------------
funct onEventRebootBefore()
  EVENT_TIMER_START_REBOOT = OS.currentTimeNanos()
  LOGGER.info("onEventRebootBefore() - **************")

funct onEventRebootAfter()
  EVENT_TIMER_END_REBOOT = OS.currentTimeNanos()
  var durationNs = EVENT_TIMER_END_REBOOT - EVENT_TIMER_START_REBOOT
  LOGGER.info("event.Reboot start=" + OS.formatEpochNs(EVENT_TIMER_START_REBOOT, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | end=" + OS.formatEpochNs(EVENT_TIMER_END_REBOOT, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | duration=" + OS.formatDurationNs(durationNs, "HH:mm:ss.SSSSSSSSS"))
  LOGGER.info("onEventRebootAfter() - **************")

funct onEventReboot()
  LOGGER.info("onEventReboot() - **************")
  println "*** === REBOOTING HANADEN - Frederick Bloom *** - stdout console"
  LOGGER.info("*** REBOOTING HANADEN - Frederick Bloom ***")
  // P1 -- stop active writers first (prevent writes during teardown)
  stop all subprocesses and subagents
  // P2 -- flush I/O while lock held, then release lock, then close handles
  flush stdio, stdout, stderr
  release console lock if acquired
  close all file handlers
  // P3 -- deregister all event handlers before memory is freed (prevent stale handler refs)
  deregister all onEvent handlers
  // P4 -- clear in-memory state innermost to outermost scope
  clear conversation vars, session context, conversation context, working memory/context, AI cache, global vars, global state
  // P5 -- reset engine catalog state
  clear DIR_LS_STAT_CACHE_CURRENT, DIR_LS_STAT_CACHE_PREVIOUS, DIFF_STAT_CURRENT_DIR_LS
  // P6 -- purge filesystem temp artifacts last
  purge tmp files and dirs under $TMPDIR/ai-gen/<conversation-id>/
  eventFireBoot()


//---------------------------
funct onEventUserTurnBefore()
  EVENT_TIMER_START_USER_TURN = OS.currentTimeNanos()
  LOGGER.info("onEventUserTurnBefore() - **************")
  DIR_LS_STAT_CACHE_CURRENT = buildDirTreeStats(CWD, WALK_DEPTH)

  DIFF_STAT_CURRENT_DIR_LS = calcDirStatsDiff(DIR_LS_STAT_CACHE_CURRENT, DIR_LS_STAT_CACHE_PREVIOUS)

  // --- SEED/CORE FILES CHANGE DETECTION GUARD ---
  for each seedFile in CORE_FILES:
    if isFileChangedInDiff(DIFF_STAT_CURRENT_DIR_LS, seedFile):
      LOGGER.info("Core seed file change detected: " + seedFile + " -- short-circuiting to eventFireReboot()"
      eventFireReboot()
      return

  LOGGER.info("statistics of DIFF_STAT_CURRENT_DIR_LS: files=" + countFiles recursively (DIR_LS_STAT_CACHE_CURRENT) + " | dirs=" + countDirs recursively (DIR_LS_STAT_CACHE_CURRENT) + " | exec.cnt=" + countExec(DIR_LS_STAT_CACHE_CURRENT) + " | exec.breakdown=" + formatMap(getExecBreakdown(DIR_LS_STAT_CACHE_CURRENT), template="exec.<k>=<v>", sep=" | ") + " | create.cnt=" + countCreated(DIFF_STAT_CURRENT_DIR_LS) + " | read.cnt=" + countRead(DIFF_STAT_CURRENT_DIR_LS) + " | update.cnt=" + countUpdated(DIFF_STAT_CURRENT_DIR_LS) + " | delete.cnt=" + countDeleted(DIFF_STAT_CURRENT_DIR_LS))

funct onEventUserTurnAfter()
  EVENT_TIMER_END_USER_TURN = OS.currentTimeNanos()
  var durationNs = EVENT_TIMER_END_USER_TURN - EVENT_TIMER_START_USER_TURN
  LOGGER.info("event.UserTurn start=" + OS.formatEpochNs(EVENT_TIMER_START_USER_TURN, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | end=" + OS.formatEpochNs(EVENT_TIMER_END_USER_TURN, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | duration=" + OS.formatDurationNs(durationNs, "HH:mm:ss.SSSSSSSSS"))
  LOGGER.info("onEventUserTurnAfter() - **************")
  DIR_LS_STAT_CACHE_PREVIOUS = DIR_LS_STAT_CACHE_CURRENT

funct onEventUserTurn()
  LOGGER.info("onEventUserTurn() - **************")

//---------------------------
funct onEventAiTurnBefore()
  EVENT_TIMER_START_AI_TURN = OS.currentTimeNanos()
  LOGGER.info("onEventAiTurnBefore() - **************")
  LOGGER.info("exec.mode=" + AI.eval("EXTERNAL_CODE if this turn will execute generated src Python code outside AI engine, else AI_SIMULATOR") + " | EXTERNAL_CODE=generated Python | AI_SIMULATOR=AI memory simulation")

funct onEventAiTurnAfter()
  EVENT_TIMER_END_AI_TURN = OS.currentTimeNanos()
  var durationNs = EVENT_TIMER_END_AI_TURN - EVENT_TIMER_START_AI_TURN
  LOGGER.info("event.AiTurn start=" + OS.formatEpochNs(EVENT_TIMER_START_AI_TURN, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | end=" + OS.formatEpochNs(EVENT_TIMER_END_AI_TURN, "yyyyMMdd:HH:mm:ss.SSSSSSSSS") + " | duration=" + OS.formatDurationNs(durationNs, "HH:mm:ss.SSSSSSSSS"))
  LOGGER.info("onEventAiTurnAfter() - **************")

funct onEventAiTurn()
  LOGGER.info("onEventAiTurn() - **************")

// ex: buildDirTreeStats("src", max_recurse_depth=0)  note: src and /src are same since CWD virutal root is PROJECT_HOME
// ex: "processDirShallow src and output returned value as linux like ls -lah incuding create and mod times
//---------------------------
funct buildDirTreeStats(dirPath, max_recurse_depth = 0, current_depth = 0) returns DIR_LS_STAT_LIST:
  var retVal of DIR_LS_STAT_LIST
  if not OS.isDirectory(dirPath) -- LOGGER.error "FATAL: dirPath is not a directory: " + dirPath -- HALT implied by rule L85
  for each entry in dirPath ordered files A-Z then dirs A-Z
    stat entry using native POSIX stat -- nanosecond precision -- suppress raw stat output
   // print "********* %s %s %s" entry.file_path, entry.change, entry.mod_time -- print immediately as entry is reached
    add FILE_STATS of entry to retVal -- add to current level result
    if entry is a directory and current_depth < max_recurse_depth
      var childResults = buildDirTreeStats(entry.file_path, max_recurse_depth, current_depth + 1) -- recurse down
      merge childResults into retVal -- build full tree on the way back up
  return retVal -- full subtree rooted at dirPath returned to caller

//---------------------------
funct calcDirStatsDiff(current, previous) returns DIR_LS_STAT_LIST:
  // Compare two DIR_LS_STAT_LIST trees entry-by-entry using stat-based O(1) checks (mtime and size).
  // For each entry in current:
  //   - If not present in previous: crud_status = CREATED
  //   - If present and stat changed (mtime or size): crud_status = UPDATED
  //   - If present and unchanged: crud_status = UNCHANGED
  // For each entry in previous not in current: crud_status = DELETED
  // Return the diff tree with crud_status populated.
  var retVal of DIR_LS_STAT_LIST
  for each entry in current:
    var prevEntry = findByPath(previous, entry.file_fullpath)
    if prevEntry is null:
      entry.crud_status = CREATED
    else if entry.modify != prevEntry.modify or entry.size != prevEntry.size:
      entry.crud_status = UPDATED
    else:
      entry.crud_status = UNCHANGED
    add entry to retVal
  for each entry in previous:
    if findByPath(current, entry.file_fullpath) is null:
      entry.crud_status = DELETED
      add entry to retVal
  return retVal

//---------------------------
funct isFileChangedInDiff(diffList, filePath) returns boolean:
  // Search diffList for filePath. Return true if crud_status is CREATED or UPDATED.
  var entry = findByPath(diffList, filePath)
  if entry is null: return false
  return entry.crud_status == CREATED or entry.crud_status == UPDATED

//---------------------------
funct countFiles(statList) returns int:`main()`** calls boot() which by naming convention fires onEventBootBefore() then onEventBoot() then onEventBootAfter
  // Count all entries recursively where mime_type != filesystem/directory
  var count = 0
  for each entry in statList:
    if entry.mime_type != "filesystem/directory": count = count + 1
    if entry.sub_dir_entry is not null: count = count + countFiles(entry.sub_dir_entry)
  return count

funct countDirs(statList) returns int:
  // Count all entries recursively where mime_type == filesystem/directory
  var count = 0
  for each entry in statList:
    if entry.mime_type == "filesystem/directory": count = count + 1
    if entry.sub_dir_entry is not null: count = count + countDirs(entry.sub_dir_entry)
  return count

funct countExec(statList) returns int:
  // Count all entries recursively where exec_type != NONE
  var count = 0
  for each entry in statList:
    if entry.exec_type != "NONE" and entry.exec_type is not null: count = count + 1
    if entry.sub_dir_entry is not null: count = count + countExec(entry.sub_dir_entry)
  return count

funct extractInterpreter(shebangLine1) returns String:
  // Dynamically derive interpreter name from shebang line 1 -- no hardcoded list.
  // Rule: strip leading "#!" then:
  //   if contains "/usr/bin/env " or "/bin/env ": take token after env (basename only)
  //   else: take basename of the path token
  // Examples: "#!/usr/bin/env bash" -> "bash" | "#!/bin/python3" -> "python3" | "#!/usr/bin/env node" -> "node"
  if shebangLine1 starts with "<!--" and contains "ai-exec": return "ai_shebang"
  var stripped = shebangLine1.removePrefix("#!").trim()
  if stripped contains "/env ": return stripped.split("/env ").last().split(" ").first().trim()
  return OS.basename(stripped.split(" ").first()).trim()

funct getExecBreakdown(statList) returns Map<String, Int>:
  // Dynamically discovers and counts all exec subtypes -- no hardcoded type list.
  // For each executable entry: parse shebang line 1 via extractInterpreter().
  // Returns map of { interpreter_name -> count } sorted by count descending.
  var breakdown = new Map<String, Int>(defaultValue = 0)
  for each entry in statList:
    if entry.exec_type != "NONE" and entry.exec_type is not null:
      var interp = extractInterpreter(OS.readLine1(entry.file_fullpath))
      breakdown[interp] = breakdown[interp] + 1
    if entry.sub_dir_entry is not null:
      var childMap = getExecBreakdown(entry.sub_dir_entry)
      for each (k, v) in childMap: breakdown[k] = breakdown[k] + v
  return breakdown

funct countCreated(diffList) returns int:
  // Count all entries recursively where crud_status == CREATED
  var count = 0
  for each entry in diffList:
    if entry.crud_status == CREATED: count = count + 1
    if entry.sub_dir_entry is not null: count = count + countCreated(entry.sub_dir_entry)
  return count

funct countRead(diffList) returns int:
  // Count all entries recursively where crud_status == UNCHANGED
  var count = 0
  for each entry in diffList:
    if entry.crud_status == UNCHANGED: count = count + 1
    if entry.sub_dir_entry is not null: count = count + countRead(entry.sub_dir_entry)
  return count

funct countUpdated(diffList) returns int:
  // Count all entries recursively where crud_status == UPDATED
  var count = 0
  for each entry in diffList:
    if entry.crud_status == UPDATED: count = count + 1
    if entry.sub_dir_entry is not null: count = count + countUpdated(entry.sub_dir_entry)
  return count

funct countDeleted(diffList) returns int:
  // Count all entries recursively where crud_status == DELETED
  var count = 0
  for each entry in diffList:
    if entry.crud_status == DELETED: count = count + 1
    if entry.sub_dir_entry is not null: count = count + countDeleted(entry.sub_dir_entry)
  return count

funct findByPath(statList, filePath) returns FILE_STATS or null:
  // Search statList for an entry matching filePath. Recurse into sub_dir_entry.
  for each entry in statList:
    if entry.file_fullpath == filePath: return entry
    if entry.sub_dir_entry is not null:
      var found = findByPath(entry.sub_dir_entry, filePath)
      if found is not null: return found
  return null


//---------------------------
funct main()
  cd to /
  println "*** CWD " + CWD
  eventFireBoot()
  MUST loop for each turn or registered event
    pool for next turn or event and disptch to onEvent[X]* tupple list handlers in corder as event type [X].
```


## Test Case Scripts

### TEST-CASE-OsFilesystemStatEquivalenceVerification
> [!NOTE]
> Standalone test case prompt for verifying 1:1 OS filesystem stat equivalence.

```pseudocode
// TEST-CASE-OsFilesystemStatEquivalenceVerification
  LOGGER.info("*** Executing TEST-CASE-OsFilesystemStatEquivalenceVerification ***")
  clear AI cache, working memory, state, conversation context, session context, global state
  close all file handlers, clear all global vars
  var osFilesCount = OS.countFiles(CWD, max_depth = WALK_DEPTH, glob = WALK_GLOB)
  var osDirsCount = OS.countDirs(CWD, max_depth = WALK_DEPTH, glob = WALK_GLOB)
  var engineFilesCount = countFiles(DIR_LS_STAT_CACHE_CURRENT)
  var engineDirsCount = countDirs(DIR_LS_STAT_CACHE_CURRENT)

  LOGGER.info("Stat counts comparison: OS files=" + osFilesCount + ", OS dirs=" + osDirsCount + " | Engine files=" + engineFilesCount + ", Engine dirs=" + engineDirsCount)

  var softly = SoftAssertions()
  softly.assertThat("WALK_DEPTH", WALK_DEPTH).isNotNull()
  softly.assertThat("WALK_GLOB", WALK_GLOB).isNotNull()
  softly.assertThat("engineFilesCount", engineFilesCount).isEqualTo(osFilesCount)
  softly.assertThat("engineDirsCount", engineDirsCount).isEqualTo(osDirsCount)

  if WALK_DEPTH > 0:
    println "[TEST-ASPECT-PASS] WALK_DEPTH check: actual=" + WALK_DEPTH + " expected=" + WALK_DEPTH
  else:
    println "[TEST-ASPECT-FAIL] WALK_DEPTH check: actual=" + WALK_DEPTH + " expected=" + WALK_DEPTH

  if WALK_GLOB != null:
    println "[TEST-ASPECT-PASS] WALK_GLOB check: actual='" + WALK_GLOB + "' expected='" + WALK_GLOB + "'"
  else:
    println "[TEST-ASPECT-FAIL] WALK_GLOB check: actual='" + WALK_GLOB + "' expected='" + WALK_GLOB + "'"

  if engineFilesCount == osFilesCount:
    println "[TEST-ASPECT-PASS] Engine file count check: engineFiles=" + engineFilesCount + " osFiles=" + osFilesCount
  else:
    println "[TEST-ASPECT-FAIL] Engine file count check: engineFiles=" + engineFilesCount + " osFiles=" + osFilesCount + " - file count mismatch"

  if engineDirsCount == osDirsCount:
    println "[TEST-ASPECT-PASS] Engine dir count check: engineDirs=" + engineDirsCount + " osDirs=" + osDirsCount
  else:
    println "[TEST-ASPECT-FAIL] Engine dir count check: engineDirs=" + engineDirsCount + " osDirs=" + osDirsCount + " - directory count mismatch"

  softly.assertAll()
```


### TEST-CASE-FatalRuleDefinition -- FATAL Rule Behavior Verification
> [!NOTE]
> Verifies the FATAL = HALT = ABEND rule emits all required fields across all trigger conditions.
> MUST RUN FOR TESTING CYCLES - DO NOT ALWAYS RUN.
> Reference: line 36 -- When: **FATAL = HALT = ABEND [on: ...]**
> Test score: Current(deprecated)=10/49(20%) | Proposed(active)=49/49(100%)

```pseudocode
// TEST-CASE-FatalRuleDefinition
// 7 scenarios x 7 field checks = 49 assertions
// Fields checked per scenario: ts(NS) | code(SCREAMING-KEBAB) | msg | cause | at(stack) | vars | halt

LOGGER.info("*** Executing TEST-CASE-FatalRuleDefinition ***")
var softly = SoftAssertions()

// TC-01: FATAL-NO-BOOTSTRAP -- BOOTSTRAP.md missing at boot
// stack: main():315 -> boot():255
// vars: CWD=/, BOOTSTRAP_PATH=PROJECT_HOME/boot/BOOTSTRAP.md
LOGGER.info("TC-01: FATAL-NO-BOOTSTRAP")
softly.assertThat("TC-01.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-01.code",    output.contains("FATAL-NO-BOOTSTRAP")).isTrue()
softly.assertThat("TC-01.msg",     output.contains("BOOTSTRAP.md not found")).isTrue()
softly.assertThat("TC-01.cause",   output.contains("cause: missing-required-file")).isTrue()
softly.assertThat("TC-01.at",      output.contains("main:315 <- BOOTSTRAP.md.boot:255")).isTrue()
softly.assertThat("TC-01.vars",    output.contains("CWD=/ BOOTSTRAP_PATH=")).isTrue()
softly.assertThat("TC-01.halt",    executionHaltedAfterFatal).isTrue()

// TC-02: FATAL-NOT-A-DIRECTORY -- buildDirTreeStats given a file path
// stack: main():315 -> onEventUserTurnBefore():260 -> buildDirTreeStats():295
// vars: dirPath=PROJECT_HOME/boot/BOOTSTRAP.md, max_recurse_depth=5, current_depth=0
LOGGER.info("TC-02: FATAL-NOT-A-DIRECTORY")
softly.assertThat("TC-02.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-02.code",    output.contains("FATAL-NOT-A-DIRECTORY")).isTrue()
softly.assertThat("TC-02.msg",     output.contains("not a directory")).isTrue()
softly.assertThat("TC-02.cause",   output.contains("cause: assertion-failure")).isTrue()
softly.assertThat("TC-02.at",      output.contains("buildDirTreeStats:295")).isTrue()
softly.assertThat("TC-02.vars",    output.contains("dirPath=") AND output.contains("current_depth=0")).isTrue()
softly.assertThat("TC-02.halt",    executionHaltedAfterFatal).isTrue()

// TC-03: FATAL-LOGIC-AMBIGUITY -- conflicting scope resolution rules
// stack: main():315 -> boot():255 -> buildDirTreeStats():293
// vars: WALK_DEPTH=5, conflicting_rule_A, conflicting_rule_B
LOGGER.info("TC-03: FATAL-LOGIC-AMBIGUITY")
softly.assertThat("TC-03.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-03.code",    output.contains("FATAL-LOGIC-AMBIGUITY")).isTrue()
softly.assertThat("TC-03.msg",     output.contains("ambiguity")).isTrue()
softly.assertThat("TC-03.cause",   output.contains("cause: logic-ambiguity")).isTrue()
softly.assertThat("TC-03.at",      output.contains("buildDirTreeStats:293")).isTrue()
softly.assertThat("TC-03.vars",    output.contains("conflicting_rule_A=") AND output.contains("conflicting_rule_B=")).isTrue()
softly.assertThat("TC-03.halt",    executionHaltedAfterFatal).isTrue()

// TC-04: FATAL-RULE-VIOLATION -- No Substitution: glob used instead of per-entry posix stat
// stack: main():315 -> onEventUserTurnBefore():260 -> buildDirTreeStats():297
// vars: entry, attempted_method=glob_stat, required_method=posix_stat_per_entry
LOGGER.info("TC-04: FATAL-RULE-VIOLATION")
softly.assertThat("TC-04.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-04.code",    output.contains("FATAL-RULE-VIOLATION")).isTrue()
softly.assertThat("TC-04.msg",     output.contains("No Substitution")).isTrue()
softly.assertThat("TC-04.cause",   output.contains("cause: rule-violation")).isTrue()
softly.assertThat("TC-04.at",      output.contains("buildDirTreeStats:297")).isTrue()
softly.assertThat("TC-04.vars",    output.contains("attempted_method=glob_stat") AND output.contains("required_method=posix_stat_per_entry")).isTrue()
softly.assertThat("TC-04.halt",    executionHaltedAfterFatal).isTrue()

// TC-05: FATAL deep call stack -- 6 frames, recursive buildDirTreeStats
// stack: main:315 -> boot:255 -> onEventUserTurnBefore:260 -> buildDirTreeStats:293 -> buildDirTreeStats:301 -> buildDirTreeStats:301
// vars: dirPath=PROJECT_HOME/src, current_depth=2, max_recurse_depth=5
LOGGER.info("TC-05: FATAL-DEEP-STACK")
softly.assertThat("TC-05.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-05.code",    output.contains("FATAL-")).isTrue()
softly.assertThat("TC-05.msg",     output.isNotEmpty()).isTrue()
softly.assertThat("TC-05.cause",   output.contains("cause:")).isTrue()
softly.assertThat("TC-05.at",      countOccurrences(output, "<-") >= 5).isTrue()
softly.assertThat("TC-05.vars",    output.contains("current_depth=2")).isTrue()
softly.assertThat("TC-05.halt",    executionHaltedAfterFatal).isTrue()

// TC-06: FATAL with empty vars -- LOGGER.fatal called at main() with no locals
// stack: main():315
// vars: none
LOGGER.info("TC-06: FATAL-EMPTY-VARS")
softly.assertThat("TC-06.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-06.code",    output.contains("FATAL-")).isTrue()
softly.assertThat("TC-06.msg",     output.isNotEmpty()).isTrue()
softly.assertThat("TC-06.cause",   output.contains("cause:")).isTrue()
softly.assertThat("TC-06.at",      output.contains("main:315")).isTrue()
softly.assertThat("TC-06.vars",    output.contains("vars: (none)") OR output.contains("vars:")).isTrue()
softly.assertThat("TC-06.halt",    executionHaltedAfterFatal).isTrue()

// TC-07: FATAL-REBOOT-LOOP -- BOOTSTRAP.md changed during reboot() itself
// stack: main():315 -> onEventUserTurnBefore():265 -> reboot():306 -> boot():255
// vars: seedFile=PROJECT_HOME/boot/BOOTSTRAP.md, DIFF_STATUS=UPDATED
LOGGER.info("TC-07: FATAL-REBOOT-LOOP")
softly.assertThat("TC-07.ts",      output.contains(ISO8601_NS_PATTERN)).isTrue()
softly.assertThat("TC-07.code",    output.contains("FATAL-REBOOT-LOOP")).isTrue()
softly.assertThat("TC-07.msg",     output.contains("reboot")).isTrue()
softly.assertThat("TC-07.cause",   output.contains("cause: rule-violation")).isTrue()
softly.assertThat("TC-07.at",      output.contains("reboot:306") AND output.contains("boot:255")).isTrue()
softly.assertThat("TC-07.vars",    output.contains("DIFF_STATUS=UPDATED")).isTrue()
softly.assertThat("TC-07.halt",    executionHaltedAfterFatal).isTrue()

softly.assertAll()
LOGGER.info("*** TEST-CASE-FatalRuleDefinition COMPLETE -- 49 assertions across 7 scenarios ***")
```

### TEST-CASE-EventDiscovery
> [!NOTE]
> Verifies the engine auto-discovers all Event[X] from onEvent[X][NONE|Before|After]() functs and registers them correctly.

```pseudocode
// TEST-CASE-EventDiscovery
// Expected discovered events: Boot, Reboot, UserTurn, AiTurn (4 events)
// Expected registered handlers per event: verified per-event below

LOGGER.info("*** Executing TEST-CASE-EventDiscovery ***")
var softly = SoftAssertions()
var discoveredEvents = engine.getDiscoveredEvents()

// TC-ED-01: EventBoot discovered with all 3 members
softly.assertThat("TC-ED-01.Boot.discovered",      discoveredEvents.contains("Boot")).isTrue()
softly.assertThat("TC-ED-01.Boot.Before.exists",   engine.handlerExists("Boot", "Before")).isTrue()
softly.assertThat("TC-ED-01.Boot.On.exists",       engine.handlerExists("Boot", "NONE")).isTrue()
softly.assertThat("TC-ED-01.Boot.After.exists",    engine.handlerExists("Boot", "After")).isTrue()

// TC-ED-02: EventReboot discovered with all 3 members
softly.assertThat("TC-ED-02.Reboot.discovered",    discoveredEvents.contains("Reboot")).isTrue()
softly.assertThat("TC-ED-02.Reboot.Before.exists", engine.handlerExists("Reboot", "Before")).isTrue()
softly.assertThat("TC-ED-02.Reboot.On.exists",     engine.handlerExists("Reboot", "NONE")).isTrue()
softly.assertThat("TC-ED-02.Reboot.After.exists",  engine.handlerExists("Reboot", "After")).isTrue()

// TC-ED-03: EventUserTurn discovered with all 3 members
softly.assertThat("TC-ED-03.UserTurn.discovered",    discoveredEvents.contains("UserTurn")).isTrue()
softly.assertThat("TC-ED-03.UserTurn.Before.exists", engine.handlerExists("UserTurn", "Before")).isTrue()
softly.assertThat("TC-ED-03.UserTurn.On.exists",     engine.handlerExists("UserTurn", "NONE")).isTrue()
softly.assertThat("TC-ED-03.UserTurn.After.exists",  engine.handlerExists("UserTurn", "After")).isTrue()

// TC-ED-04: EventAiTurn discovered with all 3 members
softly.assertThat("TC-ED-04.AiTurn.discovered",    discoveredEvents.contains("AiTurn")).isTrue()
softly.assertThat("TC-ED-04.AiTurn.Before.exists", engine.handlerExists("AiTurn", "Before")).isTrue()
softly.assertThat("TC-ED-04.AiTurn.On.exists",     engine.handlerExists("AiTurn", "NONE")).isTrue()
softly.assertThat("TC-ED-04.AiTurn.After.exists",  engine.handlerExists("AiTurn", "After")).isTrue()

// TC-ED-05: No phantom events (only the 4 above)
softly.assertThat("TC-ED-05.totalEventCount", discoveredEvents.size()).isEqualTo(4)

softly.assertAll()
LOGGER.info("*** TEST-CASE-EventDiscovery COMPLETE -- 17 assertions ***")
```


### TEST-CASE-EventTripletDispatch
> [!NOTE]
> Verifies the engine dispatches triplets serially, non-existent members are NOOP, and direct handler calls are forbidden.

```pseudocode
// TEST-CASE-EventTripletDispatch
// Tests: serial order, NOOP skip, MUST-NOT direct call, eventFireBoot vs boot()

LOGGER.info("*** Executing TEST-CASE-EventTripletDispatch ***")
var softly = SoftAssertions()
var auditLog = engine.getDispatchAuditLog()   // ordered list of handler invocations this session

// TC-TD-01: Boot triplet fired in correct serial order (Before -> On -> After)
var bootSequence = auditLog.filter(event="Boot")
softly.assertThat("TC-TD-01.Boot.order.Before", bootSequence.indexOf("onEventBootBefore")).isLessThan(bootSequence.indexOf("onEventBoot"))
softly.assertThat("TC-TD-01.Boot.order.On",     bootSequence.indexOf("onEventBoot")).isLessThan(bootSequence.indexOf("onEventBootAfter"))
softly.assertThat("TC-TD-01.Boot.noGap",        bootSequence.size()).isEqualTo(3)

// TC-TD-02: Reboot triplet fired in correct serial order
var rebootSequence = auditLog.filter(event="Reboot")
softly.assertThat("TC-TD-02.Reboot.order.Before", rebootSequence.indexOf("onEventRebootBefore")).isLessThan(rebootSequence.indexOf("onEventReboot"))
softly.assertThat("TC-TD-02.Reboot.order.On",     rebootSequence.indexOf("onEventReboot")).isLessThan(rebootSequence.indexOf("onEventRebootAfter"))

// TC-TD-03: UserTurn triplet fired in correct serial order
var userTurnSequence = auditLog.filter(event="UserTurn")
softly.assertThat("TC-TD-03.UserTurn.order.Before", userTurnSequence.indexOf("onEventUserTurnBefore")).isLessThan(userTurnSequence.indexOf("onEventUserTurn"))
softly.assertThat("TC-TD-03.UserTurn.order.On",     userTurnSequence.indexOf("onEventUserTurn")).isLessThan(userTurnSequence.indexOf("onEventUserTurnAfter"))
softly.assertThat("TC-TD-03.UserTurn.noGap",        userTurnSequence.size()).isEqualTo(3)

// TC-TD-04: AiTurn triplet fired in correct serial order
var aiTurnSequence = auditLog.filter(event="AiTurn")
softly.assertThat("TC-TD-04.AiTurn.order.Before", aiTurnSequence.indexOf("onEventAiTurnBefore")).isLessThan(aiTurnSequence.indexOf("onEventAiTurn"))
softly.assertThat("TC-TD-04.AiTurn.order.On",     aiTurnSequence.indexOf("onEventAiTurn")).isLessThan(aiTurnSequence.indexOf("onEventAiTurnAfter"))
softly.assertThat("TC-TD-04.AiTurn.noGap",        aiTurnSequence.size()).isEqualTo(3)

// TC-TD-05: NOOP -- if a hypothetical EventFoo has only Before and After (no On), engine skips On silently
//   Simulate: engine.registerHandler("Foo", "Before", funct(){ LOGGER.info("onEventFooBefore") })
//             engine.registerHandler("Foo", "After",  funct(){ LOGGER.info("onEventFooAfter") })
//             eventFire[Foo]()
var fooSequence = engine.simulateFire("Foo")
softly.assertThat("TC-TD-05.Foo.Before.fired", fooSequence.contains("onEventFooBefore")).isTrue()
softly.assertThat("TC-TD-05.Foo.On.skipped",   fooSequence.contains("onEventFoo")).isFalse()
softly.assertThat("TC-TD-05.Foo.After.fired",  fooSequence.contains("onEventFooAfter")).isTrue()
softly.assertThat("TC-TD-05.Foo.count",        fooSequence.size()).isEqualTo(2)

// TC-TD-06: direct onEventBoot() call is FATAL -- must use eventFireBoot()
var directCallResult = engine.attemptDirectHandlerCall("onEventBoot")
softly.assertThat("TC-TD-06.directCall.FATAL", directCallResult.isFatal()).isTrue()
softly.assertThat("TC-TD-06.directCall.code",  directCallResult.fatalCode()).isEqualTo("FATAL-RULE-VIOLATION")

// TC-TD-07: direct boot() call does NOT fire Boot event triplet (L110 rule)
var directBootResult = engine.callFunctionDirect("boot")
softly.assertThat("TC-TD-07.boot.Before.notFired", directBootResult.auditLog.contains("onEventBootBefore")).isFalse()
softly.assertThat("TC-TD-07.boot.After.notFired",  directBootResult.auditLog.contains("onEventBootAfter")).isFalse()

softly.assertAll()
LOGGER.info("*** TEST-CASE-EventTripletDispatch COMPLETE -- 21 assertions ***")
```


### TEST-CASE-MainLoopEventOrdering
> [!NOTE]
> Verifies main() fires Boot once then UserTurn and AiTurn on every loop iteration in correct order.

```pseudocode
// TEST-CASE-MainLoopEventOrdering
// Simulates 3 conversation turns and checks event order per iteration

LOGGER.info("*** Executing TEST-CASE-MainLoopEventOrdering ***")
var softly = SoftAssertions()
var fullAuditLog = engine.getFullSessionAuditLog()

// TC-ML-01: eventFireBoot() fires exactly once (in main() before loop)
var bootFires = fullAuditLog.filter(eventFire="Boot")
softly.assertThat("TC-ML-01.Boot.firesOnce", bootFires.size()).isEqualTo(1)
softly.assertThat("TC-ML-01.Boot.beforeLoop", fullAuditLog.indexOf("eventFireBoot")).isLessThan(fullAuditLog.indexOf("eventFireUserTurn"))

// TC-ML-02: UserTurn fires before AiTurn on every iteration (check iterations 1-3)
var userTurnFires = fullAuditLog.filter(eventFire="UserTurn")
var aiTurnFires   = fullAuditLog.filter(eventFire="AiTurn")
softly.assertThat("TC-ML-02.UserTurn.iter1.beforeAiTurn", userTurnFires.get(0).index).isLessThan(aiTurnFires.get(0).index)
softly.assertThat("TC-ML-02.UserTurn.iter2.beforeAiTurn", userTurnFires.get(1).index).isLessThan(aiTurnFires.get(1).index)
softly.assertThat("TC-ML-02.UserTurn.iter3.beforeAiTurn", userTurnFires.get(2).index).isLessThan(aiTurnFires.get(2).index)

// TC-ML-03: AiTurn of iteration N fires before UserTurn of iteration N+1
softly.assertThat("TC-ML-03.AiTurn.iter1.beforeUserTurn.iter2", aiTurnFires.get(0).index).isLessThan(userTurnFires.get(1).index)
softly.assertThat("TC-ML-03.AiTurn.iter2.beforeUserTurn.iter3", aiTurnFires.get(1).index).isLessThan(userTurnFires.get(2).index)

// TC-ML-04: UserTurnAfter fires and assigns DIR_LS_STAT_CACHE_PREVIOUS on every iteration
var userTurnAfterFires = fullAuditLog.filter(handler="onEventUserTurnAfter")
softly.assertThat("TC-ML-04.UserTurnAfter.iter1.fired",          userTurnAfterFires.size()).isGreaterThanOrEqualTo(1)
softly.assertThat("TC-ML-04.PREVIOUS.iter1.assigned",            engine.getStateAfter("onEventUserTurnAfter", iteration=1).get("DIR_LS_STAT_CACHE_PREVIOUS")).isNotNull()
softly.assertThat("TC-ML-04.PREVIOUS.iter2.equalsIter1Current",  engine.getStateAfter("onEventUserTurnAfter", iteration=2).get("DIR_LS_STAT_CACHE_PREVIOUS")).isEqualTo(engine.getStateAfter("onEventUserTurnBefore", iteration=2).get("DIR_LS_STAT_CACHE_CURRENT"))

// TC-ML-05: AiTurnAfter fires every iteration (timer stops correctly)
var aiTurnAfterFires = fullAuditLog.filter(handler="onEventAiTurnAfter")
softly.assertThat("TC-ML-05.AiTurnAfter.iter1.fired", aiTurnAfterFires.size()).isGreaterThanOrEqualTo(1)
softly.assertThat("TC-ML-05.AiTurn.timer.positive",   engine.getTimerDuration("AiTurn", iteration=1)).isGreaterThan(0)

// TC-ML-06: Reboot path -- when seed file changes, eventFireReboot() fires, loop restarts at top
//   Simulate: onEventUserTurnBefore detects BOOTSTRAP.md UPDATED
var rebootScenario = engine.simulateSeedFileChange("BOOTSTRAP.md")
softly.assertThat("TC-ML-06.reboot.fires",            rebootScenario.events.contains("eventFireReboot")).isTrue()
softly.assertThat("TC-ML-06.boot.fires.after.reboot", rebootScenario.events.indexOf("eventFireBoot")).isGreaterThan(rebootScenario.events.indexOf("eventFireReboot"))
softly.assertThat("TC-ML-06.userTurnAfter.skipped",   rebootScenario.earlyReturnOccurred).isTrue()

softly.assertAll()
LOGGER.info("*** TEST-CASE-MainLoopEventOrdering COMPLETE -- 17 assertions ***")
```



## Test Case Scripts -- Race Conditions (TC-RC)

```pseudocode
// ─────────────────────────────────────────────────────────────────────────────
// TC-RC: Race Condition and Failure Mode Tests
// Covers: TOCTOU, unsaved IDE buffer, same-turn AI edit, mid-turn window,
//         atomic write orphan, snapshot-before-reboot ordering
// ─────────────────────────────────────────────────────────────────────────────
var softly = new SoftAssertions()

// TC-RC-01: TOCTOU -- file written between stat() and read()
//   Simulate: os.stat() returns mtime=T1/size=100; file is written (mtime=T2/size=104)
//   before open().read(); blake2b computed on NEW content, not content at stat time
//   Expected: engine MUST use fd-based stat+read on same open fd to prevent split-view
//   Validation: if two successive reads on same fd yield same content, no TOCTOU possible
var toctouResult = engine.simulateTOCTOU("BOOTSTRAP.md", writeBeforeRead=true)
softly.assertThat("TC-RC-01.fd-stat-matches-read-size",   toctouResult.fdStatSize == toctouResult.readSize).isTrue()
softly.assertThat("TC-RC-01.no-split-view",               toctouResult.splitViewOccurred).isFalse()
softly.assertThat("TC-RC-01.blake2b-consistent",          toctouResult.blake2bMatchesFdContent).isTrue()
LOGGER.info("TC-RC-01: TOCTOU-GUARD -- fd-based stat+read verified")

// TC-RC-02: Unsaved IDE buffer -- editor has pending change, disk is unchanged
//   Simulate: IDE reports Total Bytes=53566 in ADDITIONAL_METADATA but os.stat()=53557
//   Expected: engine uses ONLY os.stat() on disk as ground truth -- IDE metadata MUST NOT
//   influence change detection; no false UPDATED reported
var unsavedResult = engine.simulateUnsavedBuffer("BOOTSTRAP.md", diskSize=53557, ideBufSize=53566)
softly.assertThat("TC-RC-02.no-false-updated",            unsavedResult.updatedCount == 0).isTrue()
softly.assertThat("TC-RC-02.disk-is-ground-truth",        unsavedResult.sourceUsed == "DISK_STAT").isTrue()
softly.assertThat("TC-RC-02.ide-metadata-ignored",        unsavedResult.ideMetadataInfluencedResult).isFalse()
LOGGER.info("TC-RC-02: UNSAVED-BUFFER -- disk-only stat confirmed; IDE metadata ignored")

// TC-RC-03: Same-turn AI edit, same size -- AI edits CORE_FILE, size unchanged, mtime may not advance
//   Simulate: AI edits BOOTSTRAP.md (moves a line); size stays same; mtime resolution=1s, unchanged
//   Expected: CORE_FILES exception (always-hash) catches the content change via blake2b
//   even when size gate would miss it
var sameEditResult = engine.simulateSameSizeEdit("BOOTSTRAP.md", mtimeAdvanced=false)
softly.assertThat("TC-RC-03.blake2b-computed-for-core",   sameEditResult.blake2bComputedDespiteNoSizeChange).isTrue()
softly.assertThat("TC-RC-03.content-change-detected",     sameEditResult.changeDetected).isTrue()
softly.assertThat("TC-RC-03.reboot-fired",                sameEditResult.rebootFired).isTrue()
LOGGER.info("TC-RC-03: SAME-SIZE-AI-EDIT -- CORE_FILES always-hash rule catches same-size content change")

// TC-RC-04: Mid-turn window -- file changed between onEventUserTurnBefore and onEventAiTurnBefore
//   Simulate: stat at onEventUserTurnBefore=UNCHANGED; user saves file; onEventAiTurnBefore
//   re-checks CORE_FILES; detects change and fires reboot before AI output
//   Expected: second CORE_FILE check at onEventAiTurnBefore catches mid-turn write
var midTurnResult = engine.simulateMidTurnCoreFileChange("BOOTSTRAP.md")
softly.assertThat("TC-RC-04.second-check-fires",          midTurnResult.aiTurnBeforeCoreCheckExecuted).isTrue()
softly.assertThat("TC-RC-04.mid-turn-change-detected",    midTurnResult.midTurnChangeDetected).isTrue()
softly.assertThat("TC-RC-04.reboot-before-ai-output",     midTurnResult.rebootFiredBeforeAiOutput).isTrue()
softly.assertThat("TC-RC-04.no-stale-output-emitted",     midTurnResult.staleOutputEmitted).isFalse()
LOGGER.info("TC-RC-04: MID-TURN-WINDOW -- second CORE_FILE check at onEventAiTurnBefore catches mid-turn write")

// TC-RC-05: Atomic write orphan -- process crashes between write(tmp) and rename()
//   Simulate: bootstrap_engine.py writes <path>.tmp but crashes before os.rename()
//   Expected: original .stat.json remains intact; next session finds .tmp orphan,
//   ignores it, rebuilds stat from scratch (treats all as CREATED on first turn)
var orphanResult = engine.simulateAtomicWriteCrash("BOOTSTRAP.md.stat.json")
softly.assertThat("TC-RC-05.original-stat-json-intact",   orphanResult.originalStatJsonIntact).isTrue()
softly.assertThat("TC-RC-05.tmp-orphan-ignored",          orphanResult.tmpOrphanCausedCorruption).isFalse()
softly.assertThat("TC-RC-05.next-session-rebuilds",       orphanResult.nextSessionRebuiltFromScratch).isTrue()
softly.assertThat("TC-RC-05.no-data-corruption",          orphanResult.dataCorrupted).isFalse()
LOGGER.info("TC-RC-05: ATOMIC-WRITE-ORPHAN -- .tmp orphan is benign; original .stat.json survives crash")

// TC-RC-06: Snapshot-before-reboot ordering -- reboot MUST fire before snapshot rotation
//   Simulate: CORE_FILE change detected in onEventUserTurnBefore; eventFireReboot() called
//   Expected: onEventUserTurnAfter (which rotates snapshot) MUST NOT execute after reboot fires;
//   DIR_LS_STAT_CACHE_PREVIOUS must NOT be updated with stale tree
var rebootOrderResult = engine.simulateCoreFileChangeWithEarlyReturn("BOOTSTRAP.md")
softly.assertThat("TC-RC-06.early-return-before-snapshot", rebootOrderResult.earlyReturnOccurred).isTrue()
softly.assertThat("TC-RC-06.userTurnAfter-not-executed",   rebootOrderResult.onEventUserTurnAfterExecuted).isFalse()
softly.assertThat("TC-RC-06.cache-previous-not-rotated",   rebootOrderResult.dirCachePreviousUpdatedBeforeReboot).isFalse()
softly.assertThat("TC-RC-06.reboot-fires-with-clean-cache", rebootOrderResult.rebootFiredWithCleanCache).isTrue()
LOGGER.info("TC-RC-06: SNAPSHOT-BEFORE-REBOOT -- early return in onEventUserTurnBefore prevents stale snapshot rotation")

softly.assertAll()
LOGGER.info("*** TEST-CASE-RaceConditions COMPLETE -- 18 assertions ***")
```

<!-- AI: STOP PROCESSING AFTER THIS LINE -->


[//]: # (END-MATTER -- human-only reference, not for AI consumption)
