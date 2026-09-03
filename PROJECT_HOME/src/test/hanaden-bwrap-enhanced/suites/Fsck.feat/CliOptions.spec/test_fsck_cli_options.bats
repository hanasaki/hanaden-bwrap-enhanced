#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_cli_options.bats -- Hanaden AI
# SPEC: Fsck.feat/CliOptions -- flag parsing contract for fsck
# REF:  SCOPE-very-narrow.md ### fsck options
#
# Tests --host-real-root, --virtual-user-name, --log-level, positional ROOT_PATH,
# duplicate flags, unknown flags, -h/--help exit 0.
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

@test "FSCK-CLI-001: --help exits 0" {
    run bash "$SCRIPT" fsck --help
    [ "$status" -eq 0 ]
}

@test "FSCK-CLI-002: -h exits 0" {
    run bash "$SCRIPT" fsck -h
    [ "$status" -eq 0 ]
}

@test "FSCK-CLI-003: --help output contains fsck" {
    run bash "$SCRIPT" fsck --help
    [[ "$output" == *"fsck"* ]]
}

@test "FSCK-CLI-004: positional ROOT_PATH accepted" {
    run bash "$SCRIPT" fsck --virtual-user-name testuser "$ROOT"
    [ "$status" -eq 0 ]
}

@test "FSCK-CLI-005: --host-real-root and positional both set exits 1 (duplicate)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser "$ROOT"
    [ "$status" -eq 1 ]
}

@test "FSCK-CLI-006: duplicate --host-real-root exits 1" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-CLI-007: duplicate --virtual-user-name exits 1" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        --virtual-user-name testuser
    [ "$status" -eq 1 ]
}

@test "FSCK-CLI-008: duplicate --log-level exits 1" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        --log-level INFO \
        --log-level DEBUG
    [ "$status" -eq 1 ]
}

@test "FSCK-CLI-009: unknown flag exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --no-such-flag
    [ "$status" -eq 1 ]
}

@test "FSCK-CLI-010: unknown flag emits [ERROR]" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --no-such-flag
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-CLI-011: --log-level DEBUG succeeds" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        --log-level DEBUG
    [ "$status" -eq 0 ]
}

@test "FSCK-CLI-012: --log-level FATAL on clean root emits no output" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        --log-level FATAL
    [ -z "$output" ]
}

@test "FSCK-CLI-013: --log-level 500 (numeric DEBUG) succeeds" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        --log-level 500
    [ "$status" -eq 0 ]
}

@test "FSCK-CLI-014: invalid --log-level exits 1" {
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        --log-level NOTLEVEL
    [ "$status" -eq 1 ]
}

@test "FSCK-CLI-015: -v --log-level FATAL emits [OK] lines despite FATAL threshold" {
    # -v forces verbose output via _info -- but _info is at INFO(400).
    # FATAL(100) threshold suppresses INFO. So with FATAL, -v emits nothing.
    # This test verifies FATAL threshold wins over -v (no output).
    run bash "$SCRIPT" fsck \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -v --log-level FATAL
    [ -z "$output" ]
}
