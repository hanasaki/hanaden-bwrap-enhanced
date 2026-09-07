#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bool_flag_parsing.bats -- Hanaden AI
# SPEC: BoolFlagParsing -- boolean passthrough flags: bare / explicit true / false=legal / wrong-qualifier=error
# All tests operate on `start` which owns all boolean passthrough flags.

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

# ---------------------------------------------------------------------------
# --net-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-NET-001: --net-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --net-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-NET-002: --net-passthrough true accepted (dry-run)" {
    run bash "$SCRIPT" start --net-passthrough true --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-NET-003: --net-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --net-passthrough false --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-NET-004: --net-passthrough ro rejected exit 1" {
    run bash "$SCRIPT" start --net-passthrough ro --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

# ---------------------------------------------------------------------------
# --env-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-ENV-001: --env-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --env-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-ENV-002: --env-passthrough true accepted (dry-run)" {
    run bash "$SCRIPT" start --env-passthrough true --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-ENV-003: --env-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --env-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --x11-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-X11-001: --x11-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --x11-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-X11-002: --x11-passthrough true accepted (dry-run)" {
    run bash "$SCRIPT" start --x11-passthrough true --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-X11-003: --x11-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --x11-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --wayland-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-WAY-001: --wayland-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --wayland-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-WAY-002: --wayland-passthrough true accepted (dry-run)" {
    run bash "$SCRIPT" start --wayland-passthrough true --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-WAY-003: --wayland-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --wayland-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --gnome-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-GNO-001: --gnome-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --gnome-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-GNO-002: --gnome-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --gnome-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --kde-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-KDE-001: --kde-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --kde-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-KDE-002: --kde-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --kde-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --audio-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-AUD-001: --audio-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --audio-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-AUD-002: --audio-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --audio-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --a11y-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-A11-001: --a11y-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --a11y-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-A11-002: --a11y-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --a11y-passthrough false --dry-run
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# --dbus-passthrough
# ---------------------------------------------------------------------------
@test "BOOL-DBU-001: --dbus-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --dbus-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "BOOL-DBU-002: --dbus-passthrough false silently accepted exit 0" {
    run bash "$SCRIPT" start --dbus-passthrough false --dry-run
    [ "$status" -eq 0 ]
}
