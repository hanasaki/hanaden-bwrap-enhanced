#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_tls_certificates.bats -- Hanaden AI
# SPEC: TlsCertificates.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-TLS-001: /etc/ssl bound" {
    run _dry
    [[ "$output" == *"/etc/ssl"* ]]
}

@test "VFS-TLS-002: /etc/pki bound" {
    run _dry
    [[ "$output" == *"/etc/pki"* ]]
}
