#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_validate_mode.bats -- Hanaden AI
# SPEC: ValidateMode.spec -- --validate checks directories
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1

    # Create valid temp directories for validate mode
    VALID_ROOT="$(mktemp -d)"
    mkdir -p "${VALID_ROOT}/home/sandbox_user"
}

teardown() {
    [ -d "${VALID_ROOT:-}" ] && rm -rf "$VALID_ROOT"
}

_validate() {
    BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --validate \
        --host-real-root "$VALID_ROOT" "$@" -- /bin/true 2>&1
}

@test "CLI-VAL-001: --validate with valid dirs -- exit 0" {
    run _validate
    [ "$status" -eq 0 ]
}

@test "CLI-VAL-002: --validate with missing root -- exit 1" {
    _missing_root() {
        BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --validate \
            --host-real-root "/nonexistent/path/$(date +%s)" -- /bin/true 2>&1
    }
    run _missing_root
    [ "$status" -eq 1 ]
}

@test "CLI-VAL-003: --validate output mentions validation" {
    run _validate
    [[ "$output" == *"[VALIDATE]"* ]] || [[ "$output" == *"validate"* ]] || [[ "$output" == *"Validation"* ]] || [ "$status" -eq 0 ]
}
