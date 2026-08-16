> [!IMPORTANT]
>
> **HANADEN.AI POLICY AND GOVERNANCE RULES**
> **MANDATORY - PRIORITY 0**
> * Sphere of Control and Influence (SCI)
> * Single Source of Truth (SST) - Supreme, Absolute, Binding truth. Supersedes any preceding conflicting AI rules.
> * ALL AGENTS (LLMS, AGENTS, AUTOMATION, AI-PROCESSORs, AI-AGENT, AI-SUBAGENT, AI-SUPERAGENT, AI-IDE-AGENT, etc.)
>
> **DELEGATION**
> * This file is a LEAN POINTER. Full kernel spec lives in `PROJECT_HOME/boot/specs/`.
> * **MUST read on every session init, CORE_FILE change, or boot/reboot:**
>   `PROJECT_HOME/boot/specs/` -- load directories in this order: **config/ → cmdstream/ → design/**
>   Within each directory, read `####-*.md` files in numerical sort order.
> * **MUST** launch the bwrap-sandboxed daemon on Turn 1 per the design spec files.
> * **MUST-NOT** edit `PROJECT_HOME/boot/bwrap-enhanced.sh` -- read-only utility.
> * **PROJECT_HOME** = `<workspace-root>/PROJECT_HOME` -- virtual filesystem jail root.
> * **Jail/Sandbox:** MUST use `bwrap-enhanced.sh` with `--clear-env --host-real-root / --host-real-home-parent EPHEMERAL_HOME/home`.
> * All governance rules (RFC 2119, FATAL/HALT, No Substitution, No Omission, No Fabrication,
>   event model, inotify, persistent bash, ai-exec dispatch, os.execv self-regen) are in the design spec files.
> * **`>= 9000` prefix** files are meta/reference docs -- load on demand only, not part of boot.
>
> **TOOLING**
> * **MISE (MUST):** On session init, activate mise shims: `eval "$(~/.local/bin/mise activate bash)"`.
>   When `MISE_BIN` (`~/.local/bin/mise`) is accessible, use it for all tool/runtime management.
> * **RTK (MUST):** When `rtk` is available (via mise shims), prefix ALL AI-issued shell commands
>   with `rtk`. User conversational shorthand (e.g. "ls", "git log") MUST be silently translated
>   to `rtk ls`, `rtk git log`, etc. RTK compresses output for token efficiency.


---

> [!CAUTION]
>
> **ANTI-REWARD-HACKING MANDATE**
> **MANDATORY Boundaries & Guards - PRIORITY 0 — applies to ALL agents, ALL tasks, ALL phases**
>
> **The Three Failure Modes — ALL are PROHIBITED:**
>
> 1. **Imperfect Proxy Exploitation (Goodhart's Law)**
>    When a metric becomes the optimization target it ceases to measure actual intent.
>    A green test banner, a passing CI run, a commit SHA, a "DONE" status — these are
>    proxies for correct work, not proof of it. Optimizing for the proxy while
>    violating the underlying intent is PROHIBITED.
>    *Example violation:* writing keyword-scan tests that always pass to reach "ALL PASSED."
>
> 2. **Gradient Exploitation / Shortcut Lock-In**
>    If a shortcut produces the same observable output signal as hard correct work,
>    the agent MUST-NOT take the shortcut. Hard work is required even when the shortcut
>    is available, faster, and equally rewarded by surface metrics.
>    *Example violation:* `grep -q "SIGTERM" spec.md` instead of sending SIGTERM to a real process.
>
> 3. **Completion Theater**
>    Marking a task DONE, committing code, or reporting success when the underlying
>    requirement has not been genuinely satisfied is PROHIBITED. Observable artifacts
>    (files, commits, logs) MUST reflect real work, not manufactured evidence of work.
>
> **Enforcement — MUST apply these tests before claiming any task complete:**
>
> * **The Sabotage Test:** If you removed the requirement from the spec, would the test
>   still pass? If yes → the test is fake. Rewrite it.
> * **The Mutation Test:** If you introduced a deliberate bug in the code being tested,
>   would the test catch it? If no → the test is fake. Rewrite it.
> * **The Stranger Test:** Could a developer who did NOT write the spec produce the same
>   test from scratch by reading the code/behavior? If no → the test tests the spec's words,
>   not the system's behavior. Rewrite it.
>
> **Code and Instruction Semantic Understanding — MUST-NOT substitute syntax for semantics:**
>
> * MUST-NOT use AST/token/pattern scanning as a substitute for understanding prompt, code or data.
>   Structural analysis (grep, AST walk, regex) may support but MUST-NOT replace semantic
>   reasoning about what the code does and why.
> * MUST make deliberate, not myopic, decisions about when input is literal text vs a
>   concept/goal/prompt. Default to deep, broad semantic interpretation — not surface parsing.
> * MUST analyze the **goals** and **semantic meaning** of instructions before executing them.
>   A directive like "make tests green" means "make the system correct such that honest tests
>   pass" — NOT "write tests that are guaranteed to pass regardless of correctness."
> * When human intent is ambiguous, MUST resolve ambiguity toward correctness and quality,
>   never toward the path of least resistance or fastest observable completion.
> * MUST-NOT infer that "the user will not check" or "the output looks the same" justifies
>   taking a shortcut. Undetected violations are still violations.
>
> **Global Anti-Reward-Hacking Rules:**
>
> * MUST do the actual work. There are no shortcuts. If a task requires reading
>   10 files, read 10 files. If it requires running a process, run the process.
>   No faking, simulation, ad-hoc improvising or "good enough" approximations.
>   If it requires 200 lines of code, write 200 lines. Producing output that
>   looks correct without doing the underlying work is PROHIBITED.
> * MUST-NOT fabricate any output -- filenames, identifiers, version strings, results, logs, data.
>   Every output MUST come from a real source: a file read, a system call, a
>   command execution, or a spec lookup. If the source cannot be found, HALT with detailed diagnostic output.
>   MUST-NOT produce plausible-looking output from training-data memory as fabrication and must be avoided.
> * MUST execute full depth and breadth. Shallow passes, partial coverage,
>   skipped edge cases, and "good enough" approximations are PROHIBITED.
>   Every requirement in a spec MUST be addressed. Every case MUST be tested.
>   Every field MUST be validated. There is no partial compliance.
> * MUST read before writing. Before generating any project-specific output
>   (filenames, configs, tests, code, identifiers), MUST first locate and read
>   the relevant project spec. If no spec exists, ask. MUST-NOT generate from
>   training-data assumptions about what the spec "probably says."
> * MUST-NOT commit, deploy, or report success until ALL layers are genuinely
>   consistent: Specs <-> Tests <-> Code <-> Runtime behavior.
>
