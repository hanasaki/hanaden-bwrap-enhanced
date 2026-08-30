#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "GNOME-SVC-001: --gnome-passthrough -> gvfs bound" {
    run _dry --gnome-passthrough
    [[ "$output" == *"gvfs"* ]]
}

@test "GNOME-SVC-002: --gnome-passthrough -> dconf bound" {
    run _dry --gnome-passthrough
    [[ "$output" == *"dconf"* ]]
}

@test "GNOME-SVC-003: --gnome-passthrough -> keyring bound" {
    run _dry --gnome-passthrough
    [[ "$output" == *"keyring"* ]]
}
