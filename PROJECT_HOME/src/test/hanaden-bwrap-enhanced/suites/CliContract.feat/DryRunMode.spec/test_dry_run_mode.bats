#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_dry_run_mode.bats -- Hanaden AI
# SPEC: DryRunMode -- -n/--dry-run on start and provision exits 0 without side effects

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    TMPROOT="$(mktemp -d)"
}
teardown() {
    rm -rf "$TMPROOT"
}

@test "DRY-001: start --dry-run exits 0" {
    run bash "$SCRIPT" start --dry-run
    [ "$status" -eq 0 ]
}
@test "DRY-002: start -n exits 0" {
    run bash "$SCRIPT" start -n
    [ "$status" -eq 0 ]
}
@test "DRY-003: start --dry-run with flags exits 0" {
    run bash "$SCRIPT" start --net-passthrough --wayland-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "DRY-004: provision --dry-run on nonexistent root exits 0" {
    run bash "$SCRIPT" provision --host-real-root "${TMPROOT}/new-root" --dry-run
    [ "$status" -eq 0 ]
}
@test "DRY-005: provision -n on nonexistent root exits 0" {
    run bash "$SCRIPT" provision --host-real-root "${TMPROOT}/new-root" -n
    [ "$status" -eq 0 ]
}
@test "DRY-006: provision --dry-run does NOT create the root directory" {
    local root="${TMPROOT}/should-not-exist"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [ "$status" -eq 0 ]
    [ ! -d "$root" ]
}
