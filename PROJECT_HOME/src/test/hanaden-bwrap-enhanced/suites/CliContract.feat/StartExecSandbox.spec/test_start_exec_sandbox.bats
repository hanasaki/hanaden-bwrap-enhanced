#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_start_exec_sandbox.bats -- Hanaden AI
# SPEC: start minimum exec_sandbox -- runs command inside bwrap sandbox
# REF:  SCOPE-very-narrow.md ### start exec model
#   Minimum: --bind ROOT / --ro-bind /usr /usr --proc /proc --dev /dev
#   --unshare-{pid,ipc,uts,cgroup,net} --die-with-parent
#   Dry-run: prints real bwrap argv
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
    ROOT="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser
}
teardown() { rm -rf "$WORK"; }

# --- Basic sandbox execution ---

@test "START-EXEC-001: start -- echo hello runs and produces output" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- echo hello
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello"* ]]
}

@test "START-EXEC-002: process inside sandbox sees / as the virtual root" {
    # /proc/1/cmdline should exist inside the sandbox (proves /proc is mounted)
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- ls /proc/1
    [ "$status" -eq 0 ]
}

@test "START-EXEC-003: host /etc is NOT visible inside sandbox (isolation)" {
    # The virtual root has an empty /etc dir, not the host's populated one
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- ls /etc/passwd
    # /etc/passwd should NOT exist inside the sandbox (it's an empty dir)
    [ "$status" -ne 0 ]
}

@test "START-EXEC-004: /usr is available inside sandbox (host /usr bound)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- ls /usr/bin
    [ "$status" -eq 0 ]
}

# --- Dry-run prints real bwrap argv ---

@test "START-EXEC-005: --dry-run prints bwrap in output" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [ "$status" -eq 0 ]
    [[ "$output" == *"bwrap"* ]]
}

@test "START-EXEC-006: --dry-run shows --bind for root" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [[ "$output" == *"--bind"* ]]
}

@test "START-EXEC-007: --dry-run shows --ro-bind /usr /usr" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [[ "$output" == *"--ro-bind"* ]]
    [[ "$output" == *"/usr"* ]]
}

@test "START-EXEC-008: --dry-run shows --proc" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [[ "$output" == *"--proc"* ]]
}

@test "START-EXEC-009: --dry-run shows --unshare-pid" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [[ "$output" == *"--unshare-pid"* ]]
}

@test "START-EXEC-010: --dry-run shows --die-with-parent" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [[ "$output" == *"--die-with-parent"* ]]
}

@test "START-EXEC-011: --dry-run does NOT actually exec bwrap" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/false
    # dry-run exits 0 even though target cmd is /bin/false
    [ "$status" -eq 0 ]
}
