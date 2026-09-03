#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_usr_merge_symlinks.bats -- Hanaden AI
# SPEC: UsrMergeSymlinks.spec -- usr-merge symlinks
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() {
    bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1
}

@test "VFS-USR-001: dry-run shows --ro-bind /usr /usr" {
    run _dry
    [[ "$output" == *"--ro-bind"* ]]
    [[ "$output" == *"/usr"* ]]
}

@test "VFS-USR-002: dry-run shows --symlink usr/lib /lib" {
    run _dry
    [[ "$output" == *"--symlink"* ]]
    [[ "$output" == *"usr/lib"* ]]
}

@test "VFS-USR-003: dry-run shows --symlink usr/bin /bin" {
    run _dry
    [[ "$output" == *"usr/bin"* ]]
}
