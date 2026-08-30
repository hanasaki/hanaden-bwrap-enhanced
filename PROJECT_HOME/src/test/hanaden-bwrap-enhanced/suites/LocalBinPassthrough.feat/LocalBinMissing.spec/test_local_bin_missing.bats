#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

_dry_no_localbin() {
    HOME="/nonexistent/home-$(date +%N)" BWRAP_SKIP_PREFLIGHT=1         bash "$SCRIPT" --dry-run --local-bin-passthrough -- /bin/true 2>&1
}

@test "LBP-MISS-001: missing .local/bin -> FATAL exit 1" {
    run _dry_no_localbin
    [ "$status" -eq 1 ]
    [[ "$output" == *"FATAL"* ]]
}
