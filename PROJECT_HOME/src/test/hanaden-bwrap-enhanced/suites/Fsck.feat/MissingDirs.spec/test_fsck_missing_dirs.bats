#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_missing_dirs.bats -- Hanaden AI
# SPEC: Fsck.feat/MissingDirs -- fsck check #2: all 9 required dirs present
# REF:  SCOPE-very-narrow.md ### fsck checks #2 -- auto-repairable
#
# Chaos pattern: provision a clean root, delete one or more dirs,
# verify fsck detects and (with -a) repairs each one.
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
teardown() { rm -rf "$WORK"; }

# Helper: corrupt by removing a dir, run fsck -n, check exit 1
_chaos_missing_dir_detected() {
    local dir="$1"
    rm -rf "${ROOT:?}/${dir}"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

# Helper: corrupt by removing a dir, run fsck -a, check exit 2 and dir restored
_chaos_missing_dir_repaired() {
    local dir="$1"
    rm -rf "${ROOT:?}/${dir}"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/${dir}" ]
}

@test "FSCK-DIRS-001: removing usr detected by -n (exit 1)" {
    _chaos_missing_dir_detected usr
}
@test "FSCK-DIRS-002: removing etc detected by -n (exit 1)" {
    _chaos_missing_dir_detected etc
}
@test "FSCK-DIRS-003: removing proc detected by -n (exit 1)" {
    _chaos_missing_dir_detected proc
}
@test "FSCK-DIRS-004: removing dev detected by -n (exit 1)" {
    _chaos_missing_dir_detected dev
}
@test "FSCK-DIRS-005: removing tmp detected by -n (exit 1)" {
    _chaos_missing_dir_detected tmp
}
@test "FSCK-DIRS-006: removing run detected by -n (exit 1)" {
    _chaos_missing_dir_detected run
}
@test "FSCK-DIRS-007: removing opt detected by -n (exit 1)" {
    _chaos_missing_dir_detected opt
}
@test "FSCK-DIRS-008: removing var detected by -n (exit 1)" {
    _chaos_missing_dir_detected var
}

@test "FSCK-DIRS-009: -n on missing dir emits [ERROR]" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-DIRS-010: -a repairs missing usr (exit 2, dir restored)" {
    _chaos_missing_dir_repaired usr
}
@test "FSCK-DIRS-011: -a repairs missing etc (exit 2, dir restored)" {
    _chaos_missing_dir_repaired etc
}
@test "FSCK-DIRS-012: -a repairs missing tmp (exit 2, dir restored)" {
    _chaos_missing_dir_repaired tmp
}
@test "FSCK-DIRS-013: -a repairs missing run (exit 2, dir restored)" {
    _chaos_missing_dir_repaired run
}

@test "FSCK-DIRS-014: -a on missing dir emits repaired message" {
    rm -rf "${ROOT}/opt"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"repaired"* ]]
}

@test "FSCK-DIRS-015: -a repairs multiple missing dirs in one pass (exit 2)" {
    rm -rf "${ROOT}/proc" "${ROOT}/dev" "${ROOT}/tmp"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/proc" ]
    [ -d "${ROOT}/dev" ]
    [ -d "${ROOT}/tmp" ]
}

@test "FSCK-DIRS-016: after -a repair, second fsck exits 0 (clean again)" {
    rm -rf "${ROOT}/var"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    # first fsck exits 2 (repaired) -- already consumed by run above
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-DIRS-017: no repair mode on missing dir exits 1" {
    rm -rf "${ROOT}/opt"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}
