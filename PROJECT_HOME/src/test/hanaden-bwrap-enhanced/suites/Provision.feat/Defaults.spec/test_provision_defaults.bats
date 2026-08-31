#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_defaults.bats -- Hanaden AI
# SPEC: Provision.feat/Defaults -- default parameter behavior
# REF:  SCOPE-very-narrow.md ### provision
#
# Tests: default virtual-user-name, default host-real-home-parent,
#        minimal invocation with only --host-real-root, defaults vs. custom
#        interaction, dry-run defaults in output.
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

# ---------------------------------------------------------------------------
# Default virtual-user-name
# ---------------------------------------------------------------------------

@test "PROV-DFLT-001: default user is sandbox_user (home at ROOT/home/sandbox_user)" {
    local root="${WORK}/d1"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/sandbox_user" ]
}

# ---------------------------------------------------------------------------
# Default host-real-home-parent
# ---------------------------------------------------------------------------

@test "PROV-DFLT-002: default home parent is ROOT/home (home at ROOT/home/USER)" {
    local root="${WORK}/d2"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/sandbox_user" ]
}

# ---------------------------------------------------------------------------
# Custom root changes where everything goes
# ---------------------------------------------------------------------------

@test "PROV-DFLT-003: custom root places ALL dirs under that root" {
    local root="${WORK}/custom-root"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/usr" ]
    [ -d "${root}/etc" ]
    [ -d "${root}/home" ]
    [ -d "${root}/proc" ]
    [ -d "${root}/dev" ]
    [ -d "${root}/tmp" ]
    [ -d "${root}/run" ]
    [ -d "${root}/opt" ]
    [ -d "${root}/var" ]
}

# ---------------------------------------------------------------------------
# Custom user changes ONLY home subdir name
# ---------------------------------------------------------------------------

@test "PROV-DFLT-004: custom user changes ONLY home subdir (dirs unaffected)" {
    local root="${WORK}/d4"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --virtual-user-name alice 2>&1
    [ "$status" -eq 0 ]
    # Home subdir changed
    [ -d "${root}/home/alice" ]
    [ ! -d "${root}/home/sandbox_user" ]
    # All 9 dirs still present
    [ -d "${root}/usr" ]
    [ -d "${root}/var" ]
}

# ---------------------------------------------------------------------------
# Custom home parent changes ONLY home location
# ---------------------------------------------------------------------------

@test "PROV-DFLT-005: custom home parent changes only where home is" {
    local root="${WORK}/d5"
    local hp="${WORK}/ext-home"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --host-real-home-parent "$hp" 2>&1
    [ "$status" -eq 0 ]
    # Home at external location
    [ -d "${hp}/sandbox_user" ]
    # Skeleton dirs still under root
    [ -d "${root}/usr" ]
    [ -d "${root}/etc" ]
    [ -L "${root}/bin" ]
}

# ---------------------------------------------------------------------------
# Minimal invocation (only --host-real-root)
# ---------------------------------------------------------------------------

@test "PROV-DFLT-006: provision with ONLY --host-real-root exits 0" {
    local root="${WORK}/minimal"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
}

@test "PROV-DFLT-007: minimal invocation creates all 9 dirs" {
    local root="${WORK}/minimal2"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    local dirs=( usr etc home proc dev tmp run opt var )
    for d in "${dirs[@]}"; do
        [ -d "${root}/${d}" ]
    done
}

@test "PROV-DFLT-008: minimal invocation creates all 3 symlinks" {
    local root="${WORK}/minimal3"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -L "${root}/bin" ]
    [ "$(readlink "${root}/bin")" = "usr/bin" ]
    [ -L "${root}/lib" ]
    [ "$(readlink "${root}/lib")" = "usr/lib" ]
    [ -L "${root}/lib64" ]
    [ "$(readlink "${root}/lib64")" = "usr/lib64" ]
}

@test "PROV-DFLT-009: minimal invocation creates home at ROOT/home/sandbox_user" {
    local root="${WORK}/minimal4"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/sandbox_user" ]
}

# ---------------------------------------------------------------------------
# Default interaction: --virtual-user-name without --host-real-home-parent
# ---------------------------------------------------------------------------

@test "PROV-DFLT-010: custom user + default home parent -> ROOT/home/custom-user" {
    local root="${WORK}/d10"
    run bash "$SCRIPT" provision --host-real-root "$root" \
        --virtual-user-name alice 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/alice" ]
}

# ---------------------------------------------------------------------------
# Dry-run defaults in output
# ---------------------------------------------------------------------------

@test "PROV-DFLT-011: dry-run with only --host-real-root mentions sandbox_user" {
    local root="${WORK}/dry-def"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"sandbox_user"* ]]
}

@test "PROV-DFLT-012: dry-run with only --host-real-root mentions root path" {
    local root="${WORK}/dry-root-check"
    run bash "$SCRIPT" provision --host-real-root "$root" --dry-run 2>&1
    [[ "$output" == *"$root"* ]]
}
