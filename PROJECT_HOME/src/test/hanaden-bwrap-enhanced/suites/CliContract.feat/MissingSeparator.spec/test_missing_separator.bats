#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_missing_separator.bats -- Hanaden AI
# SPEC: MissingSeparator.spec -- CMD without -- -> ERROR exit 1
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_run_missing_sep() {
    bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
@test "CLI-SEP-001: /bin/true without -- separator -- exit 1" {
    run _run_missing_sep /bin/true
    [ "$status" -eq 1 ]
}

@test "CLI-SEP-002: /bin/true without -- -- stderr contains [ERROR]" {
    run _run_missing_sep /bin/true
    [[ "$output" == *"[ERROR]"* ]]
}

@test "CLI-SEP-003: /bin/true without -- -- stderr mentions separator" {
    run _run_missing_sep /bin/true
    [[ "$output" == *"separator"* ]] || [[ "$output" == *"--"* ]]
}
