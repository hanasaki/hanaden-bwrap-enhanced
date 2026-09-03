#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_log_level_parsing.bats -- Hanaden AI
# SPEC: LogLevelParsing -- --log-level accepts names and numbers, rejects invalid values

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

# Valid names on start (dry-run to skip exec)
@test "LL-001: --log-level FATAL accepted" {
    run bash "$SCRIPT" start --log-level FATAL --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-002: --log-level ERROR accepted" {
    run bash "$SCRIPT" start --log-level ERROR --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-003: --log-level WARN accepted" {
    run bash "$SCRIPT" start --log-level WARN --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-004: --log-level INFO accepted" {
    run bash "$SCRIPT" start --log-level INFO --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-005: --log-level DEBUG accepted" {
    run bash "$SCRIPT" start --log-level DEBUG --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-006: --log-level TRACE accepted" {
    run bash "$SCRIPT" start --log-level TRACE --dry-run
    [ "$status" -eq 0 ]
}

# Valid numeric values
@test "LL-007: --log-level 100 accepted" {
    run bash "$SCRIPT" start --log-level 100 --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-008: --log-level 400 accepted" {
    run bash "$SCRIPT" start --log-level 400 --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-009: --log-level 600 accepted" {
    run bash "$SCRIPT" start --log-level 600 --dry-run
    [ "$status" -eq 0 ]
}

# Case-insensitive names
@test "LL-010: --log-level debug (lowercase) accepted" {
    run bash "$SCRIPT" start --log-level debug --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-011: --log-level Info (mixed case) accepted" {
    run bash "$SCRIPT" start --log-level Info --dry-run
    [ "$status" -eq 0 ]
}

# Invalid values
@test "LL-012: --log-level VERBOSE rejected exit 1" {
    run bash "$SCRIPT" start --log-level VERBOSE --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "LL-013: --log-level 999 rejected exit 1" {
    run bash "$SCRIPT" start --log-level 999 --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "LL-014: --log-level '' rejected exit 1" {
    run bash "$SCRIPT" start --log-level '' --dry-run
    [ "$status" -ne 0 ]
}

# log-level on provision and fsck
@test "LL-015: provision --log-level DEBUG accepted" {
    run bash "$SCRIPT" provision --log-level DEBUG --dry-run
    [ "$status" -eq 0 ]
}
@test "LL-016: fsck --log-level 500 accepted" {
    run bash "$SCRIPT" fsck --log-level 500 --host-real-root /nonexistent 2>/dev/null || true
    # fsck will fail with exit 4 (root not found), but log-level parsing itself must not error
    # We only care that exit is NOT 1 (which would indicate a parse error)
    [ "$status" -ne 1 ]
}
