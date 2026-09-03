#!/usr/bin/env bats
# Dispatch.feat/UnknownSubcommand -- unknown subcommand exits 1 with [ERROR]
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "DISP-UNK-001: unknown subcommand exits 1" {
    run bash "$SCRIPT" not-a-command
    [ "$status" -eq 1 ]
}

@test "DISP-UNK-002: unknown subcommand emits [ERROR]" {
    run bash "$SCRIPT" not-a-command
    [[ "$output" == *"[ERROR]"* ]]
}

@test "DISP-UNK-003: unknown subcommand emits hint" {
    run bash "$SCRIPT" not-a-command
    [[ "$output" == *"--help"* ]]
}
