#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_ls_parsing.bats -- Hanaden AI
# SPEC: CliContract.feat/LsParsing -- ls subcommand flag parsing
# REF:  SCOPE-very-narrow.md ### ls (stub)
#
# Tests: all ls flags accepted, missing values, unknown flags,
#        help content, stub exit behavior, --format values.
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

@test "LS-PARSE-001: --help exits 0" {
    run bash "$SCRIPT" ls --help 2>&1
    [ "$status" -eq 0 ]
}

@test "LS-PARSE-002: -h exits 0" {
    run bash "$SCRIPT" ls -h 2>&1
    [ "$status" -eq 0 ]
}

@test "LS-PARSE-003: --help mentions --all" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"--all"* ]] || [[ "$output" == *"-a"* ]]
}

@test "LS-PARSE-004: --help mentions --quiet" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"--quiet"* ]] || [[ "$output" == *"-q"* ]]
}

@test "LS-PARSE-005: --help mentions --format" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"--format"* ]]
}

@test "LS-PARSE-006: --help mentions stub/not yet implemented" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"not yet implemented"* ]] || [[ "$output" == *"stub"* ]]
}

@test "LS-PARSE-007: --help mentions table format" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"table"* ]]
}

@test "LS-PARSE-008: --help mentions json format" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"json"* ]]
}

@test "LS-PARSE-009: --help mentions csv format" {
    run bash "$SCRIPT" ls --help 2>&1
    [[ "$output" == *"csv"* ]]
}

# ---------------------------------------------------------------------------
# Flags accepted (parsed before stub exit)
# ---------------------------------------------------------------------------

@test "LS-PARSE-010: -a accepted (stub exits 1 not parse error)" {
    run bash "$SCRIPT" ls -a 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-011: --all accepted" {
    run bash "$SCRIPT" ls --all 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-012: -q accepted" {
    run bash "$SCRIPT" ls -q 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-013: --quiet accepted" {
    run bash "$SCRIPT" ls --quiet 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-014: --format table accepted" {
    run bash "$SCRIPT" ls --format table 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-015: --format json accepted" {
    run bash "$SCRIPT" ls --format json 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-016: --format csv accepted" {
    run bash "$SCRIPT" ls --format csv 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-017: --log-level accepted" {
    run bash "$SCRIPT" ls --log-level DEBUG 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-018: all flags together accepted" {
    run bash "$SCRIPT" ls -a -q --format json --log-level DEBUG 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

# ---------------------------------------------------------------------------
# Unknown flag
# ---------------------------------------------------------------------------

@test "LS-PARSE-019: unknown flag exits 1 with [ERROR]" {
    run bash "$SCRIPT" ls --badopt 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"unknown option"* ]]
}

@test "LS-PARSE-020: unknown short flag -z exits 1" {
    run bash "$SCRIPT" ls -z 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Missing values
# ---------------------------------------------------------------------------

@test "LS-PARSE-021: --format with no value exits error" {
    run bash "$SCRIPT" ls --format 2>&1
    [ "$status" -ne 0 ]
}

@test "LS-PARSE-022: --log-level with no value exits error" {
    run bash "$SCRIPT" ls --log-level 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Stub exit behavior
# ---------------------------------------------------------------------------

@test "LS-PARSE-023: bare ls (no flags) exits 1 with not-implemented" {
    run bash "$SCRIPT" ls 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"not yet implemented"* ]]
}

@test "LS-PARSE-024: ls emits [ERROR] for not-implemented" {
    run bash "$SCRIPT" ls 2>&1
    [[ "$output" == *"[ERROR]"* ]]
}
