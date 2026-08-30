#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PORT-PND-001: script name derived via basename not hardcoded" {
    # Script uses basename "$0" to derive its own name dynamically
    grep -q 'basename "$0"' "$SCRIPT"
}
