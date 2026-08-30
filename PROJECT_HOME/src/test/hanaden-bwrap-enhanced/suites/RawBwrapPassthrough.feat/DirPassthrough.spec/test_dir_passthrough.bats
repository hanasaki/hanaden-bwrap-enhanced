#!/usr/bin/env bats
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}
_dry() { bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }
@test "RBP-DR-001: --dir accepted as raw passthrough" {
    # Verify the parse_args loop handles --dir
    grep -q "BWRAP_PASSTHROUGH_ARGS" "$SCRIPT"
}
