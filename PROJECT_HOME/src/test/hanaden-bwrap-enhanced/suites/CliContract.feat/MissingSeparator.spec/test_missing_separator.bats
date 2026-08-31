#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_missing_separator.bats -- Hanaden AI
# SPEC: MissingSeparator — `start` without `--` separator → [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "SEP-001: start with no args (no --) exits 1" {
    run bash "$SCRIPT" start
    [ "$status" -eq 1 ]
}
@test "SEP-002: start with no -- emits [ERROR]" {
    run bash "$SCRIPT" start
    [[ "$output" == *"[ERROR]"* ]]
}
@test "SEP-003: start with flags but no -- exits 1" {
    run bash "$SCRIPT" start --net-passthrough
    [ "$status" -eq 1 ]
}
@test "SEP-004: start with flags but no -- emits [ERROR]" {
    run bash "$SCRIPT" start --net-passthrough
    [[ "$output" == *"[ERROR]"* ]]
}
@test "SEP-005: start --dry-run does NOT need -- (no exec path)" {
    run bash "$SCRIPT" start --dry-run
    [ "$status" -eq 0 ]
}
@test "SEP-006: start --validate does NOT need -- (no exec path)" {
    run bash "$SCRIPT" start --validate
    [ "$status" -eq 0 ]
}
