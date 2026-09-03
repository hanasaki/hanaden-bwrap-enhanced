#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_dry_run.bats -- Hanaden AI
# SPEC: Provision.feat/DryRun -- --dry-run flag behavior
# REF:  SCOPE-very-narrow.md ### provision -- -n, --dry-run
#       SCOPE caution: ZERO SIDE EFFECTS in dry-run
#
# dry-run contract:
#   - exits 0
#   - creates NO files or directories on disk
#   - prints [DRY RUN] lines describing what would happen
#   - skips the idempotency gate (root-exists check)
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

@test "PROV-DRY-001: --dry-run exits 0" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [ "$status" -eq 0 ]
}

@test "PROV-DRY-002: -n exits 0" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root" -n
    [ "$status" -eq 0 ]
}

@test "PROV-DRY-003: --dry-run creates NO root directory" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [ ! -e "$root" ]
}

@test "PROV-DRY-004: --dry-run creates NO files anywhere under WORK" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    # Only WORK itself should exist, nothing inside it
    local count
    count="$(find "$WORK" -mindepth 1 | wc -l)"
    [ "$count" -eq 0 ]
}

@test "PROV-DRY-005: --dry-run output contains [DRY RUN]" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [[ "$output" == *"[DRY RUN]"* ]]
}

@test "PROV-DRY-006: --dry-run output mentions the root path" {
    local root="${WORK}/new-root"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [[ "$output" == *"$root"* ]]
}

@test "PROV-DRY-007: --dry-run on existing root exits 0 (gate skipped)" {
    local root="${WORK}/existing"
    mkdir -p "$root"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    [ "$status" -eq 0 ]
}

@test "PROV-DRY-008: --dry-run on existing root does not modify it" {
    local root="${WORK}/existing"
    mkdir -p "$root"
    # Record contents before
    local before after
    before="$(find "$root" | sort)"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run
    after="$(find "$root" | sort)"
    [ "$before" = "$after" ]
}
