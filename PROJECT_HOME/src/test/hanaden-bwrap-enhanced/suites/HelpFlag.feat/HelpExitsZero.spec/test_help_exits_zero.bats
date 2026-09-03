#!/usr/bin/env bats
# HLP-EXIT-001: top-level --help exits 0
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "HLP-EXIT-001: --help exits 0" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
}

@test "HLP-EXIT-002: -h exits 0" {
    run bash "$SCRIPT" -h
    [ "$status" -eq 0 ]
}

@test "HLP-EXIT-003: no args exits 0 (shows top-level help)" {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
}
