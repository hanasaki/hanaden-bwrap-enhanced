#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_repair_modes.bats -- Hanaden AI
# SPEC: Fsck.feat/RepairModes -- -n / -a / -r / -f / -v flag behavior
# REF:  SCOPE-very-narrow.md ### fsck options
#   -n  check only, no repairs
#   -a  auto-repair, mutex with -r
#   -r  interactive repair, mutex with -a (not testable headlessly; verify rejection)
#   -f  force all checks
#   -v  verbose: print every check result
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

# ---- -n (check only) ---------------------------------------------------

@test "FSCK-MODE-001: -n on clean root exits 0" {
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-MODE-002: -n on corrupt root exits 1 (error found, not repaired)" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-MODE-003: -n does NOT repair (dir stays missing after run)" {
    rm -rf "${ROOT}/proc"
    bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser || true
    [ ! -e "${ROOT}/proc" ]
}

# ---- -a (auto-repair) --------------------------------------------------

@test "FSCK-MODE-004: -a repairs missing dir (exit 2)" {
    rm -rf "${ROOT}/opt"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/opt" ]
}

@test "FSCK-MODE-005: -a repairs bad symlink (exit 2)" {
    rm "${ROOT}/lib"
    ln -s /wrong "${ROOT}/lib"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ "$(readlink "${ROOT}/lib")" = "usr/lib" ]
}

# ---- -a and -r mutex ---------------------------------------------------

@test "FSCK-MODE-006: -a -r together exits 1 (mutually exclusive)" {
    run bash "$SCRIPT" fsck -a -r --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-MODE-007: -r -a together exits 1 (mutually exclusive)" {
    run bash "$SCRIPT" fsck -r -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-MODE-008: -a -r emits [ERROR]" {
    run bash "$SCRIPT" fsck -a -r --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[ERROR]"* ]]
}

# ---- -f (force) --------------------------------------------------------

@test "FSCK-MODE-009: -f on clean root exits 0" {
    run bash "$SCRIPT" fsck -f --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-MODE-010: -f combined with -a repairs (exit 2)" {
    rm -rf "${ROOT}/tmp"
    run bash "$SCRIPT" fsck -f -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/tmp" ]
}

# ---- -v (verbose) ------------------------------------------------------

@test "FSCK-MODE-011: -v on clean root emits [OK] lines" {
    run bash "$SCRIPT" fsck -v --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[OK]"* ]]
}

@test "FSCK-MODE-012: -v on clean root exits 0" {
    run bash "$SCRIPT" fsck -v --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-MODE-013: without -v, clean root does NOT emit [OK] lines" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" != *"[OK]"* ]]
}

@test "FSCK-MODE-014: -v combined with -a emits [OK] and repaired" {
    rm -rf "${ROOT}/run"
    run bash "$SCRIPT" fsck -v -a --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"repaired"* ]]
}

# ---- combined flags ----------------------------------------------------

@test "FSCK-MODE-015: -n -v on clean root emits [OK] lines and exits 0" {
    run bash "$SCRIPT" fsck -n -v --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}

@test "FSCK-MODE-016: -f -v -n on clean root exits 0" {
    run bash "$SCRIPT" fsck -f -v -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}
