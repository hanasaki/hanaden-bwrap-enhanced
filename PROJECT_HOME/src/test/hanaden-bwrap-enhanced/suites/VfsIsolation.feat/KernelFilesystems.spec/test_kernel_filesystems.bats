#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_kernel_filesystems.bats -- Hanaden AI
# SPEC: KernelFilesystems.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-KERN-001: --proc /proc present" {
    run _dry
    [[ "$output" == *"--proc"* ]]
    [[ "$output" == *"/proc"* ]]
}

@test "VFS-KERN-002: --dev-bind /dev /dev present" {
    run _dry
    [[ "$output" == *"--dev-bind"* ]]
    [[ "$output" == *"/dev"* ]]
}
