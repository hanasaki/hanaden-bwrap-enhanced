#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_operational_error.bats -- Hanaden AI
# SPEC: Fsck.feat/OperationalError -- exit code 8: fsck itself failed to run
# REF:  SCOPE-very-narrow.md ### fsck exit codes:
#   8  Operational error (fsck itself failed to run)
#
# Exit code 8 is for operational errors — internal failures of fsck itself,
# not user-facing problems with the virtual root. Examples: unreadable root
# dir (permissions deny access), internal command failures during checks.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
}
teardown() {
    # Restore permissions so rm -rf can clean up
    chmod -R u+rwx "$WORK" 2>/dev/null || true
    rm -rf "$WORK"
}

# --------------------------------------------------------------------------
# Root exists and is a directory, but is unreadable (chmod 000).
# fsck should detect that it cannot perform checks and exit 8.
# --------------------------------------------------------------------------

@test "FSCK-OPERR-001: unreadable root dir exits 8 (operational error)" {
    chmod 000 "$ROOT"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 8 ]
}

@test "FSCK-OPERR-002: operational error emits [ERROR] with diagnostic" {
    chmod 000 "$ROOT"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-OPERR-003: unreadable root with -f still exits 8" {
    chmod 000 "$ROOT"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser -f
    [ "$status" -eq 8 ]
}

# --------------------------------------------------------------------------
# Root dir is not traversable (no execute bit) — can stat children but
# not list them. This is an operational impediment.
# --------------------------------------------------------------------------

@test "FSCK-OPERR-004: non-traversable root (no +x) exits 8" {
    chmod a-x "$ROOT"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 8 ]
}
