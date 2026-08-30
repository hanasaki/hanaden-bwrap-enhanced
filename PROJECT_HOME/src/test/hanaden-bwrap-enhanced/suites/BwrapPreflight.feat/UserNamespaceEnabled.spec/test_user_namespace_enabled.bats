#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_user_namespace_enabled.bats -- Hanaden AI
# SPEC: UserNamespaceEnabled.spec -- kernel user namespace support
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"

    # Create shadow dir with all needed binaries including bwrap+newuidmap+newgidmap stubs
    SHADOW_DIR="$(mktemp -d)"
    local cmds=(bash printf id awk cat realpath mktemp head cut tr sed grep
                mkdir ln rm chmod date env command)
    for cmd in "${cmds[@]}"; do
        local src
        src="$(command -v "$cmd" 2>/dev/null || true)"
        [ -n "$src" ] && ln -sf "$src" "${SHADOW_DIR}/${cmd}" 2>/dev/null || true
    done

    # Stub all earlier preflight binaries
    for bin in bwrap newuidmap newgidmap; do
        local real_bin
        real_bin="$(command -v "$bin" 2>/dev/null || true)"
        if [ -n "$real_bin" ]; then
            ln -sf "$real_bin" "${SHADOW_DIR}/${bin}"
        else
            printf '#!/bin/sh\nexit 0\n' > "${SHADOW_DIR}/${bin}"
            chmod +x "${SHADOW_DIR}/${bin}"
        fi
    done

    # Create mock /proc/sys directory for testing
    MOCK_PROC="$(mktemp -d)"
}

teardown() {
    [ -d "${SHADOW_DIR:-}" ] && rm -rf "$SHADOW_DIR"
    [ -d "${MOCK_PROC:-}" ] && rm -rf "$MOCK_PROC"
}

_run_with_mock_proc() {
    # Set BWRAP_PREFLIGHT_PROC_BASE to override where preflight reads sysctl
    PATH="${SHADOW_DIR}" BWRAP_PREFLIGHT_PROC_BASE="${MOCK_PROC}" \
        bash "$SCRIPT" "$@" 2>&1
}

# ---------------------------------------------------------------------------
@test "PF-NS-001: user-ns enabled (value=1) -- preflight passes" {
    # Create mock sysctl file with enabled value
    mkdir -p "${MOCK_PROC}/kernel"
    echo "1" > "${MOCK_PROC}/kernel/unprivileged_userns_clone"

    run _run_with_mock_proc -- /bin/true
    [ "$status" -ne 2 ] || {
        echo "output: $output"
        return 1
    }
}

@test "PF-NS-002: user-ns disabled (value=0) -- FATAL exit 2" {
    mkdir -p "${MOCK_PROC}/kernel"
    echo "0" > "${MOCK_PROC}/kernel/unprivileged_userns_clone"

    run _run_with_mock_proc -- /bin/true
    [ "$status" -eq 2 ]
}

@test "PF-NS-003: user-ns disabled -- stderr contains [FATAL]" {
    mkdir -p "${MOCK_PROC}/kernel"
    echo "0" > "${MOCK_PROC}/kernel/unprivileged_userns_clone"

    run _run_with_mock_proc -- /bin/true
    [[ "$output" == *"[FATAL]"* ]]
    [[ "$output" == *"namespace"* ]]
}

@test "PF-NS-004: proc file absent -- no FATAL (skip check)" {
    # MOCK_PROC exists but has no sysctl files -- check should be skipped
    run _run_with_mock_proc -- /bin/true
    [ "$status" -ne 2 ] || {
        echo "output: $output"
        return 1
    }
}
