#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_ephemeral_tmpfs.bats -- Hanaden AI
# SPEC: EphemeralTmpfs.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-TMP-001: --tmpfs /dev/shm" {
    run _dry
    [[ "$output" == *"--tmpfs"* ]]
    [[ "$output" == *"/dev/shm"* ]]
}

@test "VFS-TMP-002: --tmpfs /tmp" {
    run _dry
    [[ "$output" == *"/tmp"* ]]
}

@test "VFS-TMP-003: --tmpfs /run/user/UID" {
    run _dry
    [[ "$output" == *"/run/user/"* ]]
}
