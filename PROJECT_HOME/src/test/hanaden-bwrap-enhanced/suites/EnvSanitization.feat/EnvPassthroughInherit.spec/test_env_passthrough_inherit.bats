#!/usr/bin/env bats
# SPEC: EnvPassthroughInherit.spec
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "ENV-INH-001: --env-passthrough -> no --clearenv" {
    run _dry --env-passthrough
    [[ "$output" != *"--clearenv"* ]]
}
