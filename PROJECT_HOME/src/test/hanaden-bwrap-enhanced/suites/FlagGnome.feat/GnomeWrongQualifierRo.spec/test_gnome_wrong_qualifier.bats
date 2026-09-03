#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }
@test "FGNM-WQ-001: --gnome-passthrough ro -> ERROR exit 1 (wrong qualifier)" {
    run bash "$SCRIPT" start --gnome-passthrough ro -- /bin/true 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

