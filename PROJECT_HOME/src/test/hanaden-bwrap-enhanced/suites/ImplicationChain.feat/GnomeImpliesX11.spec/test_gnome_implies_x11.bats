#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_gnome_implies_x11.bats -- Hanaden AI
# SPEC: GnomeImpliesX11.spec -- gnome -> x11
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

}

_dry() {
    bash "$SCRIPT" start --dry-run "$@" -- /bin/true 2>&1
}

@test "IMP-GNM-001: --gnome-passthrough -> X11 implied" {
    run _dry --gnome-passthrough
    [[ "$output" == *"DISPLAY"* ]] || [[ "$output" == *"X11"* ]] || [[ "$output" == *".X11"* ]]
}
