#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "MISE-BIN-001: --mise-passthrough -> mise binary path in output" {
    run _dry --mise-passthrough
    [[ "$output" == *"mise"* ]]
    [[ "$output" == *".local/bin"* ]] || [[ "$output" == *".local/share/mise"* ]]
}
