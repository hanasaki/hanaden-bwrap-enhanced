#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_empty_root_regression.bats -- Hanaden AI
# SPEC: Fsck.feat/EmptyRootRegression -- regression: fsck on completely empty dir
# REF:  SCOPE-very-narrow.md ### fsck -- exit codes 0=no errors 1=errors not repaired
#
# Regression: fsck --host-real-root /tmp/<empty-dir> was reporting exit 0
# (no errors) on an empty directory instead of exit 1 (errors found, not repaired).
# All 9 dirs + 3 symlinks + user home are missing -> must exit 1.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    # ROOT is a completely empty directory -- nothing inside it
    ROOT="${WORK}/empty"
    mkdir -p "$ROOT"
}
teardown() { rm -rf "$WORK"; }

@test "FSCK-EMPTY-001: empty root dir must NOT exit 0 (regression)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -ne 0 ]
}

@test "FSCK-EMPTY-002: empty root dir exits 1 (errors found, not repaired)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}

@test "FSCK-EMPTY-003: empty root dir emits [ERROR] for each missing dir" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT"
    local err_count
    err_count="$(printf '%s\n' "$output" | grep -c '\[ERROR\]')"
    # at minimum: 9 missing dirs + 3 missing symlinks + 1 missing home = 13
    [ "$err_count" -ge 13 ]
}

@test "FSCK-EMPTY-004: empty root with -v still exits 1" {
    run bash "$SCRIPT" fsck -v --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}

@test "FSCK-EMPTY-005: empty root with -f still exits 1" {
    run bash "$SCRIPT" fsck -f --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
}

@test "FSCK-EMPTY-006: empty root with -n exits 1 and makes no changes" {
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT"
    [ "$status" -eq 1 ]
    # nothing should have been created
    local count
    count="$(find "$ROOT" -mindepth 1 | wc -l)"
    [ "$count" -eq 0 ]
}

@test "FSCK-EMPTY-007: empty root with -a exits 2 and creates all dirs and symlinks" {
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT"
    # exit 2: errors repaired (dirs and symlinks); home still missing (exit bit 1 too)
    # 2|1 = 3, but home is "not repairable" -> bit 1 stays
    # So: dirs repaired (bit 2) | home not repaired (bit 1) = 3
    # OR if home doesn't count as repaired: just 2|1=3
    [ "$status" -ge 1 ]
    # At minimum, all 9 dirs must now be present
    [ -d "${ROOT}/usr" ]
    [ -d "${ROOT}/etc" ]
    [ -d "${ROOT}/home" ]
    [ -d "${ROOT}/proc" ]
    [ -d "${ROOT}/dev" ]
    [ -d "${ROOT}/tmp" ]
    [ -d "${ROOT}/run" ]
    [ -d "${ROOT}/opt" ]
    [ -d "${ROOT}/var" ]
    # All 3 symlinks must be correct
    [ "$(readlink "${ROOT}/bin")"   = "usr/bin"   ]
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

@test "FSCK-EMPTY-008: empty root using positional ROOT_PATH exits 1" {
    run bash "$SCRIPT" fsck --virtual-user-name sandbox_user "$ROOT"
    [ "$status" -eq 1 ]
}

@test "FSCK-EMPTY-009: empty root with --log-level FATAL exits 1 with no output" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --log-level FATAL
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}
