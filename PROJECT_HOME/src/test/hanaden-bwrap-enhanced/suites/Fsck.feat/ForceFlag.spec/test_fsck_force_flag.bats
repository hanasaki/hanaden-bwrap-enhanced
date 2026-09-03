#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_force_flag.bats -- Hanaden AI
# SPEC: Fsck.feat/ForceFlag -- fsck -f forces all checks even if root looks clean
# REF:  SCOPE-very-narrow.md ### fsck -- -f Force: run all checks even if root looks clean
#
# The -f flag defeats a quick-check optimization. Without -f, fsck
# may short-circuit on a root that "looks clean" (all expected entries
# are present on a surface scan). With -f, all deep checks always run.
#
# The quick-check tests for existence only:
#   - all 9 expected dirs exist?
#   - all 3 expected symlinks exist?
#   - user home exists and is a dir?
# If all pass -> skip detailed validation, exit 0.
#
# -f forces the detailed checks that catch subtleties like
# wrong symlink targets (a symlink exists but points to the wrong path).
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

# --------------------------------------------------------------------------
# Basic: -f on clean root exits 0 (all checks pass regardless)
# --------------------------------------------------------------------------

@test "FSCK-FORCE-001: clean root with -f exits 0" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f
    [ "$status" -eq 0 ]
}

@test "FSCK-FORCE-002: -fv on clean root shows all [OK] check output" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f -v
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}

# --------------------------------------------------------------------------
# KEY BEHAVIORAL TEST: wrong symlink target
#
# Symlink exists (quick-check sees it) but points to wrong path.
# WITHOUT -f: quick-check passes (symlink exists) -> exit 0 (bug undetected).
# WITH -f:    deep checks run -> detects wrong target -> exit 1.
# --------------------------------------------------------------------------

@test "FSCK-FORCE-003: wrong symlink target MISSED without -f (quick-check short-circuits, exit 0)" {
    rm "$ROOT/bin"
    ln -sfn "wrong/target" "$ROOT/bin"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    # Quick-check: bin exists as symlink -> "looks clean" -> exit 0
    [ "$status" -eq 0 ]
}

@test "FSCK-FORCE-004: wrong symlink target CAUGHT with -f (deep checks, exit 1)" {
    rm "$ROOT/bin"
    ln -sfn "wrong/target" "$ROOT/bin"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f
    # -f forces deep checks: bin -> wrong/target != usr/bin -> exit 1
    [ "$status" -eq 1 ]
    [[ "$output" == *"bad/missing symlink"* ]]
}

@test "FSCK-FORCE-005: wrong symlink with -f -a repairs it (exit 2)" {
    rm "$ROOT/bin"
    ln -sfn "wrong/target" "$ROOT/bin"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f -a
    [ "$status" -eq 2 ]
    [ "$(readlink "$ROOT/bin")" = "usr/bin" ]
}

# --------------------------------------------------------------------------
# Missing dirs: never caught by quick-check (dir absent = obvious),
# -f doesn't change behavior for these cases.
# --------------------------------------------------------------------------

@test "FSCK-FORCE-006: -f on root with missing dir exits 1" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f
    [ "$status" -eq 1 ]
}

@test "FSCK-FORCE-007: missing dir without -f also exits 1 (not a subtle corruption)" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-FORCE-008: -f combined with -n on damaged root exits 1 (check only)" {
    rm -rf "${ROOT}/proc"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f -n
    [ "$status" -eq 1 ]
    [ ! -e "${ROOT}/proc" ]
}

# --------------------------------------------------------------------------
# Flag bundle: -fv unbundles correctly
# --------------------------------------------------------------------------

@test "FSCK-FORCE-009: -fv flag bundle works (force + verbose)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -fv
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}
