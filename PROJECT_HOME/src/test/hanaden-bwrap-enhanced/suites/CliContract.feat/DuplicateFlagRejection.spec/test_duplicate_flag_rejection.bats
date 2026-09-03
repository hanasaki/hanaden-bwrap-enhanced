#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_duplicate_flag_rejection.bats -- Hanaden AI
# SPEC: DuplicateFlagRejection -- same flag twice on any subcommand -> [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

# start subcommand -- boolean duplicates
@test "DUP-001: start --net-passthrough twice rejected" {
    run bash "$SCRIPT" start --net-passthrough --net-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-002: start --wayland-passthrough twice rejected" {
    run bash "$SCRIPT" start --wayland-passthrough --wayland-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-003: start --audio-passthrough twice rejected" {
    run bash "$SCRIPT" start --audio-passthrough --audio-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-004: start --dbus-passthrough twice rejected" {
    run bash "$SCRIPT" start --dbus-passthrough --dbus-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-005: start --host-real-root twice rejected" {
    run bash "$SCRIPT" start --host-real-root /tmp/a --host-real-root /tmp/b --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-006: start --virtual-user-name twice rejected" {
    run bash "$SCRIPT" start --virtual-user-name alice --virtual-user-name bob --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-007: start --log-level twice rejected" {
    run bash "$SCRIPT" start --log-level INFO --log-level DEBUG --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

# provision subcommand -- duplicates
@test "DUP-008: provision --host-real-root twice rejected" {
    run bash "$SCRIPT" provision --host-real-root /tmp/a --host-real-root /tmp/b
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "DUP-009: provision --virtual-user-name twice rejected" {
    run bash "$SCRIPT" provision --virtual-user-name alice --virtual-user-name bob
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

# fsck subcommand -- duplicates
@test "DUP-010: fsck --host-real-root twice rejected" {
    run bash "$SCRIPT" fsck --host-real-root /tmp/a --host-real-root /tmp/b
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
