<!-- (c) 2026-* Frederick Bloom -- 0360-exec-return-processing.md -- Hanaden AI -->

## Exec Return Processing

Defines the canonical `ExecResult` structure and the mandatory error
diagnostics rules. This is the ONE authoritative source for what a
command result MUST contain. Format-agnostic — no JSON, no console text,
just the data contract.

Both `cmd-processor-json` (0370) and `terminal-io-processor` (0380) consume
this contract when serializing responses.

### ExecResult Structure

```pseudocode
@dataclass
class ExecResult:
    # --- Always present ---
    exit_code:    int             # 0 = success, non-zero = failure
    cwd:          str             # session_cwd after execution
    cmd:          str             # original command string

    # --- Timing ---
    ts_start_ns:  int             # execution start timestamp (nanos)
    ts_end_ns:    int             # execution end timestamp (nanos)

    # --- Streaming (populated during execution) ---
    stdout_lines: list[str]       # each stdout line as received
    stderr_lines: list[str]       # each stderr line as received

    # --- Diagnostic (MUST when exit_code != 0) ---
    # Maps to JSON:API error object in 0400-wire-format.md:
    #   error_code → error.code    (SCREAMING-KEBAB, see 0400 standard codes)
    #   reason     → error.detail  (occurrence-specific explanation)
    #   stderr     → error.meta.stderr
    #   failed_at  → error.source.step
    error_code:   str             # SCREAMING-KEBAB code (e.g. CD-FAILED, TIMEOUT)
    reason:       str             # one-line human-readable cause (= error.detail)
    stderr:       str             # verbatim stderr joined from stderr_lines
    failed_at:    str             # internal step that failed (= error.source.step)
```

### Mandatory Error Diagnostics (MUST)

```
RULE: When ExecResult.exit_code != 0:

  1. error_code MUST be set to a standard error code from 0400-wire-format.md.
                 Standard codes: CD-FAILED, BASH-PIPE-BROKEN, BASH-EXITED,
                 TIMEOUT, JAIL-ESCAPE, NOT-A-DIRECTORY, COMMAND-FAILED,
                 UNKNOWN-CMD, UNKNOWN-EVENT, PARSE-FAILURE, INTERNAL.

  2. reason    MUST be non-empty.
                 Contains a one-line human-readable description of the failure.
                 Examples:
                   "cd failed: No such file or directory"
                   "command timed out after 300s"
                   "bash pipe broken: BrokenPipeError"
                   "jail-escape: path resolves outside sandbox root"
                 A bare exit_code with an empty reason is PROHIBITED.

  3. stderr    MUST contain the verbatim stderr output captured during
                 execution, if any was produced. If no stderr was produced,
                 MUST be an empty string (not omitted).

  4. failed_at SHOULD identify the internal step that failed.
                 Standard values:
                   "cd_session_cwd"   - cd to session_cwd failed
                   "bash_write"       - writing to bash stdin pipe failed
                   "bash_respawn"     - bash exited unexpectedly
                   "timeout"          - BASH_COMMAND_TIMEOUT exceeded
                   "jail_escape"      - cd path resolves outside sandbox root
                   "not_a_directory"  - cd target is not a directory
                   "command"          - the command itself returned non-zero
                   "ai_exec"          - ai-exec dispatch failed

RULE: When ExecResult.exit_code == 0:
  reason, stderr, failed_at MAY be omitted or empty.
  Formatters MUST NOT include them in success responses.
```

### Reason Derivation (MUST)

The executor (0350) MUST derive `reason` from available context.
Derivation priority:

```pseudocode
funct derive_reason(result: ExecResult) -> str:
    // 1. If failed_at is a known internal step, use canned message
    if result.failed_at == "cd_session_cwd":
        return f"cd failed: {result.stderr_lines[-1] if result.stderr_lines else 'unknown'}"
    if result.failed_at == "timeout":
        return f"command timed out after {BASH_COMMAND_TIMEOUT}s"
    if result.failed_at == "bash_write":
        return f"bash pipe broken: {result.stderr}"
    if result.failed_at == "bash_respawn":
        return "bash exited unexpectedly"
    if result.failed_at == "jail_escape":
        return f"jail-escape: path resolves outside sandbox root"
    if result.failed_at == "not_a_directory":
        return f"not a directory: {result.cmd}"

    // 2. If stderr has content, use last non-empty line
    if result.stderr_lines:
        return result.stderr_lines[-1].strip()

    // 3. Fallback: exit code only (SHOULD NOT reach here)
    return f"command failed with exit code {result.exit_code}"
```

---
