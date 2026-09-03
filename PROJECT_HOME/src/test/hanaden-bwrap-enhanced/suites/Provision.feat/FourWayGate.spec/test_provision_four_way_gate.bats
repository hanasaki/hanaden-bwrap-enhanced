#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_four_way_gate.bats -- Hanaden AI
# SPEC: Provision.feat/FourWayGate -- SCOPE four-way gate contract
# REF:  SCOPE-very-narrow.md ### provision -- four-way gate table
#
# Gate contract:
#   root missing + provision called  -> CREATE skeleton, exit 0
#   root exists  + provision called  -> [FATAL] exit 2 (NOT idempotent)
#   root missing + provision absent  -> [FATAL] exit 2 (tested in start -- out of scope here)
#   root exists  + provision absent  -> n/a (caller uses start directly)
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    # Each test gets its own ephemeral working area
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

@test "PROV-GATE-001: root missing -> provision creates it, exit 0" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 0 ]
    [ -d "$root" ]
}

@test "PROV-GATE-002: root already exists -> [FATAL] exit 2" {
    local root="${WORK}/existing-root"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 2 ]
}

@test "PROV-GATE-003: root already exists -> output contains [FATAL]" {
    local root="${WORK}/existing-root"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [[ "$output" == *"[FATAL]"* ]]
}

@test "PROV-GATE-004: root already exists -> output mentions the root path" {
    local root="${WORK}/existing-root"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [[ "$output" == *"$root"* ]]
}

@test "PROV-GATE-005: provision is NOT idempotent -- running twice on same root -> exit 2" {
    local root="${WORK}/once-only"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 0 ]
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 2 ]
}

@test "PROV-GATE-006: root is a file not a dir -> [FATAL] exit 2" {
    local root="${WORK}/is-a-file"
    touch "$root"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 2 ]
    [[ "$output" == *"[FATAL]"* ]]
}
