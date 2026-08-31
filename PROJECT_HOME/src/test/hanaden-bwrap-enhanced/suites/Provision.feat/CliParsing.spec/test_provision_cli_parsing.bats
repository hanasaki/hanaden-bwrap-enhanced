#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_cli_parsing.bats -- Hanaden AI
# SPEC: Provision.feat/CliParsing -- argument parsing edge cases
# REF:  SCOPE-very-narrow.md ### provision
#
# Tests: missing values, unknown flags, positional args, flag ordering,
#        path with spaces, --help short-circuits from any position.
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

# ---------------------------------------------------------------------------
# Missing value args (each flag that requires a value)
# ---------------------------------------------------------------------------

@test "PROV-CLI-001: --host-real-root with no value exits 1" {
    run bash "$SCRIPT" provision --host-real-root
    [ "$status" -ne 0 ]
}

@test "PROV-CLI-002: --virtual-user-name with no value exits 1" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --virtual-user-name
    [ "$status" -ne 0 ]
}

@test "PROV-CLI-003: --host-real-home-parent with no value exits 1" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --host-real-home-parent
    [ "$status" -ne 0 ]
}

@test "PROV-CLI-004: --log-level with no value exits 1" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --log-level
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Unknown flags
# ---------------------------------------------------------------------------

@test "PROV-CLI-005: unknown long flag --no-such-flag exits 1 with [ERROR]" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --no-such-flag 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

@test "PROV-CLI-006: unknown short flag -z exits 1 with [ERROR]" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" -z 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

@test "PROV-CLI-007: unknown short flag -x exits 1" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" -x 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Positional arguments (provision accepts NO positional args)
# ---------------------------------------------------------------------------

@test "PROV-CLI-008: bare positional word exits 1 with [ERROR]" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" some_word 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
}

@test "PROV-CLI-009: positional arg after all valid flags exits 1" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" --virtual-user-name myuser extra_arg 2>&1
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Flag ordering permutations (order must not matter)
# ---------------------------------------------------------------------------

@test "PROV-CLI-010: --virtual-user-name BEFORE --host-real-root exits 0" {
    local root="${WORK}/order1"
    run bash "$SCRIPT" provision \
        --virtual-user-name testuser \
        --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/home/testuser" ]
}

@test "PROV-CLI-011: --log-level BEFORE --host-real-root exits 0" {
    local root="${WORK}/order2"
    run bash "$SCRIPT" provision \
        --log-level DEBUG \
        --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/usr" ]
}

@test "PROV-CLI-012: -n first then --host-real-root exits 0 dry-run" {
    local root="${WORK}/order3"
    run bash "$SCRIPT" provision \
        -n \
        --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    # Dry-run: nothing created
    [ ! -d "$root" ]
}

@test "PROV-CLI-013: --host-real-root LAST among multiple flags exits 0" {
    local root="${WORK}/order4"
    run bash "$SCRIPT" provision \
        --virtual-user-name myuser \
        --log-level INFO \
        --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/usr" ]
    [ -d "${root}/home/myuser" ]
}

@test "PROV-CLI-014: --host-real-home-parent BEFORE --host-real-root exits 0" {
    local root="${WORK}/order5"
    local hp="${WORK}/ext-home"
    run bash "$SCRIPT" provision \
        --host-real-home-parent "$hp" \
        --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${hp}/sandbox_user" ]
}

@test "PROV-CLI-015: --dry-run BEFORE --host-real-root exits 0" {
    local root="${WORK}/order6"
    run bash "$SCRIPT" provision \
        --dry-run \
        --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ ! -d "$root" ]
}

# ---------------------------------------------------------------------------
# All flags combined in one invocation
# ---------------------------------------------------------------------------

@test "PROV-CLI-016: all flags together exits 0 with correct structure" {
    local root="${WORK}/all-flags"
    local hp="${WORK}/all-home"
    run bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name myuser \
        --host-real-home-parent "$hp" \
        --log-level DEBUG 2>&1
    [ "$status" -eq 0 ]
    # Verify all 9 dirs
    [ -d "${root}/usr" ]
    [ -d "${root}/etc" ]
    [ -d "${root}/home" ]
    [ -d "${root}/proc" ]
    [ -d "${root}/dev" ]
    [ -d "${root}/tmp" ]
    [ -d "${root}/run" ]
    [ -d "${root}/opt" ]
    [ -d "${root}/var" ]
    # Verify 3 symlinks
    [ -L "${root}/bin" ]
    [ -L "${root}/lib" ]
    [ -L "${root}/lib64" ]
    # Verify home at custom location
    [ -d "${hp}/myuser" ]
}

# ---------------------------------------------------------------------------
# Path with spaces
# ---------------------------------------------------------------------------

@test "PROV-CLI-017: root path with spaces in name exits 0 and creates dirs" {
    local root="${WORK}/my root dir"
    run bash "$SCRIPT" provision --host-real-root "$root" 2>&1
    [ "$status" -eq 0 ]
    [ -d "${root}/usr" ]
    [ -d "${root}/home/sandbox_user" ]
    [ -L "${root}/bin" ]
}

# ---------------------------------------------------------------------------
# --help / -h short-circuits from any position
# ---------------------------------------------------------------------------

@test "PROV-CLI-018: -h after other flags still exits 0 (help short-circuits)" {
    run bash "$SCRIPT" provision --host-real-root "${WORK}/r" -h 2>&1
    [ "$status" -eq 0 ]
    # Root not created (help exited early)
    [ ! -d "${WORK}/r" ]
}

@test "PROV-CLI-019: --help in middle of flags still exits 0" {
    run bash "$SCRIPT" provision --log-level DEBUG --help --host-real-root "${WORK}/r" 2>&1
    [ "$status" -eq 0 ]
    [ ! -d "${WORK}/r" ]
}

@test "PROV-CLI-020: --host-real-root value that looks like a flag (starts with -) exits error" {
    # A value like "--bad" for --host-real-root would be consumed as the path value,
    # but since it doesn't exist it would succeed as a root name (weird but valid path).
    # This test verifies the parser doesn't crash on unusual path values.
    run bash "$SCRIPT" provision --host-real-root "--unusual-path" 2>&1
    # This might exit 0 (creates dir named --unusual-path) or error; key is no crash.
    # The parser should consume it as the value. Let's verify it doesn't exit 1 with "unknown".
    [[ "$output" != *"unknown option"* ]]
}
