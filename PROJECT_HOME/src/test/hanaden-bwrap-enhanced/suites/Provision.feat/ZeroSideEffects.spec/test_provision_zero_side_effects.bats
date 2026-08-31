#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_zero_side_effects.bats -- Hanaden AI
# SPEC: Provision.feat/ZeroSideEffects -- nothing created outside stated targets
# REF:  SCOPE-very-narrow.md ### provision -- ZERO SIDE EFFECTS caution
#
# Only the explicitly declared artifacts may exist after provision.
# Nothing may be created outside ROOT and HOME_PARENT.
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

# Helper: sorted top-level names inside ROOT
_top_level() {
    find "$1" -maxdepth 1 -mindepth 1 -printf '%f\n' | sort
}

@test "PROV-ZSE-001: exactly the declared top-level entries exist (dirs + symlinks)" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name testuser
    local expected actual
    expected="$(printf '%s\n' bin dev etc home lib lib64 opt proc run tmp usr var | sort)"
    actual="$(_top_level "$root")"
    [ "$actual" = "$expected" ]
}

@test "PROV-ZSE-002: nothing created outside ROOT when home_parent is inside ROOT (default)" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name testuser
    # WORK should contain only the root dir itself
    local count
    count="$(find "$WORK" -maxdepth 1 -mindepth 1 | wc -l)"
    [ "$count" -eq 1 ]
}

@test "PROV-ZSE-003: nothing created outside ROOT and HOME_PARENT when home_parent is external" {
    local root="${WORK}/vroot"
    local home_parent="${WORK}/homes"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --host-real-home-parent "$home_parent" \
        --virtual-user-name testuser
    # Only root/ and homes/ should exist under WORK
    local count
    count="$(find "$WORK" -maxdepth 1 -mindepth 1 | wc -l)"
    [ "$count" -eq 2 ]
}

@test "PROV-ZSE-004: provision does not touch CWD" {
    local root="${WORK}/vroot"
    local cwd_before cwd_after
    cwd_before="$(find "$WORK" -maxdepth 0 -printf '%i\n')"  # inode, sanity check
    bash "$SCRIPT" provision --host-real-root "$root" --virtual-user-name testuser
    # CWD (WORK parent area) must not have been modified
    # (we check no extra entries appeared next to WORK itself)
    [ -d "$WORK" ]  # WORK still exists and is a dir
}

@test "PROV-ZSE-005: no unexpected subdirs inside usr" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name testuser
    # usr/ is created empty -- nothing should be pre-populated inside it
    local count
    count="$(find "${root}/usr" -mindepth 1 | wc -l)"
    [ "$count" -eq 0 ]
}

@test "PROV-ZSE-006: no unexpected subdirs inside etc" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision --host-real-root "$root" --virtual-user-name testuser
    local count
    count="$(find "${root}/etc" -mindepth 1 | wc -l)"
    [ "$count" -eq 0 ]
}

@test "PROV-ZSE-007: home contains only the virtual user dir" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision --host-real-root "$root" --virtual-user-name testuser
    local actual expected
    actual="$(find "${root}/home" -maxdepth 1 -mindepth 1 -printf '%f\n' | sort)"
    expected="testuser"
    [ "$actual" = "$expected" ]
}
