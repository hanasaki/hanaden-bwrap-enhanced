#!/usr/bin/env bats
# SPEC: XdgVarsSet.spec
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "ENV-XDG-001: XDG_DATA_HOME set" {
    run _dry
    [[ "$output" == *"XDG_DATA_HOME"* ]]
}

@test "ENV-XDG-002: XDG_STATE_HOME set" {
    run _dry
    [[ "$output" == *"XDG_STATE_HOME"* ]]
}
