#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_missing_root_fatal.bats -- Hanaden AI
# SPEC: MissingRootFatal.spec -- missing root dir -> ERROR exit 1
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_run_missing_root() {
    BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" \
        --host-real-root "/nonexistent/zse/$(date +%N)" "$@" -- /bin/true 2>&1
}

@test "ZSE-ROOT-001: missing root dir -- exit 1" {
    run _run_missing_root
    [ "$status" -eq 1 ]
}

@test "ZSE-ROOT-002: missing root dir -- [ERROR] in stderr" {
    run _run_missing_root
    [[ "$output" == *"[ERROR]"* ]]
}

@test "ZSE-ROOT-003: missing root dir -- mkdir hint in stderr" {
    run _run_missing_root
    [[ "$output" == *"mkdir"* ]]
}
