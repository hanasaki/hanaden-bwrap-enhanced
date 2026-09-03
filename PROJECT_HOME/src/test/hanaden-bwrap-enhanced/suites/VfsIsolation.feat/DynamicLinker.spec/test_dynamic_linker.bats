#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_dynamic_linker.bats -- Hanaden AI
# SPEC: DynamicLinker.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-LD-001: ld.so.cache bound" {
    run _dry
    [[ "$output" == *"/etc/ld.so.cache"* ]]
}
