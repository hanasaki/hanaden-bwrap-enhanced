#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bool_false_rejection.bats -- Hanaden AI
# SPEC: BoolFalseRejection — --flag false on any boolean flag → [ERROR] exit 1
# false is implicit (default deny); specifying it is an error.

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "BFALSE-001: --net-passthrough false rejected" {
    run bash "$SCRIPT" start --net-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-002: --env-passthrough false rejected" {
    run bash "$SCRIPT" start --env-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-003: --x11-passthrough false rejected" {
    run bash "$SCRIPT" start --x11-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-004: --wayland-passthrough false rejected" {
    run bash "$SCRIPT" start --wayland-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-005: --gnome-passthrough false rejected" {
    run bash "$SCRIPT" start --gnome-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-006: --kde-passthrough false rejected" {
    run bash "$SCRIPT" start --kde-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-007: --audio-passthrough false rejected" {
    run bash "$SCRIPT" start --audio-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-008: --a11y-passthrough false rejected" {
    run bash "$SCRIPT" start --a11y-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-009: --dbus-passthrough false rejected" {
    run bash "$SCRIPT" start --dbus-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-010: graded --mise-passthrough false rejected" {
    run bash "$SCRIPT" start --mise-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "BFALSE-011: graded --local-bin-passthrough false rejected" {
    run bash "$SCRIPT" start --local-bin-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
