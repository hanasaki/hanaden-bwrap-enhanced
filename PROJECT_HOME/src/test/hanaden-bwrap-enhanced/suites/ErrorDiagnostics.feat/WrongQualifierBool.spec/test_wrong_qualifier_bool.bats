#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_wrong_qualifier_bool.bats -- Hanaden AI
# SPEC: WrongQualifierBool — boolean flag passed ro|rw → [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "WQBOOL-001: --net-passthrough ro rejected" {
    run bash "$SCRIPT" start --net-passthrough ro --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "WQBOOL-002: --net-passthrough rw rejected" {
    run bash "$SCRIPT" start --net-passthrough rw --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "WQBOOL-003: --wayland-passthrough ro rejected" {
    run bash "$SCRIPT" start --wayland-passthrough ro --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "WQBOOL-004: --audio-passthrough rw rejected" {
    run bash "$SCRIPT" start --audio-passthrough rw --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "WQBOOL-005: --dbus-passthrough ro rejected" {
    run bash "$SCRIPT" start --dbus-passthrough ro --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "WQBOOL-006: --a11y-passthrough rw rejected" {
    run bash "$SCRIPT" start --a11y-passthrough rw --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
