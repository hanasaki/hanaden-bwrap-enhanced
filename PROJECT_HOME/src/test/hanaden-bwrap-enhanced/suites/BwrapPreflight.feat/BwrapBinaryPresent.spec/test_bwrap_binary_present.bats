#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bwrap_binary_present.bats -- Hanaden AI
# SPEC: BwrapBinaryPresent.spec -- bwrap binary MUST be on PATH
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "PF-BIN-001: bwrap present on PATH" {
    run command -v bwrap
    [ "$status" -eq 0 ]
}

@test "PF-BIN-002: bwrap version returns parseable output" {
    run bwrap --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "PF-BIN-004: script --dry-run passes real preflight" {
    local root
    root="$(mktemp -d)"
    mkdir -p "${root}/home/sandbox_user"
    run bash "$SCRIPT" start --host-real-root "$root" --dry-run -- /bin/true
    rm -rf "$root"
    [ "$status" -eq 0 ]
}
