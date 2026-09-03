#!/usr/bin/env bats
# SPEC: DefaultClearenv.spec
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "ENV-CLR-001: default -> --clearenv present" {
    run _dry
    [[ "$output" == *"--clearenv"* ]]
}
