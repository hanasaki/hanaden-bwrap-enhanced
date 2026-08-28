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

## Definitions
### RFC-2119 key words and terminologies.
* MUST (defines rules that must be 100% followed).
* MUST-NOT (defines rules that are 100% forbidden, denied, not allowed, not permissible).
* SHOULD (defines rules that should be followed if possible, ~80% required).
* SHOULD-NOT (defines rules that should be avoided if possible, ~80% forbidden, denied, not allowed, not permissible).
* MAY (optional - at the discretion of the current session AI agent).
* MUST / MUST-NOT take absolute precedence over SHOULD / SHOULD-NOT, which take precedence over MAY.
* **FATAL = HALT = ABEND:** Immediately stop all processing and print the FATAL message to the user console and log it to the log file with debug level and details (including the FATAL code and explanation). AI MUST-NOT continue, retry, or substitute after ABEND.

### HANADEN.Hybrid.UUIDv7 Identifier
* A human readable identifier string with standard UUIDv7 prefix.
#### Format:
```
YYYYMMDD-HHMMSS-uuuuuu-7xxx-Nxxx-xxxxxxxxxxxx-<slug>[-<NNN>].<class>[-<semver>].<ext>
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
| `.<class>` | Class descriptor | Required: Hanaden extension -- lowercase; ex: `lesson`, `design`, `spec`, `feat`, `fsm`, `decis`, `wi`, `bug`, `audit`, `plan`, `run`, `suite`, `delivery`, `timeline` |
| `-<semver>` | Semver | Optional: Hanaden extension -- hyphen-separated from class; semver format (ex: MAJOR.MINOR.PATCH, 1.2.3, 1.2.3-alpha, 1.2.3-beta, 1.2.3-rc) |
| `.<ext>` | File extension | Required: Hanaden extension -- lowercase; ex: `md`, `yaml`, `json`, `sh` |

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
* **No Substitution (MUST):** AI MUST-NOT replace, reimplement, approximate, merge, or degrade any defined function, struct, loop, or data flow with alternative approaches. The pseudocode definition IS the implementation. If a function defines per-entry POSIX stat with nanosecond precision, the AI MUST issue per-entry POSIX stat with nanosecond precision. Violation is FATAL.
* **No Omission (MUST):** AI MUST execute every defined function call, populate every struct field per its definition, iterate every loop to completion, and perform every variable assignment. Partial execution, deferred execution, and skipped operations are FATAL.
* **No Fabrication (MUST):** AI MUST-NOT emit output (LOGGER or console) for operations not actually executed, claim variables hold values never computed, or produce estimated/placeholder data. Every output line and every state claim MUST be the direct result: of actual execution. Violation is FATAL.

### RFC 2119 Modal Keywords (Rule: Scope of Application)
* RFC 2119 keywords (MUST, MUST-NOT) as defined in `## Definitions` apply throughout ALL rules, pseudo-code, and documentation in this project.

### AI DSL Language Definition - Domain Specific Languages Used in This Project
* This is an event-driven declarative system with Funct; entry-point Funct is `main()`.
* **Mermaid & Pseudocode Execution:** Treat as executable/data flow specification.
  * **In-session (default):** AI generates context-only simulation code (never persisted); chooses best language case-by-case from: Python, Rust, Go, Zig, Java.
  * **External (MAY):** AI may generate, compile if needed, and execute real code external to the AI engine for Mermaid diagrams and/or pseudocode; same language pool.
* MUST obey/follow - Java SLF4J `.log*()`, `.is*()` methods on `LOGGER` (any non-`.log*` method is FATAL).
* MUST obey/follow - Logback configuration from `logback.xml` and `logback-test.xml` (see below).
* LOGGER configuration is defined in `logback.xml` (production) and `logback-test.xml` (test). These files are the single source of truth for all LOGGER settings. See `# LOGGER Configuration` in the boot config section below.
* **LogLevel hierarchy:** `DEBUG < INFO < WARN < ERROR < FATAL`. Default: `WARN`.
  * MUST HALT after any log level of ERROR or FATAL.
* MUST obey/follow - formatting output (not LOGGER) per C lang only: `print`, `println`, `puts`, `printf`. Others are FATAL.
  * ALWAYS prints to CONSOLE; not filtered by Logback level; MUST output verbatim -- never summarize, omit, hide, or suppress.
  * MUST C style print, printf, puts, println must be direct to console. no logger no prefix. NO EXCEPTIONS. NO EXCEPTIONS.
* **Output Rendering:** ALL `LOGGER.log*()` and C-style console output MUST be rendered raw and verbatim in code-fenced console blocks. NO markdown, NO AI markup, NO escaping, NO summarizing, NO omitting, NO suppressing. What the code outputs is exactly what appears. Each file's output MUST be fully visible before processing the next file. NO EXCEPTIONS.
* **Event Handlers (convention for dispatching Events):** Strictly Before/After pairs: `onEvent<Name>Before()` and `onEvent<Name>After()`. Engine fires them automatically around the actual function call -- flow is: `onEvent<Name>Before()` → `<name>()` → `onEvent<Name>After()`.
  * MUST register all onEvent handlers at file load time using the Engine provided register function call. See # Event Handler Registration in the boot section below.
  * MUST-NOT call event handlers directly from other code.
  * EXAMPLE: `onEventBootBefore()` -- AI calls on event Boot before calling `boot()`.
  * EXAMPLE: `onEventBootAfter()` -- AI calls on event Boot after calling `boot()` has completed.

### Engine Entry Point Convention
* MUST auto register all onEvent handlers - DO NOT CALL THEM DIRECTLY.
* **`main()`** calsl boot() which by naming convention fires onEventBootBefore() then onBoot() then onEventBootAfter().

### Variable, Function Scoping and Parameter BindingWARN
* Scope hierarchy (innermost to outermost): `OS/Shell.ENV` < `AGENT.ENV` < `WORKSPACE.ENV` < `PROJECT.ENV` < `FILE.ENV` < `FUNCT`
* **Read**: resolves innermost to outermost scope chain.
* **Assign** (`var varname =`): mutates the nearest scope frame where declared; creates in current frame if undeclared.
* **`var varname =`**: force-creates a local shadow binding; hides outer variables; unloaded on scope exit.

### Token Economy and Memory
* Markdown is canonical (may contain YAML frontmatter, Mermaid, etc.). Load only files needed for the current task.
* MUST Retain/Keep: Details >= (ie: higher than)H2 (note H1>H2>H3>H4), bullet points level and summary of lower level bullet points all for navigation, index, search, and quick lookup and reference.

## Step 0 -- MANDATORY TURN GATE
> [!CAUTION]
> * MUST engine must deterine events and automaically invote onEvent[X]Before() -> onEvent[X]() -> onEvent[X]After()
> * MUST calling a method requires engeint to call BeforeEvent -> Method -> AfterEvent.
> * `onSessionTurn()` MUST run BEFORE any user-visible assistant output on EVERY turn (turn 1 via `main()`; turn N+ the engine calls `onSessionTurn()` directly).

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
- **flow_type preference**: prefer `UML-ACTIVITY-DIAGRAM`|`RAW-DATA`|`UML-MSC`|`UML-SEQUENCE-DIAGRAM`; fallback CONSTITUTION.mdWARN+`TREE`|`GRAPH`|`GRAPH-WITH-STATE`; exec_flow correctness above all
- **`LOGGER`** = session-scoped logger object. Default level `WARN`. Per-file override via `LOGGER.setLevel()`. Guards: `LOGGER.is*Enabled()`
- **AI-EXEC Shebang**: First line `<!-- #!ai-exec [params] -->` marks `.md` as AI-instructional; `flow_type=<type>` param is **advisory only**, captured from shebang match
- **OS Shebang**: First line `#!/...` marks `.sh` as OS-executable; MUST only exec if has `+x` permission currently set for the user at OS level.  never chmod, warn and skip if missing

# LOGGER Configuration
* Source of truth: `logback.xml` (production), `logback-test.xml` (test).
* Agents MUST NOT override or re-declare LOGGER config inline.CONSTITUTION.mdCONSTITUTION.md
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
struct FILE_STATS = same as Linux stat enriched with exec_type (OS_SHEBANG | AI_SHEBANG | default NONE), file_fullpath, front_matter_keyvals, crud_status (CREATED | DELETED | UPDATED | default value UNCHANGED), sub_dir_entry (required if mime_type is filesystem/directory : DIR_LS_STAT_LIST)

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

immutable var WALK_DEPTH = 5
immutable var WALK_GLOB = "*"
immutable var CORE_FILES = [PROJECT_HOME/boot/BOOTSTRAP.md, PROJECT_HOME/CONSTITUTION.md, PROJECT_HOME/README.md]
immutable var AI_EXEC_SHEBANG_REGEX = "^<!\-\-\\s*#!(?:/usr/bin/env\\s+)?ai-exec(?:\\s+(?P<params>[^-].*?))?\s*-->"
immutable var OS_SHEBANG_REGEX = "^#!/.*"

//---------------------------
funct onEventBootBefore()
  LOGGER.info("onEventBootBefore() - **************")

funct onEventBootAfter()
  LOGGER.info("onEventBootAfter() - **************")

funct onEventBoot()
  LOGGER.info("onEventBoot() - **************")
  LOGGER.info(<inxi_ai: "=== AI ENGINE ==="; AI.ENGINE.name+version; AI.MODEL.name+vendor; "=== AI SESSION ==="; AI.SESSION.conversationId; AI.SESSION.stepIndex; "=== TOOLCHAIN ==="; java+python3+git+docker --version>)

//---------------------------
funct onEventRebootBefore()
  LOGGER.info("onEventRebootBefore() - **************")

funct onEventRebootAfter()
  LOGGER.info("onEventRebootAfter() - **************")

funct onEventReboot()
  LOGGER.info("onEventReboot() - **************")

//---------------------------
funct boot()
  LOGGER.info("*** boot() - BOOTING HANADEN - Frederick Bloom ***")

//---------------------------
funct onEventUserTurnBefore()
  LOGGER.info("onEventUserTurnBefore() - **************")
  DIR_LS_STAT_CACHE_CURRENT = buildDirTreeStats(CWD, WALK_DEPTH)

  DIFF_STAT_CURRENT_DIR_LS = calcDirStatsDiff(DIR_LS_STAT_CACHE_CURRENT, DIR_LS_STAT_CACHE_PREVIOUS)

  // --- SEED/CORE FILES CHANGE DETECTION GUARD ---
  for each seedFile in CORE_FILES:
    if isFileChangedInDiff(DIFF_STAT_CURRENT_DIR_LS, seedFile):
      LOGGER.info("Core seed file change detected: " + seedFile + " -- short-circuiting to reboot()")
      reboot()
      return

  LOGGER.info("statistics of DIFF_STAT_CURRENT_DIR_LS: files=" + countFiles recursively (DIR_LS_STAT_CACHE_CURRENT) + " | dirs=" + countDirs recursively (DIR_LS_STAT_CACHE_CURRENT) + " | created=" + countCreated recursively (DIFF_STAT_CURRENT_DIR_LS) + " | updated=" + countUpdated recursively (DIFF_STAT_CURRENT_DIR_LS) + " | deleted=" + countDeleted recursively (DIFF_STAT_CURRENT_DIR_LS))

funct onEventUserTurnAfter()
  LOGGER.info("onEventUserTurnAfter() - **************")
  DIR_LS_STAT_CACHE_PREVIOUS = DIR_LS_STAT_CACHE_CURRENT

funct onEventUserTurn()
  LOGGER.info("onEventUserTurn() - **************")

//---------------------------
funct onEventAiTurnBefore()
  LOGGER.info("onEventAiTurnBefore() - **************")

funct onEventAiTurnAfter()
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
      merge childResults into retValboot gem flash 3.6 low -- build full tree on the way back up
  return retVal -- full subtree rooted at dirPath returned to caller

//---------------------------
funct reboot()
  println "*** === REBOOTING HANADEN - Frederick Bloom *** - stdout console"
  LOGGER.info("*** REBOOTING HANADEN - Frederick Bloom ***")
  clear AI cache, working memmory, state, converation context, session context, global state
  close all file handlers, clear all global vars, flush stdio, stdout, stderr, release console lock if acquired, stop all subprocesses and subagents
  boot()

//---------------------------
funct main()
  cd to /
  println "*** CWD: " + CWD
  boot()
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

<!-- AI: STOP PROCESSING AFTER THIS LINE -->
<!-- END-MATTER -- human-only reference, not for AI consumption -->
