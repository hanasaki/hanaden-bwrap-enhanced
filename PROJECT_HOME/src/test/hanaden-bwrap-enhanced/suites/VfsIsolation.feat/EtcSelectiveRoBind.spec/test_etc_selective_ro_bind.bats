#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_etc_selective_ro_bind.bats -- Hanaden AI
# SPEC: EtcSelectiveRoBind.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-ETC-001: dry-run shows --dir /etc" {
    run _dry
    [[ "$output" == *"--dir"* ]]
    [[ "$output" == *"/etc"* ]]
}

@test "VFS-ETC-002: dry-run shows --ro-bind-try /etc/fonts" {
    run _dry
    [[ "$output" == *"/etc/fonts"* ]]
}

@test "VFS-ETC-003: dry-run shows --ro-bind-try /etc/machine-id" {
    run _dry
    [[ "$output" == *"/etc/machine-id"* ]]
}
