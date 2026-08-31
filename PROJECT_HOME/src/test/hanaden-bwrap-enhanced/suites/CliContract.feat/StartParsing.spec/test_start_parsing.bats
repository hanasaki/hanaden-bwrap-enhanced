#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_start_parsing.bats -- Hanaden AI
# SPEC: CliContract.feat/StartParsing -- start subcommand flag parsing
# REF:  SCOPE-very-narrow.md ### start
#
# Tests: missing values, flag ordering, -- CMD placement, positional arg
#        before --, all value-taking flags, help content, all flags together.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    # Create a valid provisioned root for tests needing one
    ROOT="${WORK}/root"
    bash "$SCRIPT" provision --host-real-root "$ROOT" 2>/dev/null
}
teardown() {
    rm -rf "$WORK"
}

# ---------------------------------------------------------------------------
# --help
# ---------------------------------------------------------------------------

@test "START-PARSE-001: --help exits 0" {
    run bash "$SCRIPT" start --help 2>&1
    [ "$status" -eq 0 ]
}

@test "START-PARSE-002: -h exits 0" {
    run bash "$SCRIPT" start -h 2>&1
    [ "$status" -eq 0 ]
}

@test "START-PARSE-003: --help mentions -- CMD separator" {
    run bash "$SCRIPT" start --help 2>&1
    [[ "$output" == *"--"* ]]
    [[ "$output" == *"CMD"* ]]
}

@test "START-PARSE-004: --help mentions --validate" {
    run bash "$SCRIPT" start --help 2>&1
    [[ "$output" == *"--validate"* ]]
}

@test "START-PARSE-005: --help mentions --dry-run" {
    run bash "$SCRIPT" start --help 2>&1
    [[ "$output" == *"--dry-run"* ]]
}

@test "START-PARSE-006: --help mentions all passthrough flags" {
    run bash "$SCRIPT" start --help 2>&1
    [[ "$output" == *"--net-passthrough"* ]]
    [[ "$output" == *"--env-passthrough"* ]]
    [[ "$output" == *"--x11-passthrough"* ]]
    [[ "$output" == *"--wayland-passthrough"* ]]
    [[ "$output" == *"--gnome-passthrough"* ]]
    [[ "$output" == *"--kde-passthrough"* ]]
    [[ "$output" == *"--audio-passthrough"* ]]
    [[ "$output" == *"--a11y-passthrough"* ]]
    [[ "$output" == *"--dbus-passthrough"* ]]
    [[ "$output" == *"--mise-passthrough"* ]]
    [[ "$output" == *"--local-bin-passthrough"* ]]
}

@test "START-PARSE-007: --help mentions implication (wayland implies x11)" {
    run bash "$SCRIPT" start --help 2>&1
    [[ "$output" == *"implies"* ]] || [[ "$output" == *"implied"* ]]
}

# ---------------------------------------------------------------------------
# Missing values for value-taking flags
# ---------------------------------------------------------------------------

@test "START-PARSE-008: --host-real-root with no value exits error" {
    run bash "$SCRIPT" start --host-real-root 2>&1
    [ "$status" -ne 0 ]
}

@test "START-PARSE-009: --virtual-user-name with no value exits error" {
    run bash "$SCRIPT" start --virtual-user-name 2>&1
    [ "$status" -ne 0 ]
}

@test "START-PARSE-010: --host-real-home-parent with no value exits error" {
    run bash "$SCRIPT" start --host-real-home-parent 2>&1
    [ "$status" -ne 0 ]
}

@test "START-PARSE-011: --log-level with no value exits error" {
    run bash "$SCRIPT" start --log-level 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Flag ordering (dry-run to avoid exec)
# ---------------------------------------------------------------------------

@test "START-PARSE-012: --dry-run BEFORE passthrough flags exits 0" {
    run bash "$SCRIPT" start \
        --dry-run \
        --host-real-root "$ROOT" \
        --net-passthrough 2>&1
    [ "$status" -eq 0 ]
}

@test "START-PARSE-013: passthrough flags BEFORE --dry-run exits 0" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --net-passthrough \
        --dry-run 2>&1
    [ "$status" -eq 0 ]
}

@test "START-PARSE-014: --host-real-root LAST exits 0" {
    run bash "$SCRIPT" start \
        --dry-run \
        --net-passthrough \
        --log-level DEBUG \
        --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
}

@test "START-PARSE-015: --log-level FIRST exits 0" {
    run bash "$SCRIPT" start \
        --log-level DEBUG \
        --host-real-root "$ROOT" \
        --dry-run 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# -- CMD separator
# ---------------------------------------------------------------------------

@test "START-PARSE-016: -- followed by CMD accepted (dry-run)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --dry-run -- echo hello 2>&1
    [ "$status" -eq 0 ]
}

@test "START-PARSE-017: -- with no CMD afterwards exits error (needs CMD)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" -- 2>&1
    [ "$status" -ne 0 ]
}

@test "START-PARSE-018: positional arg before -- exits 1 (unknown option)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" badarg -- echo 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown option"* ]]
}

# ---------------------------------------------------------------------------
# Unknown flags
# ---------------------------------------------------------------------------

@test "START-PARSE-019: unknown long flag exits 1 with [ERROR]" {
    run bash "$SCRIPT" start --no-such-flag 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

@test "START-PARSE-020: unknown short flag -z exits 1" {
    run bash "$SCRIPT" start -z 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Duplicate value flags
# ---------------------------------------------------------------------------

@test "START-PARSE-021: duplicate --host-real-root exits 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --host-real-root "$ROOT" --dry-run 2>&1
    [ "$status" -eq 1 ]
}

@test "START-PARSE-022: duplicate --virtual-user-name exits 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name a --virtual-user-name b --dry-run 2>&1
    [ "$status" -eq 1 ]
}

@test "START-PARSE-023: duplicate --dry-run exits 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --dry-run --dry-run 2>&1
    [ "$status" -eq 1 ]
}

@test "START-PARSE-024: duplicate --validate exits 1" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --validate --validate 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# All flags together (dry-run, maximum coverage)
# ---------------------------------------------------------------------------

@test "START-PARSE-025: all value+boolean+graded flags together exits 0 (dry-run)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name sandbox_user \
        --host-real-home-parent "${ROOT}/home" \
        --log-level DEBUG \
        --dry-run \
        --net-passthrough \
        --env-passthrough \
        --wayland-passthrough \
        --audio-passthrough \
        --a11y-passthrough \
        --dbus-passthrough \
        --mise-passthrough ro \
        --local-bin-passthrough rw 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# -n alias for --dry-run in start
# ---------------------------------------------------------------------------

@test "START-PARSE-026: -n is alias for --dry-run in start" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" -n 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]] || [[ "$output" == *"DRY"* ]]
}

# ---------------------------------------------------------------------------
# Help short-circuits from any position
# ---------------------------------------------------------------------------

@test "START-PARSE-027: --help after flags exits 0 (short-circuits)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" --net-passthrough --help 2>&1
    [ "$status" -eq 0 ]
}
