#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_newgidmap_present.bats -- Hanaden AI
# SPEC: NewgidmapPresent.spec -- newgidmap binary MUST be on PATH
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

    # Create shadow dir with REAL tools + DUMMY stubs for newuidmap/bwrap
    # so the preflight bwrap+newuidmap checks pass, isolating the newgidmap test
    SHADOW_DIR="$(mktemp -d)"
    local cmds=(bash printf id awk cat realpath mktemp head cut tr sed grep
                mkdir ln rm chmod date env command)
    for cmd in "${cmds[@]}"; do
        local src
        src="$(command -v "$cmd" 2>/dev/null || true)"
        [ -n "$src" ] && ln -sf "$src" "${SHADOW_DIR}/${cmd}" 2>/dev/null || true
    done

    # Stub bwrap: a real executable that passes command -v
    local real_bwrap
    real_bwrap="$(command -v bwrap 2>/dev/null || true)"
    if [ -n "$real_bwrap" ]; then
        ln -sf "$real_bwrap" "${SHADOW_DIR}/bwrap"
    else
        printf '#!/bin/sh\nexit 0\n' > "${SHADOW_DIR}/bwrap"
        chmod +x "${SHADOW_DIR}/bwrap"
    fi

    # Stub newuidmap: ensure command -v newuidmap passes
    local real_newuidmap
    real_newuidmap="$(command -v newuidmap 2>/dev/null || true)"
    if [ -n "$real_newuidmap" ]; then
        ln -sf "$real_newuidmap" "${SHADOW_DIR}/newuidmap"
    else
        printf '#!/bin/sh\nexit 0\n' > "${SHADOW_DIR}/newuidmap"
        chmod +x "${SHADOW_DIR}/newuidmap"
    fi

    # newgidmap intentionally NOT created in shadow dir
}

teardown() {
    [ -d "${SHADOW_DIR:-}" ] && rm -rf "$SHADOW_DIR"
}

_run_no_newgidmap() {
    PATH="${SHADOW_DIR}" bash "$SCRIPT" "$@" 2>&1
}

@test "PF-GID-001: newgidmap present on PATH -- preflight passes" {
    command -v bwrap >/dev/null 2>&1 || skip "bwrap not on test host"
    command -v newuidmap >/dev/null 2>&1 || skip "newuidmap not on test host"
    command -v newgidmap >/dev/null 2>&1 || skip "newgidmap not on test host"
    run bash "$SCRIPT" --dry-run -- /bin/true
    [ "$status" -ne 2 ]
}

@test "PF-GID-002: newgidmap absent from PATH -- FATAL exit 2" {
    run _run_no_newgidmap -- /bin/true
    [ "$status" -eq 2 ]
}

@test "PF-GID-003: newgidmap absent -- stderr contains [FATAL] with newgidmap" {
    run _run_no_newgidmap -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
    [[ "$output" == *"newgidmap"* ]]
}

@test "PF-GID-004: newgidmap absent -- stderr contains uidmap hint" {
    run _run_no_newgidmap -- /bin/true
    [[ "$output" == *"uidmap"* ]]
}
