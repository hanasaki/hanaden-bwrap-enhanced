#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_symlinks.bats -- Hanaden AI
# SPEC: Fsck.feat/SymlinkChecks -- fsck checks #3/#4/#5: bin/lib/lib64 symlinks
# REF:  SCOPE-very-narrow.md ### fsck checks #3-5 -- auto-repairable
#
# Chaos: delete symlink, replace with wrong target, replace with file/dir.
# Verify detection and -a auto-repair restores correct relative target.
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

# ---- bin ---------------------------------------------------------------

@test "FSCK-SYML-001: deleting bin detected (exit 1 with -n)" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-002: deleting bin auto-repaired by -a (exit 2)" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -L "${ROOT}/bin" ]
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}

@test "FSCK-SYML-003: bin pointing to wrong target detected (exit 1 with -n)" {
    rm "${ROOT}/bin"
    ln -s /wrong/path "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-004: bin wrong target auto-repaired to usr/bin by -a" {
    rm "${ROOT}/bin"
    ln -s /wrong/path "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}

@test "FSCK-SYML-005: bin replaced with a plain file detected (exit 1 with -n)" {
    rm "${ROOT}/bin"
    touch "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-006: bin replaced with a plain file auto-repaired by -a" {
    rm "${ROOT}/bin"
    touch "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -L "${ROOT}/bin" ]
}

# ---- lib ---------------------------------------------------------------

@test "FSCK-SYML-007: deleting lib detected (exit 1 with -n)" {
    rm "${ROOT}/lib"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-008: deleting lib auto-repaired to usr/lib by -a" {
    rm "${ROOT}/lib"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -L "${ROOT}/lib" ]
    [ "$(readlink "${ROOT}/lib")" = "usr/lib" ]
}

@test "FSCK-SYML-009: lib wrong target detected (exit 1 with -n)" {
    rm "${ROOT}/lib"
    ln -s /bad "${ROOT}/lib"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-010: lib wrong target auto-repaired to usr/lib by -a" {
    rm "${ROOT}/lib"
    ln -s /bad "${ROOT}/lib"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ "$(readlink "${ROOT}/lib")" = "usr/lib" ]
}

# ---- lib64 -------------------------------------------------------------

@test "FSCK-SYML-011: deleting lib64 detected (exit 1 with -n)" {
    rm "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-012: deleting lib64 auto-repaired to usr/lib64 by -a" {
    rm "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ -L "${ROOT}/lib64" ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

@test "FSCK-SYML-013: lib64 wrong target detected (exit 1 with -n)" {
    rm "${ROOT}/lib64"
    ln -s /bad "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-SYML-014: lib64 wrong target auto-repaired to usr/lib64 by -a" {
    rm "${ROOT}/lib64"
    ln -s /bad "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

@test "FSCK-SYML-015: all 3 symlinks deleted -- -a repairs all, exit 2" {
    rm "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 2 ]
    [ "$(readlink "${ROOT}/bin")"   = "usr/bin"   ]
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

@test "FSCK-SYML-016: after -a symlink repair, second fsck exits 0" {
    rm "${ROOT}/bin" "${ROOT}/lib"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    # first fsck exits 2 (repaired) -- consumed by run above
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}
