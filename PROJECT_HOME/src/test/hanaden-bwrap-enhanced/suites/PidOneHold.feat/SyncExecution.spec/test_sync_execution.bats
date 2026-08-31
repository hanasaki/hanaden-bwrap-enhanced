#!/usr/bin/env bats
# SPEC: SyncExecution.spec -- CMD runs synchronously in foreground

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "FH-SYNC-001: exec_sandbox runs CMD synchronously (source verifies)" {
    # The exec_sandbox function runs "$@" directly, then captures _CMD_EXIT
    grep -q '"$@"; _CMD_EXIT=' "$SCRIPT"
}
