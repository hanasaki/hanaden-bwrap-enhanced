#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_env_clearenv.bats -- Hanaden AI
# SPEC: EnvSanitization.feat/ClearEnv -- jail starts with ZERO inherited env
# REF:  Spec step 8: --clearenv wipes host env, then explicit --setenv only
#   "The jail environment must be constructed, not inherited."
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

# --- Host env must NOT leak ---

@test "CLEARENV-001: host USER variable is NOT visible inside sandbox" {
    # Set a canary so we can distinguish host vs sandbox
    export USER="hanasaki_host_canary"
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    # The host's USER value must NOT appear in sandbox env
    [[ "$output" != *"hanasaki_host_canary"* ]]
}

@test "CLEARENV-002: host HOME variable is NOT visible inside sandbox" {
    export HOME="/this/is/host/home"
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" != *"/this/is/host/home"* ]]
}

@test "CLEARENV-003: host SSH_AUTH_SOCK is NOT visible inside sandbox" {
    export SSH_AUTH_SOCK="/run/user/9999/agent.sock"
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" != *"SSH_AUTH_SOCK"* ]]
}

@test "CLEARENV-004: host WAYLAND_DISPLAY is NOT visible inside sandbox" {
    export WAYLAND_DISPLAY="wayland-0"
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" != *"WAYLAND_DISPLAY"* ]]
}

@test "CLEARENV-005: host XDG_RUNTIME_DIR is NOT visible inside sandbox" {
    export XDG_RUNTIME_DIR="/run/user/9999"
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" != *"XDG_RUNTIME_DIR"* ]]
}

@test "CLEARENV-006: sandbox env has fewer than 10 variables (constructed, not inherited)" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    # A clean constructed env should have very few vars (HOME, USER, PATH, maybe TERM)
    # A leaked host env typically has 40-80+
    local count
    count="$(printf '%s\n' "$output" | grep -c '=')"
    [ "$count" -lt 10 ]
}

@test "CLEARENV-007: --dry-run output includes --clearenv" {
    run bash "$SCRIPT" start --dry-run \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- /bin/true
    [[ "$output" == *"--clearenv"* ]]
}

# --- Minimum constructed env vars ---

@test "CLEARENV-008: sandbox has HOME set to /home/<virtual-user>" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" == *"HOME=/home/testuser"* ]]
}

@test "CLEARENV-009: sandbox has USER set to virtual-user-name" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" == *"USER=testuser"* ]]
}

@test "CLEARENV-010: sandbox has PATH=/usr/bin:/bin" {
    run bash "$SCRIPT" start \
        --host-real-root "$ROOT" \
        --virtual-user-name testuser \
        -- env
    [[ "$output" == *"PATH=/usr/bin:/bin"* ]]
}
