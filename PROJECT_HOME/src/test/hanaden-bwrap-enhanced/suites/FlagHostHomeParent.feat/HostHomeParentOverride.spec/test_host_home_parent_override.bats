#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }
@test "FHHP-OVR-001: --host-real-home-parent /tmp/homes -> used" {
    run _dry --host-real-home-parent /tmp/homes
    [[ "$output" == *"/tmp/homes"* ]]
}
