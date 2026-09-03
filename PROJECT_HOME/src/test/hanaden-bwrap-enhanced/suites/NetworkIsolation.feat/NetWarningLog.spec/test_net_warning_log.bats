#!/usr/bin/env bats
# SPEC: NetWarningLog.spec
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "NET-WARN-001: --net-passthrough -> SYS-LOG WARNING" {
    run _dry --net-passthrough
    [[ "$output" == *"WARNING"* ]]
    [[ "$output" == *"Network"* ]] || [[ "$output" == *"net"* ]]
}
