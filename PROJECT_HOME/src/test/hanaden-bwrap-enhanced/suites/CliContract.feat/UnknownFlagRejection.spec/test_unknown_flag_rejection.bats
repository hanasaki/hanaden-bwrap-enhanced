#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_unknown_flag_rejection.bats -- Hanaden AI
# SPEC: UnknownFlagRejection -- unknown flags on any subcommand -> [ERROR] exit 1

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "UNK-FLAG-001: start unknown flag exits 1" {
    run bash "$SCRIPT" start --not-a-flag --dry-run
    [ "$status" -eq 1 ]
}
@test "UNK-FLAG-002: start unknown flag emits [ERROR]" {
    run bash "$SCRIPT" start --not-a-flag --dry-run
    [[ "$output" == *"[ERROR]"* ]]
}
@test "UNK-FLAG-003: provision unknown flag exits 1" {
    run bash "$SCRIPT" provision --not-a-flag
    [ "$status" -eq 1 ]
}
@test "UNK-FLAG-004: provision unknown flag emits [ERROR]" {
    run bash "$SCRIPT" provision --not-a-flag
    [[ "$output" == *"[ERROR]"* ]]
}
@test "UNK-FLAG-005: fsck unknown flag exits 1" {
    run bash "$SCRIPT" fsck --not-a-flag
    [ "$status" -eq 1 ]
}
@test "UNK-FLAG-006: fsck unknown flag emits [ERROR]" {
    run bash "$SCRIPT" fsck --not-a-flag
    [[ "$output" == *"[ERROR]"* ]]
}
@test "UNK-FLAG-007: stop unknown flag exits 1" {
    run bash "$SCRIPT" stop --not-a-flag
    [ "$status" -eq 1 ]
}
@test "UNK-FLAG-008: ls unknown flag exits 1" {
    run bash "$SCRIPT" ls --not-a-flag
    [ "$status" -eq 1 ]
}
