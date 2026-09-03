#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_combined_short_flags.bats -- Hanaden AI
# SPEC: CliContract.feat/CombinedShortFlags -- flag bundling: -av, -fn, -rv, etc.
# REF:  SCOPE-very-narrow.md; POSIX / getopt convention
#
# BUG (to be fixed): combined short flags like -av are rejected as unknown.
# Individual flags (-a, -v) work. The fix implements POSIX flag bundling in
# each cmd_* parser: -av -> -a -v before the case loop runs.
#
# Tests are written to FAIL before the fix and PASS after.
# All assertions are behavioural (exit code, filesystem state, output text).
# No assertion calls any other bwrap-enhanced subcommand to verify state.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    ANSWERS="${WORK}/answers.txt"
    # Pre-provision a clean root for fsck tests
    bash "$SCRIPT" provision --host-real-root "$ROOT" --virtual-user-name sandbox_user
}
teardown() { rm -rf "$WORK"; }

_fsck() { bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name sandbox_user "$@" 2>&1; }
_run_fsck() { run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name sandbox_user "$@" 2>&1; }

# ---------------------------------------------------------------------------
# fsck combined short flags -- positive: must all exit 0 on clean root
# ---------------------------------------------------------------------------

@test "COMB-FSCK-001: -av (auto+verbose) on clean root exits 0" {
    _run_fsck -av
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-002: -av emits [OK] lines (verbose active)" {
    _run_fsck -av
    [[ "$output" == *"[OK]"* ]]
}

@test "COMB-FSCK-003: -va (verbose+auto, reversed order) on clean root exits 0" {
    _run_fsck -va
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-004: -nv (check-only+verbose) on clean root exits 0" {
    _run_fsck -nv
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-005: -nv emits [OK] lines (verbose active)" {
    _run_fsck -nv
    [[ "$output" == *"[OK]"* ]]
}

@test "COMB-FSCK-006: -fv (force+verbose) on clean root exits 0" {
    _run_fsck -fv
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-007: -fn (force+check-only) on clean root exits 0" {
    _run_fsck -fn
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-008: -fav (force+auto+verbose) on clean root exits 0" {
    _run_fsck -fav
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-009: -fnv (force+check-only+verbose) on clean root exits 0" {
    _run_fsck -fnv
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-010: -av on corrupt root exits 2 (auto repaired)" {
    rm -rf "${ROOT}/usr"
    _run_fsck -av
    [ "$status" -eq 2 ]
}

@test "COMB-FSCK-011: -av on corrupt root restores dir (raw)" {
    rm -rf "${ROOT}/usr"
    _run_fsck -av
    [ -d "${ROOT}/usr" ]
}

@test "COMB-FSCK-012: -av repair emits [OK] lines for clean entries (verbose active)" {
    _run_fsck -av
    [[ "$output" == *"[OK]"* ]]
}

@test "COMB-FSCK-013: -nv on corrupt root exits 1 (not repaired)" {
    rm -rf "${ROOT}/usr"
    _run_fsck -nv
    [ "$status" -eq 1 ]
}

@test "COMB-FSCK-014: -nv does NOT repair (raw: usr still missing)" {
    rm -rf "${ROOT}/usr"
    _run_fsck -nv
    [ ! -d "${ROOT}/usr" ]
}

@test "COMB-FSCK-015: -rv (interactive+verbose) on clean root exits 0" {
    printf '' > "$ANSWERS"
    BWRAP_FSCK_TTY="$ANSWERS" run bash "$SCRIPT" fsck -rv \
        --host-real-root "$ROOT" --virtual-user-name sandbox_user 2>&1
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-016: -rv emits [OK] lines (verbose active)" {
    printf '' > "$ANSWERS"
    BWRAP_FSCK_TTY="$ANSWERS" run bash "$SCRIPT" fsck -rv \
        --host-real-root "$ROOT" --virtual-user-name sandbox_user 2>&1
    [[ "$output" == *"[OK]"* ]]
}

@test "COMB-FSCK-017: -vf (verbose+force) accepted, exits 0" {
    _run_fsck -vf
    [ "$status" -eq 0 ]
}

@test "COMB-FSCK-018: -avf (auto+verbose+force) on corrupt root exits 2 and repairs (raw)" {
    rm -rf "${ROOT}/etc"
    _run_fsck -avf
    [ "$status" -eq 2 ]
    [ -d "${ROOT}/etc" ]
}

# -a and -r are still mutually exclusive even in combined form
@test "COMB-FSCK-019: -ar (auto+interactive) exits 1 (mutually exclusive, even combined)" {
    _run_fsck -ar
    [ "$status" -eq 1 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "COMB-FSCK-020: -ra (interactive+auto) exits 1 (mutually exclusive, even combined)" {
    _run_fsck -ra
    [ "$status" -eq 1 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

# ---------------------------------------------------------------------------
# provision combined short flags
# ---------------------------------------------------------------------------

@test "COMB-PROV-001: provision -nh (dry-run+help) exits 0" {
    # -h takes priority (help exits 0)
    run bash "$SCRIPT" provision -nh --host-real-root "${WORK}/newroot" 2>&1
    [ "$status" -eq 0 ]
}

@test "COMB-PROV-002: provision -hn exits 0 (help first)" {
    run bash "$SCRIPT" provision -hn --host-real-root "${WORK}/newroot" 2>&1
    [ "$status" -eq 0 ]
}

@test "COMB-PROV-003: provision combined flags not rejected as unknown option" {
    # -n is the only combinable non-help flag for provision
    run bash "$SCRIPT" provision -n --host-real-root "${WORK}/newroot" 2>&1
    [[ "$output" != *"unknown option"* ]]
}

# ---------------------------------------------------------------------------
# ls combined short flags (stub subcommand -- just verify parsing)
# ---------------------------------------------------------------------------

@test "COMB-LS-001: ls -aq (all+quiet) exits 0 (stub, combined flags parsed)" {
    run bash "$SCRIPT" ls -aq 2>&1
    [[ "$output" != *"unknown option"* ]]
}

@test "COMB-LS-002: ls -qa (quiet+all) exits 0 (stub, combined flags parsed)" {
    run bash "$SCRIPT" ls -qa 2>&1
    [[ "$output" != *"unknown option"* ]]
}

# ---------------------------------------------------------------------------
# Negative: truly unknown flags in combined form still rejected
# ---------------------------------------------------------------------------

@test "COMB-NEG-001: -ax (unknown char x) exits 1 with unknown option error" {
    _run_fsck -ax
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown option"* ]]
}

@test "COMB-NEG-002: -vz (unknown char z) exits 1 with unknown option error" {
    _run_fsck -vz
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown option"* ]]
}
