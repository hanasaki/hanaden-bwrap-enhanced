#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bool_flag_parsing.bats -- Hanaden AI
# SPEC: BoolFlagParsing.spec -- boolean flags: bare/true/false
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() {
    bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1
}

# ---------------------------------------------------------------------------
@test "CLI-BOOL-001: --net-passthrough bare -> no --unshare-net" {
    run _dry --net-passthrough
    [[ "$output" != *"--unshare-net"* ]]
}

@test "CLI-BOOL-002: --net-passthrough true -> no --unshare-net" {
    run _dry --net-passthrough true
    [[ "$output" != *"--unshare-net"* ]]
}

@test "CLI-BOOL-003: --net-passthrough false -> rejected (false is implicit)" {
    run _dry --net-passthrough false
    # false is rejected because absence of the flag already means false
    [ "$status" -eq 1 ] || [[ "$output" == *"[ERROR]"* ]]
}

@test "CLI-BOOL-004: --env-passthrough bare -> no --clearenv" {
    run _dry --env-passthrough
    [[ "$output" != *"--clearenv"* ]]
}

@test "CLI-BOOL-005: default (no env flag) -> --clearenv present" {
    run _dry
    [[ "$output" == *"--clearenv"* ]]
}
