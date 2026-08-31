#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }
@test "QR-BARE-001: bare boolean flag -> true (net example)" {
    run _dry --net-passthrough
    [[ "$output" != *"--unshare-net"* ]]
}
@test "QR-BARE-002: bare graded flag -> ro (mise example)" {
    run _dry --mise-passthrough
    [ "$status" -eq 0 ]
}
