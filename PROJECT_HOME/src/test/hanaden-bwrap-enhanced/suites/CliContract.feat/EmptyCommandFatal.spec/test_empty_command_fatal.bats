#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_empty_command_fatal.bats -- Hanaden AI
# SPEC: EmptyCommandFatal — `start -- ` with no CMD after separator → [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "ECMD-001: start -- with no cmd exits 1" {
    # Separator present but nothing follows → empty CMD array
    run bash "$SCRIPT" start --
    [ "$status" -eq 1 ]
}
@test "ECMD-002: start -- with no cmd emits [ERROR]" {
    run bash "$SCRIPT" start --
    [[ "$output" == *"[ERROR]"* ]]
}
