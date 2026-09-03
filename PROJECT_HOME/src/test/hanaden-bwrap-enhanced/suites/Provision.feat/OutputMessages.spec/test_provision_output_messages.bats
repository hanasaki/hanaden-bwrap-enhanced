#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_output_messages.bats -- Hanaden AI
# SPEC: Provision.feat/OutputMessages -- verify output message content & stream
# REF:  SCOPE-very-narrow.md ### provision
#
# Tests: [INFO] messages, [FATAL] messages, stderr routing, stdout empty,
#        dry-run output content, [DEBUG] output, log-level suppression.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

# ---------------------------------------------------------------------------
# Successful provision messages
# ---------------------------------------------------------------------------

@test "PROV-OUT-001: success emits [INFO] creating skeleton on stderr" {
    local root="${WORK}/r1"
    local stderr_f="${WORK}/stderr_out"
    bash "$SCRIPT" provision --host-real-root "$root" 2>"$stderr_f" || true
    local stderr_content
    stderr_content="$(cat "$stderr_f")"
    [[ "$stderr_content" == *"[INFO]"* ]]
    [[ "$stderr_content" == *"provision: creating skeleton"* ]]
}

@test "PROV-OUT-002: success emits [INFO] provision: done on stderr" {
    local root="${WORK}/r2"
    local stderr_f="${WORK}/stderr_out"
    bash "$SCRIPT" provision --host-real-root "$root" 2>"$stderr_f" || true
    local stderr_content
    stderr_content="$(cat "$stderr_f")"
    [[ "$stderr_content" == *"provision: done"* ]]
}

@test "PROV-OUT-003: creating skeleton message mentions exact root path" {
    local root="${WORK}/my-specific-root"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"$root"* ]]
}

@test "PROV-OUT-004: successful provision stdout is empty (all to stderr)" {
    local root="${WORK}/r4"
    local stdout_content
    stdout_content="$(bash "$SCRIPT" provision --host-real-root "$root" 2>/dev/null)"
    [ -z "$stdout_content" ]
}

# ---------------------------------------------------------------------------
# FATAL messages (existing root)
# ---------------------------------------------------------------------------

@test "PROV-OUT-005: [FATAL] on existing root mentions the root path" {
    local root="${WORK}/exists"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [[ "$output" == *"$root"* ]]
}

@test "PROV-OUT-006: [FATAL] on existing root goes to stderr (stdout empty)" {
    local root="${WORK}/exists2"
    mkdir -p "$root"
    local stdout_content
    stdout_content="$(bash "$SCRIPT" provision --host-real-root "$root" 2>/dev/null)" || true
    [ -z "$stdout_content" ]
}

# ---------------------------------------------------------------------------
# Error messages (unknown flag)
# ---------------------------------------------------------------------------

@test "PROV-OUT-007: unknown flag error goes to stderr (stdout empty)" {
    local stdout_content
    stdout_content="$(bash "$SCRIPT" provision --host-real-root "${WORK}/r" --badopt 2>/dev/null)" || true
    [ -z "$stdout_content" ]
}

@test "PROV-OUT-008: unknown flag emits text containing 'unknown option'" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --badopt 2>&1
    [[ "$output" == *"unknown option"* ]]
}

@test "PROV-OUT-009: unknown flag emits hint with 'Run:'" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --badopt 2>&1
    [[ "$output" == *"Run:"* ]]
}

# ---------------------------------------------------------------------------
# Dry-run output content
# ---------------------------------------------------------------------------

@test "PROV-OUT-010: dry-run mentions ALL 9 dirs in output" {
    local root="${WORK}/dry"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"usr"* ]]
    [[ "$output" == *"etc"* ]]
    [[ "$output" == *"home"* ]]
    [[ "$output" == *"proc"* ]]
    [[ "$output" == *"dev"* ]]
    [[ "$output" == *"tmp"* ]]
    [[ "$output" == *"run"* ]]
    [[ "$output" == *"opt"* ]]
    [[ "$output" == *"var"* ]]
}

@test "PROV-OUT-011: dry-run mentions ALL 3 symlinks" {
    local root="${WORK}/dry2"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"ln -sfn"* ]] || [[ "$output" == *"bin"* ]]
    [[ "$output" == *"usr/bin"* ]]
    [[ "$output" == *"usr/lib"* ]]
    [[ "$output" == *"usr/lib64"* ]]
}

@test "PROV-OUT-012: dry-run mentions the virtual user home path" {
    local root="${WORK}/dry3"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run 2>&1
    [[ "$output" == *"sandbox_user"* ]]
}

@test "PROV-OUT-013: dry-run mentions the exact root path" {
    local root="${WORK}/dry-specific-path"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run 2>&1
    [[ "$output" == *"$root"* ]]
}

# ---------------------------------------------------------------------------
# DEBUG output
# ---------------------------------------------------------------------------

@test "PROV-OUT-014: --log-level DEBUG emits [DEBUG] lines for dirs" {
    local root="${WORK}/dbg1"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level DEBUG 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DEBUG]"* ]]
    [[ "$output" == *"provision: created"* ]]
}

@test "PROV-OUT-015: --log-level DEBUG emits [DEBUG] lines for symlinks" {
    local root="${WORK}/dbg2"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level DEBUG 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"provision: symlink"* ]]
}

# ---------------------------------------------------------------------------
# Log-level suppression
# ---------------------------------------------------------------------------

@test "PROV-OUT-016: --log-level FATAL on success stdout is empty" {
    local root="${WORK}/fatal1"
    local stdout_content
    stdout_content="$(bash "$SCRIPT" provision --host-real-root "$root" --log-level FATAL 2>/dev/null)"
    [ -z "$stdout_content" ]
}

@test "PROV-OUT-017: --log-level FATAL on success stderr is empty" {
    local root="${WORK}/fatal2"
    local stderr_f="${WORK}/stderr_fatal"
    bash "$SCRIPT" provision --host-real-root "$root" --log-level FATAL 2>"$stderr_f"
    local stderr_content
    stderr_content="$(cat "$stderr_f")"
    [ -z "$stderr_content" ]
}

@test "PROV-OUT-018: --log-level INFO does NOT emit [DEBUG]" {
    local root="${WORK}/info1"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level INFO 2>&1
    [[ "$output" != *"[DEBUG]"* ]]
}

# ---------------------------------------------------------------------------
# Custom values in dry-run output
# ---------------------------------------------------------------------------

@test "PROV-OUT-019: dry-run with custom --virtual-user-name shows that name" {
    local root="${WORK}/dry-user"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --virtual-user-name myspecialuser --dry-run 2>&1
    [[ "$output" == *"myspecialuser"* ]]
}

@test "PROV-OUT-020: dry-run with custom --host-real-home-parent shows that path" {
    local root="${WORK}/dry-hp"
    local hp="${WORK}/my-custom-home-parent"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --host-real-home-parent "$hp" --dry-run 2>&1
    [[ "$output" == *"$hp"* ]]
}
