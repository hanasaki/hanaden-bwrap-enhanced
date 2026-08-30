#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bwrap_binary_present.bats -- Hanaden AI
# SPEC: BwrapBinaryPresent.spec -- bwrap binary MUST be on PATH
# TDD State: GREEN -- preflight_check() implemented
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

    # Create a minimal PATH directory that has common tools but NOT bwrap.
    # Only symlink the commands the script actually needs for preflight.
    SHADOW_DIR="$(mktemp -d)"
    local cmds=(bash printf id awk cat realpath mktemp head cut tr sed grep
                mkdir ln rm chmod date env command)
    for cmd in "${cmds[@]}"; do
        local src
        src="$(command -v "$cmd" 2>/dev/null || true)"
        [ -n "$src" ] && ln -sf "$src" "${SHADOW_DIR}/${cmd}" 2>/dev/null || true
    done
}

teardown() {
    [ -d "${SHADOW_DIR:-}" ] && rm -rf "$SHADOW_DIR"
}

# Helper: run script with a PATH that has no bwrap
_run_no_bwrap() {
    PATH="${SHADOW_DIR}:/usr/lib" bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
# PF-BIN-001: bwrap present on PATH -- script should NOT exit 2
# ---------------------------------------------------------------------------
@test "PF-BIN-001: bwrap present on PATH -- preflight passes" {
    command -v bwrap >/dev/null 2>&1 || skip "bwrap not installed on test host"
    run bash "$SCRIPT" --dry-run -- /bin/true
    [ "$status" -ne 2 ]
}

# ---------------------------------------------------------------------------
# PF-BIN-002: bwrap absent from PATH -- FATAL exit 2
# ---------------------------------------------------------------------------
@test "PF-BIN-002: bwrap absent from PATH -- FATAL exit 2" {
    run _run_no_bwrap -- /bin/true
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# PF-BIN-003: bwrap absent -- stderr contains FATAL
# ---------------------------------------------------------------------------
@test "PF-BIN-003: bwrap absent -- stderr contains [FATAL]" {
    run _run_no_bwrap -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
}

# ---------------------------------------------------------------------------
# PF-BIN-004: bwrap absent -- stderr contains hint with package name
# ---------------------------------------------------------------------------
@test "PF-BIN-004: bwrap absent -- stderr contains install hint" {
    run _run_no_bwrap -- /bin/true
    [[ "$output" == *"bubblewrap"* ]]
}
