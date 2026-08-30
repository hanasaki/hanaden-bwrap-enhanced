#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "PTA-RO-001: raw --setenv passes through to bwrap args" {
    run _dry --setenv MY_CUSTOM_VAR hello
    [[ "$output" == *"MY_CUSTOM_VAR"* ]]
    [[ "$output" == *"hello"* ]]
}
