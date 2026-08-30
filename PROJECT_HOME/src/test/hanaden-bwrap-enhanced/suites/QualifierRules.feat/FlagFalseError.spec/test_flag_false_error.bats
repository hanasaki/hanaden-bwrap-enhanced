#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }
@test "QR-FALSE-001: boolean false -> ERROR (implicit is false)" {
    run bash "$SCRIPT" --net-passthrough false -- /bin/true 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"false"* ]]
}
@test "QR-FALSE-002: graded false -> ERROR" {
    run bash "$SCRIPT" --mise-passthrough false -- /bin/true 2>&1
    [ "$status" -eq 1 ]
}
