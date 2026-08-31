#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_help_content.bats -- Hanaden AI
# SPEC: Provision.feat/HelpContent -- --help output content validation
# REF:  SCOPE-very-narrow.md ### provision
#
# Tests: all flags mentioned, defaults documented, FOUR-WAY GATE, NOT
#        idempotent, CREATES section, -h == --help, side-effect free.
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
# All flags mentioned in help
# ---------------------------------------------------------------------------

@test "PROV-HELP-001: --help mentions --host-real-root" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"--host-real-root"* ]]
}

@test "PROV-HELP-002: --help mentions --virtual-user-name" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"--virtual-user-name"* ]]
}

@test "PROV-HELP-003: --help mentions --host-real-home-parent" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"--host-real-home-parent"* ]]
}

@test "PROV-HELP-004: --help mentions --log-level" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"--log-level"* ]]
}

@test "PROV-HELP-005: --help mentions --dry-run" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"--dry-run"* ]]
}

@test "PROV-HELP-006: --help mentions -n (short dry-run)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"-n"* ]]
}

@test "PROV-HELP-007: --help mentions provision subcommand name" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"provision"* ]]
}

# ---------------------------------------------------------------------------
# Defaults documented
# ---------------------------------------------------------------------------

@test "PROV-HELP-008: --help mentions default root path (virtual-roots)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"virtual-roots"* ]]
}

@test "PROV-HELP-009: --help mentions default user (sandbox_user)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"sandbox_user"* ]]
}

@test "PROV-HELP-010: --help mentions default log level (INFO)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"INFO"* ]]
}

# ---------------------------------------------------------------------------
# Key contract elements
# ---------------------------------------------------------------------------

@test "PROV-HELP-011: --help mentions NOT idempotent" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"NOT idempotent"* ]]
}

@test "PROV-HELP-012: --help mentions FOUR-WAY GATE" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"FOUR-WAY GATE"* ]]
}

@test "PROV-HELP-013: --help mentions FATAL" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"FATAL"* ]]
}

# ---------------------------------------------------------------------------
# CREATES section
# ---------------------------------------------------------------------------

@test "PROV-HELP-014: --help mentions CREATES section" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"CREATES"* ]]
}

@test "PROV-HELP-015: --help mentions dirs it creates (usr)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"usr"* ]]
}

@test "PROV-HELP-016: --help mentions dirs it creates (etc)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"etc"* ]]
}

@test "PROV-HELP-017: --help mentions symlinks (bin->usr/bin)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"bin"* ]]
    [[ "$output" == *"usr/bin"* ]]
}

# ---------------------------------------------------------------------------
# Argument types documented
# ---------------------------------------------------------------------------

@test "PROV-HELP-018: --help mentions PATH as arg type for --host-real-root" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"PATH"* ]]
}

@test "PROV-HELP-019: --help mentions NAME as arg type for --virtual-user-name" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"NAME"* ]]
}

# ---------------------------------------------------------------------------
# -h and --help identity & side effects
# ---------------------------------------------------------------------------

@test "PROV-HELP-020: -h and --help produce identical output" {
    local h1 h2
    h1="$(bash "$SCRIPT" provision --help 2>&1)"
    h2="$(bash "$SCRIPT" provision -h 2>&1)"
    [ "$h1" = "$h2" ]
}

@test "PROV-HELP-021: --help does NOT create any files (side-effect free)" {
    local before after
    before="$(find "$WORK" -type f | wc -l)"
    bash "$SCRIPT" provision --help 2>/dev/null
    after="$(find "$WORK" -type f | wc -l)"
    [ "$before" -eq "$after" ]
}

@test "PROV-HELP-022: --help mentions -h (short help)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"-h"* ]]
}

@test "PROV-HELP-023: --help mentions MUST NOT already exist (for root)" {
    run bash "$SCRIPT" provision --help 2>&1
    [[ "$output" == *"MUST NOT already exist"* ]]
}
