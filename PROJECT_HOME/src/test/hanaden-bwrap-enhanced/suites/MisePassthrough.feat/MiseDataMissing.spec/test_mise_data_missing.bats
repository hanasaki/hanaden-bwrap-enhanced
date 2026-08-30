#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

_dry_no_data() {
    BWRAP_SKIP_PREFLIGHT=1 MISE_DATA_DIR="/nonexistent/mise-data-$(date +%N)"         bash "$SCRIPT" --dry-run --mise-passthrough -- /bin/true 2>&1
}

@test "MISE-NODATA-001: mise data dir missing -> FATAL" {
    run _dry_no_data
    [ "$status" -eq 1 ]
    [[ "$output" == *"FATAL"* ]]
}
