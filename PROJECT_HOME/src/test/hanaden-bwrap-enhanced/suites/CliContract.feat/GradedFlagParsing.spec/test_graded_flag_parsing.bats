#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_graded_flag_parsing.bats -- Hanaden AI
# SPEC: GradedFlagParsing -- graded flags: bare=ro / ro / rw / true=error / false=error / duplicate=error

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
}

# ---------------------------------------------------------------------------
# --mise-passthrough
# ---------------------------------------------------------------------------
@test "GRAD-MISE-001: --mise-passthrough bare accepted as ro (dry-run)" {
    run bash "$SCRIPT" start --mise-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "GRAD-MISE-002: --mise-passthrough ro accepted (dry-run)" {
    run bash "$SCRIPT" start --mise-passthrough ro --dry-run
    [ "$status" -eq 0 ]
}
@test "GRAD-MISE-003: --mise-passthrough rw accepted (dry-run)" {
    run bash "$SCRIPT" start --mise-passthrough rw --dry-run
    [ "$status" -eq 0 ]
}
@test "GRAD-MISE-004: --mise-passthrough true rejected exit 1" {
    run bash "$SCRIPT" start --mise-passthrough true --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "GRAD-MISE-005: --mise-passthrough false rejected exit 1" {
    run bash "$SCRIPT" start --mise-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "GRAD-MISE-006: --mise-passthrough duplicate rejected exit 1" {
    run bash "$SCRIPT" start --mise-passthrough ro --mise-passthrough rw --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

# ---------------------------------------------------------------------------
# --local-bin-passthrough
# ---------------------------------------------------------------------------
@test "GRAD-BIN-001: --local-bin-passthrough bare accepted (dry-run)" {
    run bash "$SCRIPT" start --local-bin-passthrough --dry-run
    [ "$status" -eq 0 ]
}
@test "GRAD-BIN-002: --local-bin-passthrough ro accepted (dry-run)" {
    run bash "$SCRIPT" start --local-bin-passthrough ro --dry-run
    [ "$status" -eq 0 ]
}
@test "GRAD-BIN-003: --local-bin-passthrough rw accepted (dry-run)" {
    run bash "$SCRIPT" start --local-bin-passthrough rw --dry-run
    [ "$status" -eq 0 ]
}
@test "GRAD-BIN-004: --local-bin-passthrough true rejected exit 1" {
    run bash "$SCRIPT" start --local-bin-passthrough true --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "GRAD-BIN-005: --local-bin-passthrough false rejected exit 1" {
    run bash "$SCRIPT" start --local-bin-passthrough false --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
@test "GRAD-BIN-006: --local-bin-passthrough duplicate rejected exit 1" {
    run bash "$SCRIPT" start --local-bin-passthrough ro --local-bin-passthrough ro --dry-run
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}
