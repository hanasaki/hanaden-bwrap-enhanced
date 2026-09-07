#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_stderr_only_log.bats -- Hanaden AI
# SPEC: Dispatch.feat/StderrOnlyLog -- "All log output → stderr"
# REF:  SCOPE-very-narrow.md ### 1a. Log Level Contract
#   "All log output → stderr. Default level: INFO(400)."
#   This spec requirement means stdout must be clean for machine parsing
#   (e.g. --version, --dry-run output) while all [INFO], [WARN], [ERROR],
#   [FATAL], [DEBUG], [TRACE] tags go exclusively to stderr.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser 2>/dev/null
}
teardown() { rm -rf "$WORK"; }

# ---------------------------------------------------------------------------
# --version: stdout has version, stderr is empty or has only log tags
# ---------------------------------------------------------------------------

@test "LOG-STDERR-001: --version output on stdout contains version string" {
    local stdout_out
    stdout_out="$(bash "$SCRIPT" --version 2>/dev/null)"
    [[ "$stdout_out" == *"v0.4.1"* ]]
}

@test "LOG-STDERR-002: --version produces no [INFO] on stdout" {
    local stdout_out
    stdout_out="$(bash "$SCRIPT" --version 2>/dev/null)"
    [[ "$stdout_out" != *"[INFO]"* ]]
}

# ---------------------------------------------------------------------------
# provision: [INFO] messages go to stderr, not stdout
# ---------------------------------------------------------------------------

@test "LOG-STDERR-003: provision [INFO] appears on stderr not stdout" {
    rm -rf "$ROOT"
    local stdout_out stderr_out
    stdout_out="$(bash "$SCRIPT" provision --host-real-root "$ROOT" --virtual-user-name testuser 2>/dev/null)"
    # stdout should be empty (provision produces no stdout output)
    [ -z "$stdout_out" ]
}

@test "LOG-STDERR-004: provision [INFO] messages are on stderr" {
    rm -rf "$ROOT"
    local stderr_out
    stderr_out="$(bash "$SCRIPT" provision --host-real-root "$ROOT" --virtual-user-name testuser 2>&1 1>/dev/null)"
    [[ "$stderr_out" == *"[INFO]"* ]]
}

# ---------------------------------------------------------------------------
# fsck: [INFO] and [ERROR] both go to stderr
# ---------------------------------------------------------------------------

@test "LOG-STDERR-005: fsck stdout is empty on clean root" {
    local stdout_out
    stdout_out="$(bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser 2>/dev/null)"
    [ -z "$stdout_out" ]
}

@test "LOG-STDERR-006: fsck [INFO] appears on stderr" {
    local stderr_out
    stderr_out="$(bash "$SCRIPT" fsck -f --host-real-root "$ROOT" --virtual-user-name testuser 2>&1 1>/dev/null)"
    [[ "$stderr_out" == *"[INFO]"* ]]
}

@test "LOG-STDERR-007: fsck [ERROR] on broken root goes to stderr not stdout" {
    rm -rf "${ROOT}/usr"
    local stdout_out
    stdout_out="$(bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser 2>/dev/null)" || true
    [[ "$stdout_out" != *"[ERROR]"* ]]
}

@test "LOG-STDERR-008: fsck [ERROR] on broken root is on stderr" {
    rm -rf "${ROOT}/usr"
    local stderr_out
    stderr_out="$(bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser 2>&1 1>/dev/null)" || true
    [[ "$stderr_out" == *"[ERROR]"* ]]
}

# ---------------------------------------------------------------------------
# start --dry-run: bwrap argv on stderr, stdout clean
# ---------------------------------------------------------------------------

@test "LOG-STDERR-009: start --dry-run produces no [INFO] on stdout" {
    local stdout_out
    stdout_out="$(bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true 2>/dev/null)" || true
    [[ "$stdout_out" != *"[INFO]"* ]]
}

@test "LOG-STDERR-010: start --dry-run [DRY RUN] banner is on stderr" {
    local stderr_out
    stderr_out="$(bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true 2>&1 1>/dev/null)"
    [[ "$stderr_out" == *"[DRY RUN]"* ]]
}
