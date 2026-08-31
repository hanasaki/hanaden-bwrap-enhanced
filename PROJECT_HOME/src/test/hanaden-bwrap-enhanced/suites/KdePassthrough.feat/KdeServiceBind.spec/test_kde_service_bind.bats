#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "KDE-SVC-001: --kde-passthrough -> kwallet bound" {
    run _dry --kde-passthrough
    [[ "$output" == *"kwallet"* ]]
}

@test "KDE-SVC-002: --kde-passthrough -> KSMserver bound" {
    run _dry --kde-passthrough
    [[ "$output" == *"KSMserver"* ]]
}
