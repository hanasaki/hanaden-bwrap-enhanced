#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_duplicate_flag_rejection.bats -- Hanaden AI
# SPEC: DuplicateFlagRejection.spec -- duplicate config flags -> ERROR exit 1
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_run_dup() {
    bash "$SCRIPT" "$@" 2>&1
}

@test "CLI-DUP-001: --virtual-user-name twice -- exit 1" {
    run _run_dup --virtual-user-name alice --virtual-user-name bob -- /bin/true
    [ "$status" -eq 1 ]
}

@test "CLI-DUP-002: --virtual-user-name twice -- [ERROR] in output" {
    run _run_dup --virtual-user-name alice --virtual-user-name bob -- /bin/true
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"more than once"* ]] || [[ "$output" == *"duplicate"* ]] || [[ "$output" == *"twice"* ]]
}

@test "CLI-DUP-003: --host-real-root twice -- exit 1" {
    run _run_dup --host-real-root /tmp --host-real-root /var -- /bin/true
    [ "$status" -eq 1 ]
}
