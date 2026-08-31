#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}
@test "HCD-PND-001: project name only in comments, not in logic" {
    # hanaden-bwrap-enhanced should only appear in comment lines (#)
    ! grep -vE '^\s*#' "$SCRIPT" | grep -q 'hanaden-bwrap-enhanced'
}
