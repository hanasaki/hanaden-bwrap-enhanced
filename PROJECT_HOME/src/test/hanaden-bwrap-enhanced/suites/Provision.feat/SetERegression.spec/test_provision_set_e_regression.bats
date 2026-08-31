#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_set_e_regression.bats -- Hanaden AI
# SPEC: Provision.feat/SetERegression -- set -e hazard regression tests
# REF:  SCOPE-very-narrow.md ### provision
#
# Regression: cmd_provision had two [[ ]] && cmd patterns at statement level
# that triggered set -e when the condition was false, silently aborting the
# function before _provision_create_skeleton was called.
#
# Fixed paths exercised here:
#   L419: [[ -z host_real_home_parent ]] && home_parent=...
#         When --host-real-home-parent IS explicitly set, [[ ]] is false.
#         Must NOT trigger set -e -- skeleton must still be created.
#   L421: [[ dry_run == false ]] && _provision_validate ...
#         When --dry-run is set, [[ ]] is false.
#         Must NOT trigger set -e -- dry-run output must still be emitted.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    HOMEPARENT="${WORK}/homes"
}
teardown() { rm -rf "$WORK"; }

# ---------------------------------------------------------------------------
# L419 regression: --host-real-home-parent explicitly set
# ---------------------------------------------------------------------------

@test "PROV-SETE-001: explicit --host-real-home-parent exits 0 (L419 regression)" {
    run bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser
    [ "$status" -eq 0 ]
}

@test "PROV-SETE-002: explicit --host-real-home-parent creates skeleton dirs (L419 regression)" {
    bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser
    [ -d "${ROOT}/usr" ]
    [ -d "${ROOT}/etc" ]
    [ -d "${ROOT}/home" ]
    [ -d "${ROOT}/tmp" ]
    [ -d "${ROOT}/var" ]
}

@test "PROV-SETE-003: explicit --host-real-home-parent creates symlinks (L419 regression)" {
    bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser
    [ "$(readlink "${ROOT}/bin")"   = "usr/bin"   ]
    [ "$(readlink "${ROOT}/lib")"   = "usr/lib"   ]
    [ "$(readlink "${ROOT}/lib64")" = "usr/lib64" ]
}

@test "PROV-SETE-004: explicit --host-real-home-parent creates user home at HOMEPARENT/user (L419 regression)" {
    bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser
    [ -d "${HOMEPARENT}/testuser" ]
}

@test "PROV-SETE-005: explicit --host-real-home-parent does NOT create home under ROOT/home (L419 regression)" {
    bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser
    [ ! -d "${ROOT}/home/testuser" ]
}

# ---------------------------------------------------------------------------
# L421 regression: --dry-run path (condition is false -> set -e hazard)
# ---------------------------------------------------------------------------

@test "PROV-SETE-006: --dry-run with explicit --host-real-home-parent exits 0 (L421+L419 regression)" {
    run bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser \
        --dry-run
    [ "$status" -eq 0 ]
}

@test "PROV-SETE-007: --dry-run with explicit --host-real-home-parent emits [DRY RUN] (L421 regression)" {
    run bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser \
        --dry-run
    [[ "$output" == *"[DRY RUN]"* ]]
}

@test "PROV-SETE-008: --dry-run with explicit --host-real-home-parent creates nothing (L421 regression)" {
    run bash "$SCRIPT" provision \
        --host-real-root        "$ROOT" \
        --host-real-home-parent "$HOMEPARENT" \
        --virtual-user-name     testuser \
        --dry-run
    [ ! -d "$ROOT" ]
    [ ! -d "$HOMEPARENT" ]
}
