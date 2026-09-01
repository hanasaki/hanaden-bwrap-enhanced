#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fake_group.bats -- Hanaden AI
# SPEC: FakeGroup.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "ID-GR-001: --ro-bind-data 10 /etc/group in dry-run" {
    run _dry
    [[ "$output" == *"--ro-bind-data"* ]]
    [[ "$output" == *"/etc/group"* ]]
}
