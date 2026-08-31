#!/usr/bin/env bats
# SPEC: OrphanReaping.spec
# Orphan reaping logic uses /proc/1/task/1/children in exec_sandbox

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PID1-REAP-001: orphan reaping loop with /proc/1/task/1/children in exec_sandbox" {
    # Verify the reaping pattern exists in the source
    grep -q "/proc/1/task/1/children" "$SCRIPT"
    grep -q "_CMD_EXIT" "$SCRIPT"
}
