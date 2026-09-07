#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}
@test "DBAN-001: every invocation emits version banner to stderr" {
    run bash -c "bash '$SCRIPT' --help 2>&1 >/dev/null"
    [ "$status" -eq 0 ]
    [[ "$output" == *"bwrap-enhanced.sh v"* ]]
    [[ "$output" == *"Bubblewrap Sandbox Launcher"* ]]
}
@test "DBAN-002: banner present on error path (unknown subcommand)" {
    run bash "$SCRIPT" bogus-cmd 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"bwrap-enhanced.sh v"* ]]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DBAN-003: --version outputs version to stdout" {
    run bash "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"bwrap-enhanced.sh v"* ]]
}
