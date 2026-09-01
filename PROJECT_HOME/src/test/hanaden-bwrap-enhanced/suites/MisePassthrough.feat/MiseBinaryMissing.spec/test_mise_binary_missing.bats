#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

_dry_no_mise() {
    MISE_BIN="/nonexistent/mise-$(date +%N)"         bash "$SCRIPT" start --dry-run --mise-passthrough -- /bin/true 2>&1
}

@test "MISE-NOBIN-001: mise binary missing -> FATAL" {
    run _dry_no_mise
    [ "$status" -eq 1 ]
    [[ "$output" == *"FATAL"* ]]
}
