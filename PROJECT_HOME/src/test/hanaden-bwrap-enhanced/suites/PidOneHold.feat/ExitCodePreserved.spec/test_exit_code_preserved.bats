#!/usr/bin/env bats
# SPEC: ExitCodePreserved.spec -- CMD exit code propagated

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "FH-EXIT-001: exit code preserved via _CMD_EXIT variable" {
    grep -q 'exit "$_CMD_EXIT"' "$SCRIPT"
}
