#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_user_namespace_enabled.bats -- Hanaden AI
# SPEC: UserNamespaceEnabled.spec -- unprivileged user namespaces enabled
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PF-NS-001: bwrap --unshare-user works (namespaces enabled)" {
    run bwrap --ro-bind / / --unshare-user --die-with-parent /bin/true
    [ "$status" -eq 0 ]
}
