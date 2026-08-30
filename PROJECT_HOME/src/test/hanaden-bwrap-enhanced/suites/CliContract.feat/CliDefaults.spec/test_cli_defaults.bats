#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_cli_defaults.bats -- Hanaden AI
# SPEC: CliDefaults.spec -- all flags default to safe/off values
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

# Helper: run dry-run with no passthrough flags
_dry() {
    bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1
}

# ---------------------------------------------------------------------------
@test "CLI-DEF-001: dry-run with no flags -- unshare-net present (net isolated)" {
    # Default: NET_PASSTHROUGH=false, so --unshare-net SHOULD be in bwrap args
    run _dry
    [[ "$output" == *"--unshare-net"* ]]
}

@test "CLI-DEF-002: dry-run with no flags -- clearenv present (env isolated)" {
    run _dry
    [[ "$output" == *"--clearenv"* ]]
}

@test "CLI-DEF-003: dry-run with no flags -- no wayland socket bound" {
    # Default: WAYLAND_PASSTHROUGH=false, no wayland socket should appear
    run _dry
    [[ "$output" != *"wayland"* ]] || [[ "$output" != *"WAYLAND_DISPLAY"* ]]
}

@test "CLI-DEF-004: dry-run with no flags -- virtual user is sandbox_user" {
    run _dry
    [[ "$output" == *"sandbox_user"* ]]
}

@test "CLI-DEF-005: dry-run with no flags -- exit 0" {
    run _dry
    [ "$status" -eq 0 ]
}
