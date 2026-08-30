#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fake_profile.bats -- Hanaden AI
# SPEC: FakeProfile.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "ID-PROF-001: --ro-bind-data 11 /etc/profile in dry-run" {
    run _dry
    [[ "$output" == *"/etc/profile"* ]]
}
