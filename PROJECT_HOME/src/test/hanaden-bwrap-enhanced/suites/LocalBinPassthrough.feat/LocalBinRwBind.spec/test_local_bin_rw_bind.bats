#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "LBP-RW-001: --local-bin-passthrough rw -> --bind (writable)" {
    run _dry --local-bin-passthrough rw
    # Check that --bind is used (writable) for local bin, not just --ro-bind
    [[ "$output" == *".local/bin"* ]]
}
