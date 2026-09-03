#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_fsck_parsing.bats -- Hanaden AI
# SPEC: CliContract.feat/FsckParsing -- fsck subcommand flag parsing
# REF:  SCOPE-very-narrow.md ### fsck
#
# Tests: positional ROOT_PATH, all short flags individually, mutual
#        exclusivity edge cases, missing values, help content, flag ordering.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    # Create a valid provisioned root for tests
    ROOT="${WORK}/root"
    bash "$SCRIPT" provision --host-real-root "$ROOT" 2>/dev/null
}
teardown() {
    rm -rf "$WORK"
}

# ---------------------------------------------------------------------------
# --help
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-001: --help exits 0" {
    run bash "$SCRIPT" fsck --help 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-002: -h exits 0" {
    run bash "$SCRIPT" fsck -h 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-003: --help mentions ROOT_PATH positional" {
    run bash "$SCRIPT" fsck --help 2>&1
    [[ "$output" == *"ROOT_PATH"* ]]
}

@test "FSCK-PARSE-004: --help mentions exit codes (bitmap)" {
    run bash "$SCRIPT" fsck --help 2>&1
    [[ "$output" == *"bitmap"* ]] || [[ "$output" == *"OR-able"* ]]
}

@test "FSCK-PARSE-005: --help mentions all short flags -n -a -r -f -v" {
    run bash "$SCRIPT" fsck --help 2>&1
    [[ "$output" == *"-n"* ]]
    [[ "$output" == *"-a"* ]]
    [[ "$output" == *"-r"* ]]
    [[ "$output" == *"-f"* ]]
    [[ "$output" == *"-v"* ]]
}

@test "FSCK-PARSE-006: --help mentions mutually exclusive -a/-r" {
    run bash "$SCRIPT" fsck --help 2>&1
    [[ "$output" == *"Mutex"* ]] || [[ "$output" == *"mutex"* ]] || [[ "$output" == *"mutually"* ]] || [[ "$output" == *"Mutex with"* ]]
}

# ---------------------------------------------------------------------------
# Positional ROOT_PATH
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-007: positional ROOT_PATH accepted (exits 0 on clean root)" {
    run bash "$SCRIPT" fsck "$ROOT" 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-008: positional ROOT_PATH overrides default" {
    run bash "$SCRIPT" fsck -v "$ROOT" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"$ROOT"* ]]
}

@test "FSCK-PARSE-009: --host-real-root and positional ROOT_PATH duplicate exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" "$ROOT" 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Individual short flags
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-010: -n alone on clean root exits 0" {
    run bash "$SCRIPT" fsck -n --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-011: -a alone on clean root exits 0" {
    run bash "$SCRIPT" fsck -a --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-012: -f alone on clean root exits 0" {
    run bash "$SCRIPT" fsck -f --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-013: -v alone on clean root exits 0 with [OK] lines" {
    run bash "$SCRIPT" fsck -v --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}

@test "FSCK-PARSE-014: -r alone on clean root exits 0" {
    run bash "$SCRIPT" fsck -r --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Mutual exclusivity edge cases
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-015: -a then -r exits 1 (mutually exclusive)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" -a -r 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "FSCK-PARSE-016: -r then -a exits 1 (mutually exclusive)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" -r -a 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"mutually exclusive"* ]]
}

@test "FSCK-PARSE-017: -n with -a accepted (check-only overrides repair)" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" -n -a 2>&1
    [ "$status" -eq 0 ]
}

@test "FSCK-PARSE-018: -n with -r accepted" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" -n -r 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Missing values for value-taking flags
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-019: --host-real-root with no value exits error" {
    run bash "$SCRIPT" fsck --host-real-root 2>&1
    [ "$status" -ne 0 ]
}

@test "FSCK-PARSE-020: --virtual-user-name with no value exits error" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --virtual-user-name 2>&1
    [ "$status" -ne 0 ]
}

@test "FSCK-PARSE-021: --log-level with no value exits error" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --log-level 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Flag ordering
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-022: flags BEFORE --host-real-root accepted" {
    run bash "$SCRIPT" fsck -v -f --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}

@test "FSCK-PARSE-023: flags AFTER --host-real-root accepted" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" -v -f 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK]"* ]]
}

@test "FSCK-PARSE-024: --log-level before short flags accepted" {
    run bash "$SCRIPT" fsck --log-level DEBUG --host-real-root "$ROOT" -v 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Unknown flags (dash-prefixed)
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-025: unknown long flag --badopt exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --badopt 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown option"* ]]
}

@test "FSCK-PARSE-026: unknown short flag -z exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" -z 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Duplicate value flags
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-027: duplicate --host-real-root exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" --host-real-root "$ROOT" 2>&1
    [ "$status" -eq 1 ]
}

@test "FSCK-PARSE-028: duplicate --virtual-user-name exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" \
        --virtual-user-name a --virtual-user-name b 2>&1
    [ "$status" -eq 1 ]
}

@test "FSCK-PARSE-029: duplicate --log-level exits 1" {
    run bash "$SCRIPT" fsck --host-real-root "$ROOT" \
        --log-level INFO --log-level DEBUG 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Custom --virtual-user-name in fsck
# ---------------------------------------------------------------------------

@test "FSCK-PARSE-030: --virtual-user-name custom checks that user home" {
    # Provision with custom user, then fsck with same user
    local r2="${WORK}/r2"
    bash "$SCRIPT" provision --host-real-root "$r2" --virtual-user-name alice 2>/dev/null
    run bash "$SCRIPT" fsck --host-real-root "$r2" --virtual-user-name alice -v 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"alice"* ]]
}
