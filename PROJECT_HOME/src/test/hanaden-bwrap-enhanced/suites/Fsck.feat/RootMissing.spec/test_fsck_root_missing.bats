#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_root_missing.bats -- Hanaden AI
# SPEC: Fsck.feat/RootMissing -- fsck check #1: ROOT must exist and be a dir
# REF:  SCOPE-very-narrow.md ### fsck checks #1 -- uncorrectable if not
#       exit code 4 = uncorrectable errors
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() { rm -rf "$WORK"; }

@test "FSCK-ROOT-001: non-existent root exits 4" {
    run bash "$SCRIPT" fsck --host-real-root "${WORK}/does-not-exist"
    [ "$status" -eq 4 ]
}

@test "FSCK-ROOT-002: non-existent root emits [ERROR]" {
    run bash "$SCRIPT" fsck --host-real-root "${WORK}/does-not-exist"
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-ROOT-003: root is a file not a dir exits 4" {
    local root="${WORK}/is-a-file"
    touch "$root"
    run bash "$SCRIPT" fsck --host-real-root "$root"
    [ "$status" -eq 4 ]
}

@test "FSCK-ROOT-004: root is a file not a dir emits [ERROR]" {
    local root="${WORK}/is-a-file"
    touch "$root"
    run bash "$SCRIPT" fsck --host-real-root "$root"
    [[ "$output" == *"[ERROR]"* ]]
}

@test "FSCK-ROOT-005: root is a symlink to a dir exits 0 (symlink to dir is valid)" {
    local real_root="${WORK}/real"
    local link_root="${WORK}/link"
    bash "$SCRIPT" provision --host-real-root "$real_root" --virtual-user-name testuser
    ln -s "$real_root" "$link_root"
    run bash "$SCRIPT" fsck --host-real-root "$link_root" --virtual-user-name testuser
    [ "$status" -eq 0 ]
}

@test "FSCK-ROOT-006: root is a symlink to a file exits 4" {
    local file="${WORK}/a-file"
    local link="${WORK}/link"
    touch "$file"
    ln -s "$file" "$link"
    run bash "$SCRIPT" fsck --host-real-root "$link"
    [ "$status" -eq 4 ]
}

@test "FSCK-ROOT-007: -n on non-existent root still exits 4 (check #1 is uncorrectable)" {
    run bash "$SCRIPT" fsck -n --host-real-root "${WORK}/gone"
    [ "$status" -eq 4 ]
}

@test "FSCK-ROOT-008: -a on non-existent root still exits 4 (root cannot be auto-created)" {
    run bash "$SCRIPT" fsck -a --host-real-root "${WORK}/gone"
    [ "$status" -eq 4 ]
}
