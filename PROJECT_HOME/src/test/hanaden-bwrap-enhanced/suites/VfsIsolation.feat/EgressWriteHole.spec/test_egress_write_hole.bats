#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_egress_write_hole.bats -- Hanaden AI
# SPEC: EgressWriteHole.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-EGR-001: --bind HOST_HOME /home/USER present" {
    run _dry
    # The egress write-hole binds host home dir to sandbox /home/user
    [[ "$output" == *"--bind"* ]]
    [[ "$output" == *"/home/sandbox_user"* ]]
}
