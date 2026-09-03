#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_top_level_dispatcher.bats -- Hanaden AI
# SPEC: CliContract.feat/TopLevelDispatcher -- pre-subcommand dispatch
# REF:  SCOPE-very-narrow.md ### Entry Point 1
#
# Tests: --help, -h, --version, -v, empty args, unknown subcommand,
#        unknown top-level flag, each subcommand dispatches correctly.
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
# --help / -h (top-level)
# ---------------------------------------------------------------------------

@test "DISP-HELP-001: --help exits 0" {
    run bash "$SCRIPT" --help 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-002: -h exits 0" {
    run bash "$SCRIPT" -h 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-003: --help output lists provision subcommand" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"provision"* ]]
}

@test "DISP-HELP-004: --help output lists fsck subcommand" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"fsck"* ]]
}

@test "DISP-HELP-005: --help output lists start subcommand" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"start"* ]]
}

@test "DISP-HELP-006: --help output lists stop subcommand" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"stop"* ]]
}

@test "DISP-HELP-007: --help output lists ls subcommand" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"ls"* ]]
}

@test "DISP-HELP-008: -h and --help produce identical output" {
    local h1 h2
    h1="$(bash "$SCRIPT" --help 2>&1)"
    h2="$(bash "$SCRIPT" -h 2>&1)"
    [ "$h1" = "$h2" ]
}

@test "DISP-HELP-009: --help mentions --version" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"--version"* ]]
}

@test "DISP-HELP-010: --help mentions log levels" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"FATAL"* ]]
    [[ "$output" == *"TRACE"* ]]
}

# ---------------------------------------------------------------------------
# --version / -v
# ---------------------------------------------------------------------------

@test "DISP-VER-001: --version exits 0" {
    run bash "$SCRIPT" --version 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-VER-002: -v exits 0" {
    run bash "$SCRIPT" -v 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-VER-003: --version output contains a version number" {
    run bash "$SCRIPT" --version 2>&1
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "DISP-VER-004: -v and --version produce identical output" {
    local v1 v2
    v1="$(bash "$SCRIPT" --version 2>&1)"
    v2="$(bash "$SCRIPT" -v 2>&1)"
    [ "$v1" = "$v2" ]
}

@test "DISP-VER-005: --version output contains script name" {
    run bash "$SCRIPT" --version 2>&1
    [[ "$output" == *"bwrap-enhanced"* ]]
}

# ---------------------------------------------------------------------------
# Empty args
# ---------------------------------------------------------------------------

@test "DISP-EMPTY-001: no args exits 0 (shows help)" {
    run bash "$SCRIPT" 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-EMPTY-002: no args produces same output as --help" {
    local h1 h2
    h1="$(bash "$SCRIPT" 2>&1)"
    h2="$(bash "$SCRIPT" --help 2>&1)"
    [ "$h1" = "$h2" ]
}

# ---------------------------------------------------------------------------
# Unknown subcommand
# ---------------------------------------------------------------------------

@test "DISP-UNK-001: unknown subcommand exits 1" {
    run bash "$SCRIPT" notacmd 2>&1
    [ "$status" -eq 1 ]
}

@test "DISP-UNK-002: unknown subcommand emits [ERROR]" {
    run bash "$SCRIPT" notacmd 2>&1
    [[ "$output" == *"[ERROR]"* ]]
}

@test "DISP-UNK-003: unknown subcommand mentions the bad name" {
    run bash "$SCRIPT" foobar 2>&1
    [[ "$output" == *"foobar"* ]]
}

@test "DISP-UNK-004: unknown subcommand emits help hint" {
    run bash "$SCRIPT" foobar 2>&1
    [[ "$output" == *"--help"* ]]
}

# ---------------------------------------------------------------------------
# Unknown top-level flag (not --help or --version)
# ---------------------------------------------------------------------------

@test "DISP-UNK-005: --badopt (unknown top-level flag) exits 1" {
    run bash "$SCRIPT" start --badopt 2>&1
    [ "$status" -eq 1 ]
}

@test "DISP-UNK-006: -z (unknown short top-level flag) exits 1" {
    run bash "$SCRIPT" -z 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Subcommand dispatch verification (each subcommand reachable)
# ---------------------------------------------------------------------------

@test "DISP-REACH-001: provision --help reachable (exits 0)" {
    run bash "$SCRIPT" provision --help 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-REACH-002: fsck --help reachable (exits 0)" {
    run bash "$SCRIPT" fsck --help 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-REACH-003: start --help reachable (exits 0)" {
    run bash "$SCRIPT" --help 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-REACH-004: stop --help reachable (exits 0)" {
    run bash "$SCRIPT" stop --help 2>&1
    [ "$status" -eq 0 ]
}

@test "DISP-REACH-005: ls --help reachable (exits 0)" {
    run bash "$SCRIPT" ls --help 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Top-level help content detail
# ---------------------------------------------------------------------------

@test "DISP-HELP-011: --help mentions default deny model" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"default deny"* ]] || [[ "$output" == *"flag absent"* ]]
}

@test "DISP-HELP-012: --help mentions --flag false = [ERROR]" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"false"* ]]
    [[ "$output" == *"ERROR"* ]]
}

@test "DISP-HELP-013: --help mentions privilege escalation order (absent < ro < rw)" {
    run bash "$SCRIPT" --help 2>&1
    [[ "$output" == *"absent"* ]]
    [[ "$output" == *"ro"* ]]
    [[ "$output" == *"rw"* ]]
}
