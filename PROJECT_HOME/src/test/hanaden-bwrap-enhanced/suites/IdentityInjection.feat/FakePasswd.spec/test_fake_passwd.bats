#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fake_passwd.bats -- Hanaden AI
# SPEC: FakePasswd.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "ID-PW-001: --ro-bind-data 9 /etc/passwd in dry-run" {
    run _dry
    [[ "$output" == *"--ro-bind-data"* ]]
    [[ "$output" == *"/etc/passwd"* ]]
}

@test "ID-PW-002: virtual user sandbox_user in passwd context" {
    run _dry
    [[ "$output" == *"sandbox_user"* ]]
}
