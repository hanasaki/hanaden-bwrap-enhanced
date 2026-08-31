#!/usr/bin/env bats
# HLP-QUAL: qualifier rules in --help one-liner (top-level)
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "HLP-QUAL-001: --help shows qualifier types (ro|rw and true|false)" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ro"* ]]
    [[ "$output" == *"rw"* ]]
    [[ "$output" == *"true"* ]]
    [[ "$output" == *"false"* ]]
}

@test "HLP-QUAL-002: --help shows privilege escalation order" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"absent"* ]]
}

@test "HLP-QUAL-003: --help shows --flag false is [ERROR]" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--flag false"* ]]
    [[ "$output" == *"[ERROR]"* ]]
}

@test "HLP-QUAL-004: start --help also shows qualifier rules" {
    run bash "$SCRIPT" start --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ro"* ]]
    [[ "$output" == *"rw"* ]]
    [[ "$output" == *"absent"* ]]
}
