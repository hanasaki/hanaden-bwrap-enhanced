#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_missing_home_fatal.bats -- Hanaden AI
# SPEC: MissingHomeFatal.spec -- missing home dir -> ERROR exit 1
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1

    # Create root dir but NOT the home subdir
    VALID_ROOT="$(mktemp -d)"
    # home/sandbox_user intentionally NOT created
}

teardown() {
    [ -d "${VALID_ROOT:-}" ] && rm -rf "$VALID_ROOT"
}

_run_missing_home() {
    BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" \
        --host-real-root "$VALID_ROOT" "$@" -- /bin/true 2>&1
}

@test "ZSE-HOME-001: root exists but home missing -- exit 1" {
    run _run_missing_home
    [ "$status" -eq 1 ]
}

@test "ZSE-HOME-002: root exists but home missing -- [ERROR] in stderr" {
    run _run_missing_home
    [[ "$output" == *"[ERROR]"* ]]
}

@test "ZSE-HOME-003: root exists but home missing -- mkdir hint in stderr" {
    run _run_missing_home
    [[ "$output" == *"mkdir"* ]]
}
