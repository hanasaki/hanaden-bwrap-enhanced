#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PORT-NHP-001: no /homes/ hardcoded paths in script" {
    # Script must not contain hardcoded user paths
    ! grep -q '/homes/' "$SCRIPT"
}
