#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }
@test "FLBIN-FE-001: --local-bin-passthrough false -> ERROR exit 1" {
    run bash "$SCRIPT" --local-bin-passthrough false -- /bin/true 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
