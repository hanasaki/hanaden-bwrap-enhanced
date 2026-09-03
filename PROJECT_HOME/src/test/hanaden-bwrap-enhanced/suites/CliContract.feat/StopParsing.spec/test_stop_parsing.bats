#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_stop_parsing.bats -- Hanaden AI
# SPEC: CliContract.feat/StopParsing -- stop subcommand flag parsing
# REF:  SCOPE-very-narrow.md ### stop (stub)
#
# Tests: all stop flags accepted, missing values, unknown flags,
#        help content, stub exit behavior.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

# ---------------------------------------------------------------------------
# --help
# ---------------------------------------------------------------------------

@test "STOP-PARSE-001: --help exits 0" {
    run bash "$SCRIPT" stop --help 2>&1
    [ "$status" -eq 0 ]
}

@test "STOP-PARSE-002: -h exits 0" {
    run bash "$SCRIPT" stop -h 2>&1
    [ "$status" -eq 0 ]
}

@test "STOP-PARSE-003: --help mentions --host-real-root" {
    run bash "$SCRIPT" stop --help 2>&1
    [[ "$output" == *"--host-real-root"* ]]
}

@test "STOP-PARSE-004: --help mentions --force" {
    run bash "$SCRIPT" stop --help 2>&1
    [[ "$output" == *"--force"* ]] || [[ "$output" == *"-f"* ]]
}

@test "STOP-PARSE-005: --help mentions --timeout" {
    run bash "$SCRIPT" stop --help 2>&1
    [[ "$output" == *"--timeout"* ]] || [[ "$output" == *"-t"* ]]
}

@test "STOP-PARSE-006: --help mentions stub/not yet implemented" {
    run bash "$SCRIPT" stop --help 2>&1
    [[ "$output" == *"not yet implemented"* ]] || [[ "$output" == *"stub"* ]]
}

# ---------------------------------------------------------------------------
# Flags accepted (parsed without error before stub exit)
# ---------------------------------------------------------------------------

@test "STOP-PARSE-007: --host-real-root accepted (stub exits 1 not parse error)" {
    run bash "$SCRIPT" stop --host-real-root "${WORK}/r" 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-008: --log-level accepted" {
    run bash "$SCRIPT" stop --log-level DEBUG 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-009: -f (force) accepted" {
    run bash "$SCRIPT" stop -f 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-010: --force accepted" {
    run bash "$SCRIPT" stop --force 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-011: -t SECONDS accepted" {
    run bash "$SCRIPT" stop -t 30 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-012: --timeout SECONDS accepted" {
    run bash "$SCRIPT" stop --timeout 30 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-013: all flags together accepted" {
    run bash "$SCRIPT" stop \
        --host-real-root "${WORK}/r" \
        --log-level DEBUG \
        -f \
        -t 30 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

# ---------------------------------------------------------------------------
# Unknown flag
# ---------------------------------------------------------------------------

@test "STOP-PARSE-014: unknown flag exits 1 with [ERROR]" {
    run bash "$SCRIPT" stop --badopt 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"unknown option"* ]]
}

@test "STOP-PARSE-015: unknown short flag -z exits 1" {
    run bash "$SCRIPT" stop -z 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Missing values
# ---------------------------------------------------------------------------

@test "STOP-PARSE-016: --host-real-root with no value exits error" {
    run bash "$SCRIPT" stop --host-real-root 2>&1
    [ "$status" -ne 0 ]
}

@test "STOP-PARSE-017: --log-level with no value exits error" {
    run bash "$SCRIPT" stop --log-level 2>&1
    [ "$status" -ne 0 ]
}

@test "STOP-PARSE-018: -t with no value exits error" {
    run bash "$SCRIPT" stop -t 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Stub exit behavior
# ---------------------------------------------------------------------------

@test "STOP-PARSE-019: bare stop (no flags) exits 1 with not-implemented" {
    run bash "$SCRIPT" stop 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "STOP-PARSE-020: stop emits [ERROR] for not-implemented" {
    run bash "$SCRIPT" stop 2>&1
    [[ "$output" == *"[ERROR]"* ]]
}
