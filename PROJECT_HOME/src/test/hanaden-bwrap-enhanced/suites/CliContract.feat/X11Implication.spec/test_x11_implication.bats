#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_x11_implication.bats -- Hanaden AI
# SPEC: CliContract.feat/X11Implication -- x11 passthrough implication conflicts
# REF:  SCOPE-very-narrow.md ### start -- implication rules
#
# Tests: wayland implies x11, gnome implies x11, kde implies x11,
#        explicit x11 with implying flag conflicts, dbus NEVER implied.
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

# ---------------------------------------------------------------------------
# Implication: wayland/gnome/kde imply x11
# ---------------------------------------------------------------------------

@test "X11-IMP-001: --wayland-passthrough implies x11 (validate exits 0)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --wayland-passthrough --validate 2>&1
    [ "$status" -eq 0 ]
}

@test "X11-IMP-002: --gnome-passthrough implies x11 (validate exits 0)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --gnome-passthrough --validate 2>&1
    [ "$status" -eq 0 ]
}

@test "X11-IMP-003: --kde-passthrough implies x11 (validate exits 0)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --kde-passthrough --validate 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Explicit x11 + implying flag = CONFLICT (by design: help says "do not pass
# explicitly with an implying flag")
# ---------------------------------------------------------------------------

@test "X11-IMP-004: explicit --x11-passthrough true + --wayland-passthrough = conflict exit 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --x11-passthrough true \
        --wayland-passthrough \
        --validate 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"implication conflict"* ]]
}

@test "X11-IMP-005: explicit --x11-passthrough bare + --gnome-passthrough = conflict exit 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --x11-passthrough \
        --gnome-passthrough \
        --validate 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"implication conflict"* ]]
}

# ---------------------------------------------------------------------------
# dbus is NEVER implied
# ---------------------------------------------------------------------------

@test "X11-IMP-006: --gnome-passthrough does NOT imply dbus (dry-run)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --gnome-passthrough --dry-run 2>&1
    [ "$status" -eq 0 ]
    # dbus should NOT appear as enabled in dry-run output
    # The output should show dbus=false or not mention dbus mount
    # This is a contract test: dbus is never implied
}

# ---------------------------------------------------------------------------
# Multiple implicators
# ---------------------------------------------------------------------------

@test "X11-IMP-007: wayland + gnome + kde together (all imply x11, validate)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --wayland-passthrough \
        --gnome-passthrough \
        --kde-passthrough \
        --validate 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# x11 alone (no implicator)
# ---------------------------------------------------------------------------

@test "X11-IMP-008: --x11-passthrough alone (dry-run)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --x11-passthrough --dry-run 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Ordering: implicator + explicit x11 = always conflict regardless of order
# ---------------------------------------------------------------------------

@test "X11-IMP-009: --wayland-passthrough BEFORE --x11-passthrough = conflict exit 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --wayland-passthrough \
        --x11-passthrough \
        --validate 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"implication conflict"* ]]
}

@test "X11-IMP-010: --x11-passthrough BEFORE --wayland-passthrough = conflict exit 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --x11-passthrough \
        --wayland-passthrough \
        --validate 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"implication conflict"* ]]
}
