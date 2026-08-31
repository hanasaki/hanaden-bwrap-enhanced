#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_virtual_root_bind.bats -- Hanaden AI
# SPEC: VirtualRootBind.spec -- virtual root bind-mounted as /
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/root"
    bash "$SCRIPT" provision --host-real-root "$ROOT" 2>/dev/null
}

teardown() {
    rm -rf "$WORK"
}

_dry() {
    bash "$SCRIPT" start --host-real-root "$ROOT" --dry-run "$@" -- /bin/true 2>&1
}

@test "VFS-ROOT-001: dry-run shows [DRY RUN] banner" {
    run _dry
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]]
}

@test "VFS-ROOT-002: dry-run mentions bwrap in output" {
    run _dry
    [ "$status" -eq 0 ]
    [[ "$output" == *"bwrap"* ]]
}
