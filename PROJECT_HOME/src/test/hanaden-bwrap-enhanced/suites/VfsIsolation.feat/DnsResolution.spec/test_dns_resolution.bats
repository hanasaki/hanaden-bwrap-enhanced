#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_dns_resolution.bats -- Hanaden AI
# SPEC: DnsResolution.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-DNS-001: resolv.conf bound" {
    run _dry
    [[ "$output" == *"/etc/resolv.conf"* ]]
}

@test "VFS-DNS-002: nsswitch.conf bound" {
    run _dry
    [[ "$output" == *"/etc/nsswitch.conf"* ]]
}

@test "VFS-DNS-003: hosts file bound" {
    run _dry
    [[ "$output" == *"/etc/hosts"* ]]
}
