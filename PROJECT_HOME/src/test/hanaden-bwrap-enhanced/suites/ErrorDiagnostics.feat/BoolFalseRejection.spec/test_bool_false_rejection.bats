#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_bool_false_rejection.bats -- Hanaden AI
# SPEC: BoolFalseAcceptance -- --flag false on any boolean flag -> exit 0 (no-op)
# Strategy spec L100/L247: false is LEGAL. It is the default; passing it
# explicitly is a silent no-op, not an error.

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}
_dry() { bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1; }

@test "BFALSE-001: --net-passthrough false silently accepted" {
    run _dry --net-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-002: --env-passthrough false silently accepted" {
    run _dry --env-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-003: --x11-passthrough false silently accepted" {
    run _dry --x11-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-004: --wayland-passthrough false silently accepted" {
    run _dry --wayland-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-005: --gnome-passthrough false silently accepted" {
    run _dry --gnome-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-006: --kde-passthrough false silently accepted" {
    run _dry --kde-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-007: --audio-passthrough false silently accepted" {
    run _dry --audio-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-008: --a11y-passthrough false silently accepted" {
    run _dry --a11y-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-009: --dbus-passthrough false silently accepted" {
    run _dry --dbus-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-010: graded --mise-passthrough false silently accepted" {
    run _dry --mise-passthrough false
    [ "$status" -eq 0 ]
}
@test "BFALSE-011: graded --local-bin-passthrough false silently accepted" {
    run _dry --local-bin-passthrough false
    [ "$status" -eq 0 ]
}
