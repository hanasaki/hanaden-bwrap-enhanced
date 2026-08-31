#!/usr/bin/env bats
# HLP-LIST: --help emits the full one-liner contract (all subcommands + all flags)
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "HLP-LIST-001: --help lists all subcommands" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"provision"* ]]
    [[ "$output" == *"fsck"* ]]
    [[ "$output" == *"start"* ]]
    [[ "$output" == *"stop"* ]]
    [[ "$output" == *"ls"* ]]
}

@test "HLP-LIST-002: --help shows stub marker for stop and ls" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"stub"* ]]
}

@test "HLP-LIST-003: --help shows version string" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"v0.4.0"* ]]
}

@test "HLP-LIST-004: --help shows all passthrough flags (start section of one-liner)" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--net-passthrough"* ]]
    [[ "$output" == *"--env-passthrough"* ]]
    [[ "$output" == *"--x11-passthrough"* ]]
    [[ "$output" == *"--wayland-passthrough"* ]]
    [[ "$output" == *"--gnome-passthrough"* ]]
    [[ "$output" == *"--kde-passthrough"* ]]
    [[ "$output" == *"--audio-passthrough"* ]]
    [[ "$output" == *"--a11y-passthrough"* ]]
    [[ "$output" == *"--dbus-passthrough"* ]]
    [[ "$output" == *"--mise-passthrough"* ]]
    [[ "$output" == *"--local-bin-passthrough"* ]]
}

@test "HLP-LIST-005: --help shows common options in all subcommand sections" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--virtual-user-name"* ]]
    [[ "$output" == *"--host-real-root"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--validate"* ]]
    [[ "$output" == *"--log-level"* ]]
}
