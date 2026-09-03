#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_log_level.bats -- Hanaden AI
# SPEC: Provision.feat/LogLevel -- --log-level flag integration
# REF:  SCOPE-very-narrow.md ### provision -- --log-level
#       Log levels: FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)
#
# Provision emits [INFO] and [DEBUG] lines on stderr.
# At DEBUG level, per-directory creation lines appear.
# At FATAL level, only [FATAL] messages appear.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

@test "PROV-LL-001: --log-level INFO succeeds (exit 0)" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level INFO
    [ "$status" -eq 0 ]
}

@test "PROV-LL-002: --log-level DEBUG succeeds (exit 0)" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level DEBUG
    [ "$status" -eq 0 ]
}

@test "PROV-LL-003: --log-level 400 (numeric INFO) succeeds" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level 400
    [ "$status" -eq 0 ]
}

@test "PROV-LL-004: --log-level DEBUG emits [DEBUG] lines" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level DEBUG
    [[ "$output" == *"[DEBUG]"* ]]
}

@test "PROV-LL-005: --log-level INFO does NOT emit [DEBUG] lines" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level INFO
    [[ "$output" != *"[DEBUG]"* ]]
}

@test "PROV-LL-006: --log-level INFO emits [INFO] lines" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level INFO
    [[ "$output" == *"[INFO]"* ]]
}

@test "PROV-LL-007: --log-level WARN does NOT emit [INFO] lines" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level WARN
    [[ "$output" != *"[INFO]"* ]]
}

@test "PROV-LL-008: --log-level FATAL on success emits no output" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level FATAL
    [ -z "$output" ]
}

@test "PROV-LL-009: --log-level FATAL on existing root still emits [FATAL]" {
    local root="${WORK}/existing"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level FATAL
    [ "$status" -eq 2 ]
    [[ "$output" == *"[FATAL]"* ]]
}

@test "PROV-LL-010: --log-level TRACE succeeds (exit 0)" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level TRACE
    [ "$status" -eq 0 ]
}

@test "PROV-LL-011: --log-level 500 (numeric DEBUG) emits [DEBUG]" {
    local root="${WORK}/r"
    run bash "$SCRIPT" provision --host-real-root "$root" --log-level 500
    [[ "$output" == *"[DEBUG]"* ]]
}
