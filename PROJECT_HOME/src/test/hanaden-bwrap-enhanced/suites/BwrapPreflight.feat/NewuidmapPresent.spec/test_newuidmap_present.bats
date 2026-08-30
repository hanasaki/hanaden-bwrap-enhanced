#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_newuidmap_present.bats -- Hanaden AI
# SPEC: NewuidmapPresent.spec -- newuidmap binary MUST be on PATH
# TDD State: RED -> GREEN
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

    # Create shadow dir with common tools but NOT newuidmap
    SHADOW_DIR="$(mktemp -d)"
    local cmds=(bash printf id awk cat realpath mktemp head cut tr sed grep
                mkdir ln rm chmod date env command bwrap)
    for cmd in "${cmds[@]}"; do
        local src
        src="$(command -v "$cmd" 2>/dev/null || true)"
        [ -n "$src" ] && ln -sf "$src" "${SHADOW_DIR}/${cmd}" 2>/dev/null || true
    done
    # Explicitly exclude newuidmap (do not symlink it)
}

teardown() {
    [ -d "${SHADOW_DIR:-}" ] && rm -rf "$SHADOW_DIR"
}

_run_no_newuidmap() {
    PATH="${SHADOW_DIR}" bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
@test "PF-UID-001: newuidmap present on PATH -- preflight passes" {
    command -v newuidmap >/dev/null 2>&1 || skip "newuidmap not on test host"
    run bash "$SCRIPT" --dry-run -- /bin/true
    [ "$status" -ne 2 ]
}

@test "PF-UID-002: newuidmap absent from PATH -- FATAL exit 2" {
    run _run_no_newuidmap -- /bin/true
    [ "$status" -eq 2 ]
}

@test "PF-UID-003: newuidmap absent -- stderr contains [FATAL]" {
    run _run_no_newuidmap -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
}

@test "PF-UID-004: newuidmap absent -- stderr contains uidmap" {
    run _run_no_newuidmap -- /bin/true
    [[ "$output" == *"uidmap"* ]]
}
