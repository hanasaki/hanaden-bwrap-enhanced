#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_bitmap_exits.bats -- Hanaden AI
# SPEC: Fsck.feat/BitmapExits -- exit code bitmap contract
# REF:  SCOPE-very-narrow.md ### fsck exit codes
#   0  No errors
#   1  Errors found, NOT repaired
#   2  Errors found and repaired
#   4  Uncorrectable errors
#   8  Operational error (out of scope for pure-bash tests)
# OR-able: e.g. dirs missing + dirs repaired = 2, root missing = 4
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

@test "FSCK-BIT-001: clean root exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-BIT-002: missing dir with no repair mode exits 1" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-BIT-003: missing dir with -a exits 2" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
}

@test "FSCK-BIT-004: missing symlink with -a exits 2" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
}

@test "FSCK-BIT-005: root missing exits 4" {
    run bash "$SCRIPT" fsck --host-real-root "${WORK}/gone"
    [ "$status" -eq 4 ]
}

@test "FSCK-BIT-006: root is a file exits 4" {
    touch "${WORK}/afile"
    run bash "$SCRIPT" fsck --host-real-root "${WORK}/afile"
    [ "$status" -eq 4 ]
}

@test "FSCK-BIT-007: home/USER is a file exits 4" {
    rm -rf "${ROOT}/home/testuser"
    touch "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 4 ]
}

@test "FSCK-BIT-008: missing dir + missing symlink with no repair exits 1 (OR of 1|1=1)" {
    rm -rf "${ROOT}/proc"
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-BIT-009: missing dir + missing symlink with -a exits 2 (OR of 2|2=2)" {
    rm -rf "${ROOT}/proc"
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
}

@test "FSCK-BIT-010: missing user home with -a exits 1 (home not auto-repaired; 1|0=1)" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-BIT-011: missing dir (-a repairs) + missing user home (not repaired) exits 3 (OR 2|1)" {
    rm -rf "${ROOT}/proc"
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 3 ]
}

@test "FSCK-BIT-012: -n overrides -a (check only, no repairs, exit 1 on error)" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck -n -a --host-real-root "$ROOT" --virtual-user-name testuser
    # -n takes precedence: no repairs -> exit 1 not 2
    [ "$status" -eq 1 ]
    # AND the directory must NOT have been recreated
    [ ! -e "${ROOT}/proc" ]
}
