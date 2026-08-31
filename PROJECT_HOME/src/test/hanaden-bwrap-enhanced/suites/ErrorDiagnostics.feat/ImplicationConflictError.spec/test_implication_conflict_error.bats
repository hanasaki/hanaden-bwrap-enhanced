#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_implication_conflict_error.bats -- Hanaden AI
# SPEC: ImplicationConflictError — explicit --x11-passthrough with an implicating flag → [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "IMPL-001: --wayland-passthrough + --x11-passthrough explicit rejected" {
    run bash "$SCRIPT" start --wayland-passthrough --x11-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "IMPL-002: --gnome-passthrough + --x11-passthrough explicit rejected" {
    run bash "$SCRIPT" start --gnome-passthrough --x11-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "IMPL-003: --kde-passthrough + --x11-passthrough explicit rejected" {
    run bash "$SCRIPT" start --kde-passthrough --x11-passthrough --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "IMPL-004: --wayland-passthrough alone (x11 implied, not explicit) accepted" {
    run bash "$SCRIPT" start --wayland-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "IMPL-005: --gnome-passthrough alone (x11 implied, not explicit) accepted" {
    run bash "$SCRIPT" start --gnome-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "IMPL-006: --kde-passthrough alone (x11 implied, not explicit) accepted" {
    run bash "$SCRIPT" start --kde-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "IMPL-007: --x11-passthrough alone (no implicator) accepted" {
    run bash "$SCRIPT" start --x11-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "IMPL-008: --dbus-passthrough alone always accepted (never implied)" {
    run bash "$SCRIPT" start --dbus-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "IMPL-009: --wayland-passthrough + --dbus-passthrough accepted (dbus never implied)" {
    run bash "$SCRIPT" start --wayland-passthrough --dbus-passthrough --dry-run
    [ "$status" -eq 0 ]
}
