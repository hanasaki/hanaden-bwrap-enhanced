#!/usr/bin/env bats
# Dispatch.feat/VersionFlag -- --version and -v
setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "DISP-VER-001: --version exits 0" {
    run bash "$SCRIPT" --version
    [ "$status" -eq 0 ]
}

@test "DISP-VER-002: -v exits 0" {
    run bash "$SCRIPT" -v
    [ "$status" -eq 0 ]
}

@test "DISP-VER-003: --version prints version string" {
    run bash "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"v0.4.1"* ]]
}
