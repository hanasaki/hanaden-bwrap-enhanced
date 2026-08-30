#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_unknown_flag_rejection.bats -- Hanaden AI
# SPEC: UnknownFlagRejection.spec -- unknown flags -> ERROR exit 1
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_run_unknown() {
    bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
@test "CLI-UNK-001: unknown --foo-bar -- exit 1" {
    run _run_unknown --foo-bar -- /bin/true
    [ "$status" -eq 1 ]
}

@test "CLI-UNK-002: unknown --foo-bar -- stderr contains [ERROR]" {
    run _run_unknown --foo-bar -- /bin/true
    [[ "$output" == *"[ERROR]"* ]]
}

@test "CLI-UNK-003: unknown --foo-bar -- stderr contains flag name" {
    run _run_unknown --foo-bar -- /bin/true
    [[ "$output" == *"--foo-bar"* ]]
}

@test "CLI-UNK-004: unknown -x -- exit 1" {
    run _run_unknown -x -- /bin/true
    [ "$status" -eq 1 ]
}
