#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_chaos_integration.bats -- Hanaden AI
# SPEC: Fsck.feat/ChaosIntegration -- full lifecycle: provision -> verify -> corrupt -> check -> repair -> verify
# REF:  SCOPE-very-narrow.md ### provision, ### fsck
#
# Testing discipline:
#   - provision is called to bootstrap the root (it is the bootstrap tool; using it in fsck tests is valid)
#   - ALL post-provision and post-fsck assertions are raw filesystem primitives only:
#       [ -d ], [ -L ], [ ! -d ], readlink, find, stat
#   - NEVER call fsck to verify what provision did
#   - NEVER call provision to verify what fsck did
#
# Chaos engineering: intentionally corrupt specific parts of the provisioned root,
# then verify detection and repair at each step manually on the filesystem.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root    "$ROOT" \
        --virtual-user-name sandbox_user
}
teardown() { rm -rf "$WORK"; }

# ---------------------------------------------------------------------------
# Phase 1: Verify provision output with raw filesystem assertions only
# ---------------------------------------------------------------------------

@test "FSCK-CI-001: provision creates usr (raw)" {
    [ -d "${ROOT}/usr" ]
}
@test "FSCK-CI-002: provision creates etc (raw)" {
    [ -d "${ROOT}/etc" ]
}
@test "FSCK-CI-003: provision creates home (raw)" {
    [ -d "${ROOT}/home" ]
}
@test "FSCK-CI-004: provision creates proc (raw)" {
    [ -d "${ROOT}/proc" ]
}
@test "FSCK-CI-005: provision creates dev (raw)" {
    [ -d "${ROOT}/dev" ]
}
@test "FSCK-CI-006: provision creates tmp (raw)" {
    [ -d "${ROOT}/tmp" ]
}
@test "FSCK-CI-007: provision creates run (raw)" {
    [ -d "${ROOT}/run" ]
}
@test "FSCK-CI-008: provision creates opt (raw)" {
    [ -d "${ROOT}/opt" ]
}
@test "FSCK-CI-009: provision creates var (raw)" {
    [ -d "${ROOT}/var" ]
}
@test "FSCK-CI-010: provision creates bin -> usr/bin symlink (raw)" {
    [ -L "${ROOT}/bin" ]
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}
@test "FSCK-CI-011: provision creates lib -> usr/lib symlink (raw)" {
    [ -L "${ROOT}/lib" ]
    [ "$(readlink "${ROOT}/lib")" = "usr/lib" ]
}
@test "FSCK-CI-012: provision creates lib64 -> usr/lib64 symlink (raw)" {
    [ -L "${ROOT}/lib64" ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}
@test "FSCK-CI-013: provision creates sandbox_user home dir (raw)" {
    [ -d "${ROOT}/home/sandbox_user" ]
}
@test "FSCK-CI-014: exactly 12 top-level entries (9 dirs + 3 symlinks) (raw)" {
    local count
    count="$(find "$ROOT" -maxdepth 1 -mindepth 1 | wc -l)"
    [ "$count" -eq 12 ]
}
@test "FSCK-CI-015: bin symlink target is relative not absolute (raw)" {
    [[ "$(readlink "${ROOT}/bin")" != /* ]]
}

# ---------------------------------------------------------------------------
# Phase 2: Corrupt one dir -- fsck -n detects, does NOT repair (raw verify)
# ---------------------------------------------------------------------------

@test "FSCK-CI-016: remove usr -> fsck -n exits 1 (error detected)" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}
@test "FSCK-CI-017: remove usr -> fsck -n leaves usr missing (raw -- -n does NOT repair)" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ ! -d "${ROOT}/usr" ]
}
@test "FSCK-CI-018: remove etc -> fsck -n exits 1" {
    rm -rf "${ROOT}/etc"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}
@test "FSCK-CI-019: remove etc -> dir still missing after -n (raw)" {
    rm -rf "${ROOT}/etc"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ ! -d "${ROOT}/etc" ]
}
@test "FSCK-CI-020: remove bin symlink -> fsck -n exits 1 (detected)" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}
@test "FSCK-CI-021: remove bin symlink -> still missing after -n (raw -- not repaired)" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ ! -L "${ROOT}/bin" ]
}
@test "FSCK-CI-022: wrong bin target -> fsck -n exits 1 (detected)" {
    rm "${ROOT}/bin"
    ln -s "WRONG" "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}
@test "FSCK-CI-023: wrong bin target -> still wrong after -n (raw)" {
    rm "${ROOT}/bin"
    ln -s "WRONG" "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$(readlink "${ROOT}/bin")" = "WRONG" ]
}
@test "FSCK-CI-024: bin replaced with plain file -> fsck -n exits 1 (detected)" {
    rm "${ROOT}/bin"
    touch "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}
@test "FSCK-CI-025: bin replaced with plain file -> still a plain file after -n (raw)" {
    rm "${ROOT}/bin"
    touch "${ROOT}/bin"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ ! -L "${ROOT}/bin" ]
    [ -f "${ROOT}/bin" ]
}

# ---------------------------------------------------------------------------
# Phase 3: Corrupt -> fsck -a repairs -> raw verify clean state
# ---------------------------------------------------------------------------

@test "FSCK-CI-026: remove usr -> fsck -a exits 2 (repaired)" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$status" -eq 2 ]
}
@test "FSCK-CI-027: remove usr -> usr is restored after -a (raw)" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ -d "${ROOT}/usr" ]
}
@test "FSCK-CI-028: remove etc -> fsck -a exits 2 (repaired)" {
    rm -rf "${ROOT}/etc"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$status" -eq 2 ]
}
@test "FSCK-CI-029: remove etc -> etc is restored after -a (raw)" {
    rm -rf "${ROOT}/etc"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ -d "${ROOT}/etc" ]
}
@test "FSCK-CI-030: remove bin -> fsck -a exits 2 (repaired)" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$status" -eq 2 ]
}
@test "FSCK-CI-031: remove bin -> bin is a correct symlink after -a (raw)" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ -L "${ROOT}/bin" ]
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}
@test "FSCK-CI-032: wrong bin target -> fsck -a corrects target (raw)" {
    rm "${ROOT}/bin"
    ln -s "WRONG" "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}
@test "FSCK-CI-033: bin as plain file -> fsck -a replaces with correct symlink (raw)" {
    rm "${ROOT}/bin"
    touch "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ -L "${ROOT}/bin" ]
    [ "$(readlink "${ROOT}/bin")" = "usr/bin" ]
}
@test "FSCK-CI-034: remove lib and lib64 -> both repaired by -a (raw)" {
    rm "${ROOT}/lib" "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}
@test "FSCK-CI-035: remove 3 dirs simultaneously -> all repaired by -a (raw)" {
    rm -rf "${ROOT}/usr" "${ROOT}/etc" "${ROOT}/var"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/usr" ]
    [ -d "${ROOT}/etc" ]
    [ -d "${ROOT}/var" ]
}
@test "FSCK-CI-036: all 3 symlinks deleted -> all repaired by -a (raw)" {
    rm "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$(readlink "${ROOT}/bin")"   = "usr/bin"   ]
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

# ---------------------------------------------------------------------------
# Phase 4: After -a repair, verify root is fully clean with raw fs assertions
# ---------------------------------------------------------------------------

@test "FSCK-CI-037: after -a repair of usr, all 9 dirs still present (raw)" {
    rm -rf "${ROOT}/usr"
    bash "$SCRIPT" fsck -a --host-real-root "$ROOT" 2>/dev/null || true
    for d in usr etc home proc dev tmp run opt var; do
        [ -d "${ROOT}/${d}" ]
    done
}
@test "FSCK-CI-038: after -a repair of bin, all 3 symlinks correct (raw)" {
    rm "${ROOT}/bin"
    bash "$SCRIPT" fsck -a --host-real-root "$ROOT" 2>/dev/null || true
    [ "$(readlink "${ROOT}/bin")"   = "usr/bin"   ]
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}
@test "FSCK-CI-039: after -a repair, sandbox_user home still exists (raw -- -a does NOT touch home)" {
    rm -rf "${ROOT}/usr"
    bash "$SCRIPT" fsck -a --host-real-root "$ROOT" 2>/dev/null || true
    [ -d "${ROOT}/home/sandbox_user" ]
}
@test "FSCK-CI-040: after -a repair, top-level entry count is still 12 (raw)" {
    rm -rf "${ROOT}/usr"
    bash "$SCRIPT" fsck -a --host-real-root "$ROOT" 2>/dev/null || true
    local count
    count="$(find "$ROOT" -maxdepth 1 -mindepth 1 | wc -l)"
    [ "$count" -eq 12 ]
}

# ---------------------------------------------------------------------------
# Phase 5: fsck after repair exits 0 (clean) -- then raw verify
# ---------------------------------------------------------------------------

@test "FSCK-CI-041: remove usr + -a repair + second fsck exits 0" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    # ^ exits 2 (repaired); consumed by run
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -eq 0 ]
}
@test "FSCK-CI-042: remove bin + -a repair + second fsck exits 0" {
    rm "${ROOT}/bin"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -eq 0 ]
}
@test "FSCK-CI-043: wrong lib64 target + -a repair + raw verify target is correct" {
    rm "${ROOT}/lib64"
    ln -s "DEFINITELY_WRONG" "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}
@test "FSCK-CI-044: chaos -- delete all dirs and symlinks + -a repair + all restored (raw)" {
    rm -rf "${ROOT}/usr" "${ROOT}/etc" "${ROOT}/home" "${ROOT}/proc" \
           "${ROOT}/dev" "${ROOT}/tmp" "${ROOT}/run" "${ROOT}/opt" "${ROOT}/var"
    rm -f  "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/lib64"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    # dirs restored
    for d in usr etc home proc dev tmp run opt var; do
        [ -d "${ROOT}/${d}" ]
    done
    # symlinks restored
    [ "$(readlink "${ROOT}/bin")"   = "usr/bin"   ]
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

# ---------------------------------------------------------------------------
# Phase 6: -n blocks repair even when -n is passed after -a-like corruption
# ---------------------------------------------------------------------------

@test "FSCK-CI-045: remove usr -> -n detects but does NOT create usr (raw)" {
    rm -rf "${ROOT}/usr"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ ! -d "${ROOT}/usr" ]
}
@test "FSCK-CI-046: wrong lib target -> -n detects but does NOT fix target (raw)" {
    rm "${ROOT}/lib"
    ln -s "BADTARGET" "${ROOT}/lib"
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$(readlink "${ROOT}/lib")" = "BADTARGET" ]
}

# ---------------------------------------------------------------------------
# Phase 7: Bitmap exit codes verified with raw post-check
# ---------------------------------------------------------------------------

@test "FSCK-CI-047: clean root -> fsck exits 0, all dirs present (raw)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -eq 0 ]
    for d in usr etc home proc dev tmp run opt var; do
        [ -d "${ROOT}/${d}" ]
    done
}
@test "FSCK-CI-048: remove tmp -> no repair -> exit 1, tmp still missing (raw)" {
    rm -rf "${ROOT}/tmp"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
    [ ! -d "${ROOT}/tmp" ]
}
@test "FSCK-CI-049: remove tmp -> -a repair -> exit 2, tmp present (raw)" {
    rm -rf "${ROOT}/tmp"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/tmp" ]
}
@test "FSCK-CI-050: root is a file -> exit 4 (uncorrectable, raw: still a file)" {
    rm -rf "$ROOT"
    touch "$ROOT"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -eq 4 ]
    [ -f "$ROOT" ]
    [ ! -d "$ROOT" ]
}
