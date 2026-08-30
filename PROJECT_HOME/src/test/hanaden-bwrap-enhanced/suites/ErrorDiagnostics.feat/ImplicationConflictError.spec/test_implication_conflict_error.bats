#!/usr/bin/env bats
# SPEC: ImplicationConflictError.spec
# Tests that the _err_implication_conflict function is defined and produces ERROR output

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "ERR-IMPL-001: _err_implication_conflict function is defined in script" {
    grep -q "_err_implication_conflict" "$SCRIPT"
}
