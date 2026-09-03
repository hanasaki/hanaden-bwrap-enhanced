#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_cli_defaults.bats -- Hanaden AI
# SPEC: CliDefaults -- all flags absent = safest defaults; --dry-run with no flags exits 0

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

@test "DFLT-001: start --dry-run with zero passthrough flags exits 0" {
    run bash "$SCRIPT" start --dry-run
    [ "$status" -eq 0 ]
}
@test "DFLT-002: start --validate with zero passthrough flags exits 0" {
    run bash "$SCRIPT" start --validate
    [ "$status" -eq 0 ]
}
@test "DFLT-003: provision --dry-run with only --host-real-root exits 0 (nonexistent root ok for dry)" {
    run bash "$SCRIPT" provision --host-real-root /tmp/does-not-exist-dflt --dry-run
    [ "$status" -eq 0 ]
}
@test "DFLT-004: all flags absent -- start --dry-run output contains [DRY RUN]" {
    run bash "$SCRIPT" start --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
}
@test "DFLT-005: provision --dry-run output contains [DRY RUN]" {
    run bash "$SCRIPT" provision --host-real-root /tmp/does-not-exist-dflt2 --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
}
