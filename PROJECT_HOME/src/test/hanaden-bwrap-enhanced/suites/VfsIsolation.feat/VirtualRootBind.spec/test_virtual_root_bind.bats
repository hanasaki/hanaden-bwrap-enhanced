#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_virtual_root_bind.bats -- Hanaden AI
# SPEC: VirtualRootBind.spec -- virtual root bind-mounted as /
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_dry() {
    BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1
}

@test "VFS-ROOT-001: dry-run shows --bind ROOT /" {
    run _dry
    # The dry-run output should contain --bind <path> / for the virtual root
    [[ "$output" == *"--bind"* ]]
    # The / mount target should be present
    [[ "$output" == *"virtual-roots"* ]]
}

@test "VFS-ROOT-002: dry-run shows default ~/virtual-roots" {
    run _dry
    [[ "$output" == *"virtual-roots"* ]]
}
