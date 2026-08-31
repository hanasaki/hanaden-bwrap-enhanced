#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_wrong_qualifier_graded.bats -- Hanaden AI
# SPEC: WrongQualifierGraded — graded flag passed true → [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "WQGRAD-001: --mise-passthrough true rejected" {
    run bash "$SCRIPT" start --mise-passthrough true --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "WQGRAD-002: --local-bin-passthrough true rejected" {
    run bash "$SCRIPT" start --local-bin-passthrough true --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
