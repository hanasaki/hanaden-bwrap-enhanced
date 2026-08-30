#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_graded_flag_parsing.bats -- Hanaden AI
# SPEC: GradedFlagParsing.spec -- graded flags: off/ro/rw
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() {
    bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1
}

# ---------------------------------------------------------------------------
@test "CLI-GRAD-001: --mise-passthrough bare -> mise bind appears" {
    run _dry --mise-passthrough
    # When mise-passthrough is ro/rw, the dry-run output should mention mise
    [[ "$output" == *"mise"* ]] || [[ "$output" == *"MISE"* ]]
}

@test "CLI-GRAD-002: --mise-passthrough rw -> mise bind appears" {
    run _dry --mise-passthrough rw
    [[ "$output" == *"mise"* ]] || [[ "$output" == *"MISE"* ]]
}

@test "CLI-GRAD-003: default (no mise flag) -> no mise bind" {
    run _dry
    # Default MISE_PASSTHROUGH=off, so no mise-related binds
    [[ "$output" != *".local/share/mise"* ]]
}
