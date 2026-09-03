#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_root_readonly_lock.bats -- Hanaden AI
# SPEC: RootReadonlyLock.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-ROLOCK-001: --remount-ro / present" {
    run _dry
    [[ "$output" == *"--remount-ro"* ]]
}
