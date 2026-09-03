#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_wayland_implies_x11.bats -- Hanaden AI
# SPEC: WaylandImpliesX11.spec -- wayland -> x11
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() {
    bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1
}

@test "IMP-WAY-001: --wayland-passthrough -> X11 implied" {
    run _dry --wayland-passthrough
    # wayland implies x11, so DISPLAY or X11 socket binding should appear
    [[ "$output" == *"DISPLAY"* ]] || [[ "$output" == *"X11"* ]] || [[ "$output" == *".X11"* ]]
}

@test "IMP-WAY-002: default (no wayland) -> no DISPLAY env" {
    run _dry
    # Without X11 passthrough, no DISPLAY env var should be set
    [[ "$output" != *"DISPLAY"* ]]
}
