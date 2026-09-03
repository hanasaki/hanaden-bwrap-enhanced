#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_symlinks.bats -- Hanaden AI
# SPEC: Provision.feat/Symlinks -- bin/lib/lib64 symlink creation
# REF:  SCOPE-very-narrow.md ### provision -- CREATES: SYMLINKS
#
# CREATES symlinks: bin->usr/bin  lib->usr/lib  lib64->usr/lib64
# Symlinks MUST be relative (not absolute) so the vroot is portable.
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
teardown() {
    rm -rf "$WORK"
}

@test "PROV-LINK-001: bin is a symlink" {
    [ -L "${ROOT}/bin" ]
}

@test "PROV-LINK-002: bin points to usr/bin (relative)" {
    local target
    target="$(readlink "${ROOT}/bin")"
    [ "$target" = "usr/bin" ]
}

@test "PROV-LINK-003: lib is a symlink" {
    [ -L "${ROOT}/lib" ]
}

@test "PROV-LINK-004: lib points to usr/lib (relative)" {
    local target
    target="$(readlink "${ROOT}/lib")"
    [ "$target" = "usr/lib" ]
}

@test "PROV-LINK-005: lib64 is a symlink" {
    [ -L "${ROOT}/lib64" ]
}

@test "PROV-LINK-006: lib64 points to usr/lib64 (relative)" {
    local target
    target="$(readlink "${ROOT}/lib64")"
    [ "$target" = "usr/lib64" ]
}

@test "PROV-LINK-007: bin symlink target is NOT absolute" {
    local target
    target="$(readlink "${ROOT}/bin")"
    [[ "$target" != /* ]]
}

@test "PROV-LINK-008: lib symlink target is NOT absolute" {
    local target
    target="$(readlink "${ROOT}/lib")"
    [[ "$target" != /* ]]
}

@test "PROV-LINK-009: lib64 symlink target is NOT absolute" {
    local target
    target="$(readlink "${ROOT}/lib64")"
    [[ "$target" != /* ]]
}
