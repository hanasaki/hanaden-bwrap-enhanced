#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_validate_mode.bats -- Hanaden AI
# SPEC: ValidateMode -- start --validate exits 0 (parse only, no preflight, no exec)

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "VAL-001: start --validate exits 0 (no paths checked)" {
    run bash "$SCRIPT" start --validate
    [ "$status" -eq 0 ]
}
@test "VAL-002: start --validate with all bool flags exits 0" {
    run bash "$SCRIPT" start \
        --net-passthrough \
        --wayland-passthrough \
        --audio-passthrough \
        --a11y-passthrough \
        --dbus-passthrough \
        --validate
    [ "$status" -eq 0 ]
}
@test "VAL-003: start --validate with graded flags exits 0" {
    run bash "$SCRIPT" start \
        --mise-passthrough ro \
        --local-bin-passthrough rw \
        --validate
    [ "$status" -eq 0 ]
}
@test "VAL-004: start --validate does NOT require -- CMD separator" {
    run bash "$SCRIPT" start --validate
    [ "$status" -eq 0 ]
}
@test "VAL-005: start --validate flag errors still caught before validate check" {
    run bash "$SCRIPT" start --net-passthrough false --validate
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
