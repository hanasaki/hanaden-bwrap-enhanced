#!/usr/bin/env bats
# SPEC: PureBuiltinLoop.spec -- orphan poll uses bash builtins only

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "FH-BUILTIN-001: orphan loop uses read builtin not external commands" {
    # The loop reads /proc/1/task/1/children via read builtin
    grep -q 'read -r children < /proc/1/task/1/children' "$SCRIPT"
}
