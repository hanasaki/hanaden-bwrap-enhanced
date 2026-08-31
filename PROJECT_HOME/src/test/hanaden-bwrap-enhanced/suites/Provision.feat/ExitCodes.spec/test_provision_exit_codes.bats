#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_exit_codes.bats -- Hanaden AI
# SPEC: Provision.feat/ExitCodes -- exit code contract
# REF:  SCOPE-very-narrow.md ### provision -- four-way gate table
#
# exit 0: skeleton created successfully
# exit 1: option parse / unknown flag error
# exit 2: [FATAL] -- root already exists (NOT idempotent gate)
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

@test "PROV-EXIT-001: successful provision exits 0" {
    local root="${WORK}/fresh"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 0 ]
}

@test "PROV-EXIT-002: provision on existing root exits 2" {
    local root="${WORK}/existing"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root"
    [ "$status" -eq 2 ]
}

@test "PROV-EXIT-003: unknown flag exits 1" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --no-such-flag
    [ "$status" -eq 1 ]
}

@test "PROV-EXIT-004: --help exits 0" {
    run bash "$SCRIPT" provision --help
    [ "$status" -eq 0 ]
}

@test "PROV-EXIT-005: -h exits 0" {
    run bash "$SCRIPT" provision -h
    [ "$status" -eq 0 ]
}

@test "PROV-EXIT-006: --dry-run exits 0 (no root check)" {
    local root="${WORK}/fresh"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [ "$status" -eq 0 ]
}

@test "PROV-EXIT-007: duplicate --host-real-root exits 1" {
    run bash "$SCRIPT" provision \
        --host-real-root "${WORK}/a" \
        --host-real-root "${WORK}/b"
    [ "$status" -eq 1 ]
}

@test "PROV-EXIT-008: duplicate --virtual-user-name exits 1" {
    run bash "$SCRIPT" provision \
        --host-real-root "${WORK}/r" \
        --virtual-user-name alice \
        --virtual-user-name bob
    [ "$status" -eq 1 ]
}

@test "PROV-EXIT-009: duplicate --host-real-home-parent exits 1" {
    run bash "$SCRIPT" provision \
        --host-real-root "${WORK}/r" \
        --host-real-home-parent "${WORK}/h1" \
        --host-real-home-parent "${WORK}/h2"
    [ "$status" -eq 1 ]
}

@test "PROV-EXIT-010: duplicate --log-level exits 1" {
    run bash "$SCRIPT" provision \
        --host-real-root "${WORK}/r" \
        --log-level INFO \
        --log-level DEBUG
    [ "$status" -eq 1 ]
}

@test "PROV-EXIT-011: duplicate --dry-run exits 1" {
    run bash "$SCRIPT" provision \
        --host-real-root "${WORK}/r" \
        --dry-run \
        --dry-run
    [ "$status" -eq 1 ]
}

@test "PROV-EXIT-012: invalid --log-level exits 1" {
    run bash "$SCRIPT" provision \
        --host-real-root "${WORK}/r" \
        --log-level NOTLEVEL
    [ "$status" -eq 1 ]
}
