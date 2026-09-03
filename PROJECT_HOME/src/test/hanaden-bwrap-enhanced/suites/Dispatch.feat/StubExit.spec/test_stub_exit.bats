#!/usr/bin/env bats
# Dispatch.feat/StubExit -- stop and ls exit 1 with [ERROR] when called without --help
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "DISP-STUB-001: stop without --help exits 1" {
    run bash "$SCRIPT" stop
    [ "$status" -eq 1 ]
}

@test "DISP-STUB-002: stop without --help emits [ERROR]" {
    run bash "$SCRIPT" stop
    [[ "$output" == *"[ERROR]"* ]]
}

@test "DISP-STUB-003: stop [ERROR] message mentions 'not yet implemented'" {
    run bash "$SCRIPT" stop
    [[ "$output" == *"not yet implemented"* ]]
}

@test "DISP-STUB-004: ls without --help exits 1" {
    run bash "$SCRIPT" ls
    [ "$status" -eq 1 ]
}

@test "DISP-STUB-005: ls without --help emits [ERROR]" {
    run bash "$SCRIPT" ls
    [[ "$output" == *"[ERROR]"* ]]
}

@test "DISP-STUB-006: ls [ERROR] message mentions 'not yet implemented'" {
    run bash "$SCRIPT" ls
    [[ "$output" == *"not yet implemented"* ]]
}
