#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_empty_command_fatal.bats -- Hanaden AI
# SPEC: EmptyCommandFatal.spec -- no CMD after -- -> ERROR exit 1
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_run_empty_cmd() {
    bash "$SCRIPT" -- 2>&1
}

# ---------------------------------------------------------------------------
@test "CLI-ECMD-001: -- with no CMD -- exit 1" {
    run _run_empty_cmd
    [ "$status" -eq 1 ]
}

@test "CLI-ECMD-002: -- with no CMD -- stderr contains [ERROR]" {
    run _run_empty_cmd
    [[ "$output" == *"[ERROR]"* ]]
}

@test "CLI-ECMD-003: -- with no CMD -- stderr mentions CMD" {
    run _run_empty_cmd
    [[ "$output" == *"CMD"* ]] || [[ "$output" == *"command"* ]]
}
