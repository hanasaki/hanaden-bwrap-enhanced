#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_dry_run_mode.bats -- Hanaden AI
# SPEC: DryRunMode.spec -- --dry-run prints resolved config
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() {
    bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1
}

@test "CLI-DRY-001: --dry-run exits 0" {
    run _dry
    [ "$status" -eq 0 ]
}

@test "CLI-DRY-002: --dry-run outputs bwrap command" {
    run _dry
    [[ "$output" == *"bwrap"* ]]
}

@test "CLI-DRY-003: --dry-run includes DRY-RUN tag" {
    run _dry
    [[ "$output" == *"[DRY-RUN]"* ]] || [[ "$output" == *"DRY-RUN"* ]]
}
