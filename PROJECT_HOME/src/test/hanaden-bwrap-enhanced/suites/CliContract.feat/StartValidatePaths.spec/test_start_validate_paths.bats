#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_start_validate_paths.bats -- Hanaden AI
# SPEC: start --validate validates flags AND paths
# REF:  SCOPE-very-narrow.md ### start --validate
#   "Validate flags and paths, do not run bwrap"
#   Missing root/home -> [FATAL] exit 2
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
}
teardown() { rm -rf "$WORK"; }

# --- --validate should validate paths ---

@test "START-VALP-001: --validate with missing root exits non-zero" {
    run bash "$SCRIPT" start --validate \
        --host-real-root "/nonexistent/root/$(date +%N)" \
        -- /bin/true
    [ "$status" -ne 0 ]
}

@test "START-VALP-002: --validate with missing root exits 2 (FATAL)" {
    run bash "$SCRIPT" start --validate \
        --host-real-root "/nonexistent/root/$(date +%N)" \
        -- /bin/true
    [ "$status" -eq 2 ]
}

@test "START-VALP-003: --validate with missing root emits [FATAL]" {
    run bash "$SCRIPT" start --validate \
        --host-real-root "/nonexistent/root/$(date +%N)" \
        -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
}

@test "START-VALP-004: --validate with existing root+home exits 0" {
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
    run bash "$SCRIPT" start --validate \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [ "$status" -eq 0 ]
}

@test "START-VALP-005: --validate with root but missing home exits 2" {
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" start --validate \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [ "$status" -eq 2 ]
}

# --- Missing root exit code drift: should be 2 (FATAL), not 1 ---

@test "START-EXIT-001: missing root exits 2 (FATAL), not 1" {
    run bash "$SCRIPT" start \
        --host-real-root "/nonexistent/root/$(date +%N)" \
        -- /bin/true
    [ "$status" -eq 2 ]
}

@test "START-EXIT-002: missing root emits [FATAL]" {
    run bash "$SCRIPT" start \
        --host-real-root "/nonexistent/root/$(date +%N)" \
        -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
}

@test "START-EXIT-003: missing home exits 2 (FATAL)" {
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
    rm -rf "${ROOT}/home/testuser"
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [ "$status" -eq 2 ]
}
