#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}
@test "HCD-NHP-001: no hardcoded absolute user paths in logic" {
    # Script must not contain /homes/ (site-specific paths) in logic lines
    ! grep -qE '^[^#]*/homes/' "$SCRIPT"
}
