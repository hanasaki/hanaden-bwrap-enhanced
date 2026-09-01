#!/usr/bin/env bats
# SPEC: DefaultPath.spec
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "ENV-PATH-001: default PATH=/usr/bin:/bin" {
    run _dry
    [[ "$output" == *"PATH"* ]]
    [[ "$output" == *"/usr/bin:/bin"* ]]
}
