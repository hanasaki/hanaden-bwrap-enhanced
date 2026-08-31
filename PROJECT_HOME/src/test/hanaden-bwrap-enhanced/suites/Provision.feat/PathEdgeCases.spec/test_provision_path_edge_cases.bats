#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_path_edge_cases.bats -- Hanaden AI
# SPEC: Provision.feat/PathEdgeCases -- unusual paths and edge cases
# REF:  SCOPE-very-narrow.md ### provision
#
# Tests: trailing slashes, deep nesting, external home parents,
#        relative paths, special chars in user names, multiple provisions.
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
# Trailing slash
# ---------------------------------------------------------------------------

@test "PROV-PATH-001: root with trailing slash exits 0 and creates structure" {
    local root="${WORK}/trail/"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${WORK}/trail/usr" ]
    [ -d "${WORK}/trail/etc" ]
    [ -L "${WORK}/trail/bin" ]
}

# ---------------------------------------------------------------------------
# Deep nesting (mkdir -p creates intermediate dirs)
# ---------------------------------------------------------------------------

@test "PROV-PATH-002: deeply nested root path exits 0 (mkdir -p)" {
    local root="${WORK}/a/b/c/d/e/root"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/usr" ]
    [ -d "${root}/var" ]
    [ -L "${root}/lib64" ]
}

# ---------------------------------------------------------------------------
# External home parent (outside root)
# ---------------------------------------------------------------------------

@test "PROV-PATH-003: --host-real-home-parent that doesn't exist yet gets created" {
    local root="${WORK}/r3"
    local hp="${WORK}/nonexistent-parent"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --host-real-home-parent "$hp" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${hp}/sandbox_user" ]
}

@test "PROV-PATH-004: external home parent creates home OUTSIDE root" {
    local root="${WORK}/r4"
    local hp="${WORK}/external-homes"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --host-real-home-parent "$hp" 2>&1
    [ "$status" -eq 0 ]
    # Home is at external location
    [ -d "${hp}/sandbox_user" ]
    # Root/home dir itself exists (skeleton dir) but the user is NOT there
    [ -d "${root}/home" ]
    [ ! -d "${root}/home/sandbox_user" ]
}

@test "PROV-PATH-005: deeply nested external home parent gets created" {
    local root="${WORK}/r5"
    local hp="${WORK}/deep/nest/path/homes"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --host-real-home-parent "$hp" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${hp}/sandbox_user" ]
}

# ---------------------------------------------------------------------------
# Relative paths
# ---------------------------------------------------------------------------

@test "PROV-PATH-006: relative root path (from CWD) exits 0" {
    # Create a unique subdir name so we can use relative path from WORK
    local relname="rel-root-$$"
    run bash -c "cd '$WORK' && bash '$SCRIPT' provision --host-real-root './$relname'" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${WORK}/${relname}/usr" ]
    [ -d "${WORK}/${relname}/etc" ]
}

# ---------------------------------------------------------------------------
# After external home parent: root/home still EXISTS but user NOT there
# ---------------------------------------------------------------------------

@test "PROV-PATH-007: external home parent -- root/home exists (skeleton) but user absent" {
    local root="${WORK}/r7"
    local hp="${WORK}/ext-hp"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --host-real-home-parent "$hp" 2>&1
    [ "$status" -eq 0 ]
    # Skeleton home dir created as part of 9-dir skeleton
    [ -d "${root}/home" ]
    # But user lives externally
    [ ! -d "${root}/home/sandbox_user" ]
    [ -d "${hp}/sandbox_user" ]
}

# ---------------------------------------------------------------------------
# Special characters in virtual-user-name
# ---------------------------------------------------------------------------

@test "PROV-PATH-008: user name with hyphen (my-user) exits 0" {
    local root="${WORK}/r8"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --virtual-user-name "my-user" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/my-user" ]
}

@test "PROV-PATH-009: user name with numbers (user42) exits 0" {
    local root="${WORK}/r9"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --virtual-user-name "user42" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/user42" ]
}

@test "PROV-PATH-010: user name with underscore (my_user) exits 0" {
    local root="${WORK}/r10"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --virtual-user-name "my_user" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/my_user" ]
}

# ---------------------------------------------------------------------------
# Multiple independent provisions
# ---------------------------------------------------------------------------

@test "PROV-PATH-011: two independent provisions to different roots both succeed" {
    local root1="${WORK}/root-a"
    local root2="${WORK}/root-b"
    run bash "$SCRIPT" provision --host-real-root "$root1" 2>&1
    [ "$status" -eq 0 ]
    run bash "$SCRIPT" provision --host-real-root "$root2" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root1}/usr" ]
    [ -d "${root2}/usr" ]
    [ -d "${root1}/home/sandbox_user" ]
    [ -d "${root2}/home/sandbox_user" ]
}

# ---------------------------------------------------------------------------
# Root path with double slash (normalization)
# ---------------------------------------------------------------------------

@test "PROV-PATH-012: root path with double slash exits 0" {
    local root="${WORK}//double-slash"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${WORK}/double-slash/usr" ]
}
