#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

_run_bool_false() {
    bash "$SCRIPT" --net-passthrough false -- /bin/true 2>&1
}

@test "ERR-BFALSE-001: --net-passthrough false -> ERROR exit 1" {
    run _run_bool_false
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
