#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_unexpected_entries.bats -- Hanaden AI
# SPEC: Fsck.feat/UnexpectedEntries -- fsck check #8: unexpected top-level entries
# REF:  SCOPE-very-narrow.md ### fsck checks #8 -- warn only, never auto-removed
#
# Expected top-level entries: usr etc home proc dev tmp run opt var bin lib lib64
# Any extra entry -> [WARN], exit code unchanged (0 if otherwise clean)
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
teardown() { rm -rf "$WORK"; }

@test "FSCK-UNEX-001: unexpected file emits [WARN]" {
    touch "${ROOT}/intruder"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[WARN]"* ]]
}

@test "FSCK-UNEX-002: unexpected file does NOT change exit code (still 0)" {
    touch "${ROOT}/intruder"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-UNEX-003: unexpected dir emits [WARN]" {
    mkdir "${ROOT}/surprise"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[WARN]"* ]]
}

@test "FSCK-UNEX-004: unexpected entry is NOT auto-removed by -a" {
    touch "${ROOT}/intruder"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    # entry must still exist -- -a must NOT remove it
    [ -e "${ROOT}/intruder" ]
}

@test "FSCK-UNEX-005: unexpected entry with -a still exits 0 (no error bit set)" {
    touch "${ROOT}/intruder"
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-UNEX-006: unexpected symlink emits [WARN] and is not removed" {
    ln -s /dev/null "${ROOT}/odd-symlink"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"[WARN]"* ]]
    [ -L "${ROOT}/odd-symlink" ]
}

@test "FSCK-UNEX-007: [WARN] message mentions the unexpected entry name" {
    touch "${ROOT}/intruder"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    [[ "$output" == *"intruder"* ]]
}

@test "FSCK-UNEX-008: multiple unexpected entries each get a [WARN]" {
    touch "${ROOT}/a" "${ROOT}/b" "${ROOT}/c"
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name testuser
    # count [WARN] lines (each unexpected entry should produce one)
    local warn_count
    warn_count="$(printf '%s\n' "$output" | grep -c '\[WARN\]')"
    [ "$warn_count" -ge 3 ]
}

@test "FSCK-UNEX-009: unexpected entry combined with other errors -- exit code reflects other errors" {
    touch "${ROOT}/intruder"
    rm -rf "${ROOT}/proc"   # adds error bit 1
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" --virtual-user-name testuser
    # proc missing -> exit 1; intruder -> warn only, no bit change
    [ "$status" -eq 1 ]
}
