#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

_run_wrong_qual_graded() {
    BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --mise-passthrough true -- /bin/true 2>&1
}

@test "ERR-WQGRAD-001: --mise-passthrough true -> wrong qualifier ERROR" {
    run _run_wrong_qual_graded
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"wrong qualifier"* ]]
}
