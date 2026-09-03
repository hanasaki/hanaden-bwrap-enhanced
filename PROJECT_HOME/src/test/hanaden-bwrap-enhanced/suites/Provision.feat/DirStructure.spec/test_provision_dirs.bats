#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_dirs.bats -- Hanaden AI
# SPEC: Provision.feat/DirStructure -- skeleton directory creation
# REF:  SCOPE-very-narrow.md ### provision -- CREATES section
#
# CREATES dirs: usr etc home proc dev tmp run opt var
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    # Run provision once for the structure tests
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
}
teardown() {
    rm -rf "$WORK"
}

@test "PROV-DIRS-001: usr directory created" {
    [ -d "${ROOT}/usr" ]
}

@test "PROV-DIRS-002: etc directory created" {
    [ -d "${ROOT}/etc" ]
}

@test "PROV-DIRS-003: home directory created" {
    [ -d "${ROOT}/home" ]
}

@test "PROV-DIRS-004: proc directory created" {
    [ -d "${ROOT}/proc" ]
}

@test "PROV-DIRS-005: dev directory created" {
    [ -d "${ROOT}/dev" ]
}

@test "PROV-DIRS-006: tmp directory created" {
    [ -d "${ROOT}/tmp" ]
}

@test "PROV-DIRS-007: run directory created" {
    [ -d "${ROOT}/run" ]
}

@test "PROV-DIRS-008: opt directory created" {
    [ -d "${ROOT}/opt" ]
}

@test "PROV-DIRS-009: var directory created" {
    [ -d "${ROOT}/var" ]
}
