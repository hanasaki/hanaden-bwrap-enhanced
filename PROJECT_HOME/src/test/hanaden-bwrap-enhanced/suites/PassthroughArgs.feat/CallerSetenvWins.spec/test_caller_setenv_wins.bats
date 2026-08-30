#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "PTA-WIN-001: raw passthrough args appear after default args" {
    run _dry --setenv CUSTOM_LAST yes
    [[ "$output" == *"CUSTOM_LAST"* ]]
    # Verify it appears after the built-in HOME setenv
    local home_pos custom_pos
    home_pos=$(echo "$output" | grep -n "HOME" | head -1 | cut -d: -f1)
    custom_pos=$(echo "$output" | grep -n "CUSTOM_LAST" | head -1 | cut -d: -f1)
    [ "$custom_pos" -gt "$home_pos" ]
}
