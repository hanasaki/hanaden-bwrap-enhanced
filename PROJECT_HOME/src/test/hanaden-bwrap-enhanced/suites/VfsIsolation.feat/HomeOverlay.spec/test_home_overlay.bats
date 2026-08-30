#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_home_overlay.bats -- Hanaden AI
# SPEC: HomeOverlay.spec
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    export BWRAP_SKIP_PREFLIGHT=1
}

_dry() { BWRAP_SKIP_PREFLIGHT=1 bash "$SCRIPT" --dry-run "$@" -- /bin/true 2>&1; }

@test "VFS-HOME-001: --tmpfs /home" {
    run _dry
    [[ "$output" == *"--tmpfs"* ]]
    [[ "$output" == *"/home"* ]]
}

@test "VFS-HOME-002: --dir /home/sandbox_user" {
    run _dry
    [[ "$output" == *"/home/sandbox_user"* ]]
}
