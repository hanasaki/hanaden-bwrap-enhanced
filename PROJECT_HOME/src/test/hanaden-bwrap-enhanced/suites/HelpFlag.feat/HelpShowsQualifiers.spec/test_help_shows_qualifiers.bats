#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "HLP-QUAL-001: --help shows qualifier types" {
    run bash "$SCRIPT" --help
    # graded flags show ro|rw
    [[ "$output" == *"ro"* ]]
    [[ "$output" == *"rw"* ]]
    # boolean flags show true
    [[ "$output" == *"true"* ]]
}
