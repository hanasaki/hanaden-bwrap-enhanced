#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PORT-BASH-001: no bash 5 exclusive features (nameref, wait -p)" {
    # Script must not use declare -n (nameref) or wait -p (bash 5 only)
    ! grep -qE 'declare -n|wait -p' "$SCRIPT"
}
