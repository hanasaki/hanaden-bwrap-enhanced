#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }
@test "FHRR-SET-001: --host-real-root /tmp/test-root -> used in output" {
    run _dry --host-real-root /tmp/test-root
    [[ "$output" == *"/tmp/test-root"* ]]
}
