#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

_run_wrong_qual_bool() {
    bash "$SCRIPT" --net-passthrough ro -- /bin/true 2>&1
}

@test "ERR-WQBOOL-001: --net-passthrough ro -> wrong qualifier ERROR" {
    run _run_wrong_qual_bool
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"wrong qualifier"* ]]
}
