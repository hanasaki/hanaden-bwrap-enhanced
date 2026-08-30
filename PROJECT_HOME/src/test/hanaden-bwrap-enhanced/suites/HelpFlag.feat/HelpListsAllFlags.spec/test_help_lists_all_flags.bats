#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}
_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "HLP-LIST-001: --help lists all major CLI flags" {
    run bash "$SCRIPT" --help
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
    [[ "$output" == *"--virtual-user-name"* ]]
    [[ "$output" == *"--host-real-root"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--validate"* ]]
}
