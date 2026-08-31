#!/usr/bin/env bats
# Dispatch.feat/SubcommandHelp — each subcommand's --help exits 0
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "DISP-HELP-001: provision --help exits 0" {
    run bash "$SCRIPT" provision --help
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-002: provision -h exits 0" {
    run bash "$SCRIPT" provision -h
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-003: fsck --help exits 0" {
    run bash "$SCRIPT" fsck --help
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-004: fsck -h exits 0" {
    run bash "$SCRIPT" fsck -h
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-005: start --help exits 0" {
    run bash "$SCRIPT" start --help
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-006: start -h exits 0" {
    run bash "$SCRIPT" start -h
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-007: stop --help exits 0" {
    run bash "$SCRIPT" stop --help
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-008: stop -h exits 0" {
    run bash "$SCRIPT" stop -h
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-009: ls --help exits 0" {
    run bash "$SCRIPT" ls --help
    [ "$status" -eq 0 ]
}

@test "DISP-HELP-010: ls -h exits 0" {
    run bash "$SCRIPT" ls -h
    [ "$status" -eq 0 ]
}
