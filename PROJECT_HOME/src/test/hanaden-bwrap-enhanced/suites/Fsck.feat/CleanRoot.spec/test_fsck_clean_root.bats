#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_clean_root.bats -- Hanaden AI
# SPEC: Fsck.feat/CleanRoot -- fsck on a clean provisioned root exits 0
# REF:  SCOPE-very-narrow.md ### fsck -- exit codes: 0 = no errors
#
# The canonical happy path: provision creates a correct root,
# fsck confirms it is correct.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    # Provision a clean root for all tests in this file
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
}
teardown() { rm -rf "$WORK"; }

@test "FSCK-CLEAN-001: clean provisioned root exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-CLEAN-002: clean root with positional ROOT_PATH exits 0" {
    run bash "$SCRIPT" fsck --virtual-user-name testuser "$ROOT"
    [ "$status" -eq 0 ]
}

@test "FSCK-CLEAN-003: clean root emits 'no errors found'" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"no errors found"* ]]
}

@test "FSCK-CLEAN-004: clean root with -v exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -v
    [ "$status" -eq 0 ]
}

@test "FSCK-CLEAN-005: clean root with -v emits [OK] for each check" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -v
    [[ "$output" == *"[OK]"* ]]
}

@test "FSCK-CLEAN-006: clean root with -n exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -n
    [ "$status" -eq 0 ]
}

@test "FSCK-CLEAN-007: clean root with -f exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f
    [ "$status" -eq 0 ]
}

@test "FSCK-CLEAN-008: clean root with -a exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -a
    [ "$status" -eq 0 ]
}
