#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_log_level_contract.bats -- Hanaden AI
# SPEC: Dispatch.feat/LogLevelContract -- log level behavior
# REF:  SCOPE-very-narrow.md ### log levels
#   [ERROR] and [FATAL] are "always emitted regardless of log level"
#   All log output includes caller function:line for debuggability
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
}
teardown() { rm -rf "$WORK"; }

# --- ERROR always emitted regardless of log level ---

@test "LOG-LVL-001: --log-level FATAL still shows [ERROR] messages" {
    # Make a broken root so fsck emits [ERROR]
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck --log-level FATAL --host-real-root "$ROOT" --virtual-user-name testuser
    # [ERROR] must still appear even though threshold is FATAL
    [[ "$output" == *"[ERROR]"* ]]
}

@test "LOG-LVL-002: --log-level FATAL suppresses [INFO] messages" {
    # Clean root with -f so fsck runs deep checks and would emit [INFO]
    run bash "$SCRIPT" fsck -f --log-level FATAL --host-real-root "$ROOT" --virtual-user-name testuser
    # [INFO] must NOT appear at FATAL threshold
    [[ "$output" != *"[INFO]"* ]]
}

@test "LOG-LVL-003: --log-level FATAL suppresses [WARN] messages" {
    touch "${ROOT}/intruder"
    run bash "$SCRIPT" fsck -f --log-level FATAL --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" != *"[WARN]"* ]]
}

@test "LOG-LVL-004: --log-level ERROR still shows [ERROR] messages" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck --log-level ERROR --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[ERROR]"* ]]
}

@test "LOG-LVL-005: --log-level ERROR suppresses [INFO] messages" {
    run bash "$SCRIPT" fsck -f --log-level ERROR --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" != *"[INFO]"* ]]
}

# --- Caller location in log output ---

@test "LOG-LOC-001: log output contains caller function name" {
    # Run fsck which calls _info from cmd_fsck
    run bash "$SCRIPT" fsck -f --host-real-root "$ROOT" --virtual-user-name testuser
    # Output should contain a function name followed by a colon and a line number
    # e.g. [INFO] cmd_fsck:770 fsck: ...
    [[ "$output" =~ [A-Za-z_]+:[0-9]+ ]]
}

@test "LOG-LOC-002: [ERROR] output contains caller function name" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    # The [ERROR] line should also have caller info
    local error_line
    error_line="$(printf '%s\n' "$output" | grep '\[ERROR\]' | head -1)"
    [[ "$error_line" =~ [A-Za-z_]+:[0-9]+ ]]
}
