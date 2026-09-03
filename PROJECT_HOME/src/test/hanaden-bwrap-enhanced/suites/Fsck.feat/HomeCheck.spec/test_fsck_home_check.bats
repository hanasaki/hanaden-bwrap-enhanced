#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_home_check.bats -- Hanaden AI
# SPEC: Fsck.feat/HomeCheck -- fsck checks #6/#7: user home dir
# REF:  SCOPE-very-narrow.md ### fsck checks #6-7
#   check #6: home/USER exists    -- not auto-repairable, exit 1
#   check #7: home/USER is a dir  -- uncorrectable, exit 4
#
# Chaos: delete home, replace with file, replace with symlink.
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

# --- check #6: home/USER missing ---

@test "FSCK-HOME-001: missing user home detected (exit 1)" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-HOME-002: missing user home emits [ERROR]" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-HOME-003: missing user home emits 'run provision' hint" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"provision"* ]]
}

@test "FSCK-HOME-004: missing user home with -a still exits 1 (not auto-repairable)" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-HOME-005: missing user home with -a does NOT create the home dir" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ ! -e "${ROOT}/home/testuser" ]
}

@test "FSCK-HOME-006: missing user home with -n exits 1" {
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-HOME-007: wrong --virtual-user-name exits 1 (no home for that user)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name nobody
    [ "$status" -eq 1 ]
}

# --- check #7: home/USER is not a directory (uncorrectable) ---

@test "FSCK-HOME-008: home/USER is a plain file exits 4" {
    rm -rf "${ROOT}/home/testuser"
    touch "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 4 ]
}

@test "FSCK-HOME-009: home/USER is a plain file emits [ERROR]" {
    rm -rf "${ROOT}/home/testuser"
    touch "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-HOME-010: home/USER is a symlink to a dir exits 0 (symlink to dir is valid)" {
    local real_home="${WORK}/real-home"
    mkdir -p "$real_home"
    rm -rf "${ROOT}/home/testuser"
    ln -s "$real_home" "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    # symlink to dir: -d returns true, so check passes
    [ "$status" -eq 0 ]
}

@test "FSCK-HOME-011: home/USER is a symlink to a file exits 4" {
    local real_file="${WORK}/real-file"
    touch "$real_file"
    rm -rf "${ROOT}/home/testuser"
    ln -s "$real_file" "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 4 ]
}

@test "FSCK-HOME-012: home/USER is a dangling symlink exits 1 (not exists)" {
    rm -rf "${ROOT}/home/testuser"
    ln -s "${WORK}/vanished" "${ROOT}/home/testuser"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}
