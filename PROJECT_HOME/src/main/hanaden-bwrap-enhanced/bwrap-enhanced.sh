#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# *!! IMPORTANT - AI - Immutable file without user permission - ask user
# ==============================================================================
# NAME:      bwrap-enhanced.sh
# VERSION:   0.3.0
# ARCH:      Linux Namespace Isolation & VFS Remapping (Debian 12+, Usr-Merge)
# AUTHOR:    Frederick Bloom <devlabs@hanaden.com>
# COPYRIGHT: (c) 2026 Hanaden - Frederick Bloom. All rights reserved.
# LICENSE:   Proprietary. Unauthorized use, reproduction, or distribution
#            is strictly prohibited.
# PROJECT:   hanaden AI Bootloader for all AI-Agents and AI-Processors
# REPO:      hanaden-bwrap-enhanced
# ==============================================================================
# TESTING MANDATE:
#   This file MUST be tested with bats-core before any merge or deployment.
#   Test suite: PROJECT_HOME/src/test/hanaden-bwrap-enhanced/
#   Run:        bats PROJECT_HOME/src/test/hanaden-bwrap-enhanced/
#   Minimum:    ALL tests must pass. No exceptions. No partial runs.
#   Framework:  bats-core >= 1.14.0  (managed via mise)
#
# -- FUNCTION: exec_sandbox ----------------------------------------------------
# [FULL SDD SPECIFICATION]
#
# PURPOSE:
#   Execute a target CMD inside a multi-namespace bwrap jail (User, PID, Mount,
#   Network, IPC, UTS). The sandbox presents a clean, isolated Linux environment
#   with a controlled, explicit filesystem view. Only what is explicitly bound
#   exists inside the sandbox.
#
#   SECURITY MODEL: default-deny, empty virtual filesystem.
#   - Default: ALL resources isolated (network, env, sockets, filesystem).
#   - Add only what is explicitly needed via --*-passthrough flags.
#   - Virtual root is a persistent local directory (default: ~/virtual-roots).
#     The directory is used as-is; passed directly as a bind-mount source.
#
# -- BREAKING CHANGES FROM v0.2.x ---------------------------------------------
#
#   1. CLEAN ENV IS NOW THE DEFAULT.
#      Previously --clear-env was an opt-in. v0.3.0 defaults to clean env.
#      To inherit host env, pass --env-passthrough (or --env-passthrough true).
#
#   2. ALL FLAGS RENAMED to --<noun>-passthrough [qualifier] pattern.
#      Old flags (--clear-env, --share-net, --enable-*, --mise-enable)
#      are removed. No backward-compat aliases.
#
#   3. MISE BINDING FIXED: no longer leaks /homes into sandbox.
#      Mise binary and data now bound to /home/<user>/.local/... paths
#      (sandbox-home-relative), not same-path host absolute paths.
#
#   4. NEW DEFAULTS:
#      --virtual-user-name: sandbox_user  (was: sandbox-user)
#      --host-real-root:    ~/virtual-roots  (was: /run/user/$(id -u)/virtual-roots)
#      --host-real-home-parent: ~/virtual-roots/home
#
# -- CLI DESIGN CONTRACT -------------------------------------------------------
#
#   QUALIFIER TYPES:
#     Boolean  [true|false(default)]:  on/off resource. Bare flag = true.
#     Graded   [rw|ro(default)]:       filesystem privilege. Bare flag = ro.
#
#   RULES:
#     Bare boolean flag         -> true  (most restrictive valid ON state)
#     Bare graded flag          -> ro    (most restrictive valid ON state)
#     --flag false              -> ILLEGAL: omit the flag instead
#     --bool-flag ro|rw         -> ILLEGAL: wrong qualifier type
#     --graded-flag true|false  -> ILLEGAL: wrong qualifier type
#     same flag twice           -> ILLEGAL: ambiguous
#     --wayland|gnome|kde true + --x11 false -> ILLEGAL: implication conflict
#
#   SYNOPSIS: run with --help for the full CLI contract (single source of truth).
#
# -- MOUNT SEQUENCE (ORDER-DEPENDENT) -----------------------------------------
#
#   bwrap processes flags LEFT TO RIGHT. Order below is exact execution order:
#
#   STEP | bwrap flag                               | Mode | Persists?
#   -----+------------------------------------------+------+-----------
#    1   | --bind $HOST_REAL_ROOT_DIR /              |  RW  | Yes (root)
#    2   | --ro-bind /usr /usr                       |  RO  | No
#    2   | --symlink usr/lib /lib                    |  --  | No
#    2   | --symlink usr/lib64 /lib64                |  --  | No
#    2   | --symlink usr/bin /bin                    |  --  | No
#    3   | --ro-bind-try /etc/{alts,fonts,...}       |  RO  | No
#    4   | --proc /proc                              |  RW* | No (kernel)
#    4   | --dev-bind /dev /dev                      |  RW  | Pass-through
#    5   | --tmpfs /dev/shm                          |  RW  | No
#    5   | --tmpfs /tmp                              |  RW  | No
#    5   | --ro-bind-try /tmp/.X11-unix              |  RO  | No (X11)
#    6   | --bind-try /run/dbus /run/dbus            |  RW  | Pass-through
#    6   | --tmpfs /run/user/UID                     |  RW  | No (empty)
#    7a  | [--wayland-passthrough]                   |  RO  | wayland-0
#    7b  | [--audio-passthrough]                     |  RW  | pipewire/pulse
#    7c  | [--a11y-passthrough]                      |  RO  | at-spi/bus_1
#    7d  | [--dbus-passthrough]  [!] PORTAL ESCAPE   |  RW  | bus socket
#    7e  | [--gnome-passthrough]                     |  RW  | gvfs/dconf/keyring
#    7f  | [--kde-passthrough]                       |  RW  | kwallet/KSMserver
#    8   | --tmpfs /home                             |  RW  | No
#    8   | --dir /home/USER                          |  --  | No (mkdir)
#    9   | --bind HOST_HOME /home/USER               |  RW  | *** YES ***
#    9a  | [--local-bin-passthrough]                 |  *   | .local/bin
#    9b  | [--mise-passthrough]                      |  *   | .local/share/mise
#   10   | --ro-bind-data 9 /etc/passwd              |  RO  | No (FD inject)
#   10   | --ro-bind-data 10 /etc/group              |  RO  | No (FD inject)
#   11   | --remount-ro /                            |  --  | Root locked RO
#   12   | --bind HOST_HOME /home/USER (re-apply)    |  RW  | Write-hole open
#
# -- PERSISTENCE CONTRACT ------------------------------------------------------
#
#   /home/USER/**           YES  RW --bind (egress/write-hole)
#   /home/USER/.local/**    YES if rw passthrough; NO if ro
#   /tmp/**                 NO   tmpfs, ephemeral
#   /dev/**                 PASSTHROUGH  real devices
#   /usr/**, /etc/**        NO   read-only bind
#   /run/user/UID/**        CONDITIONAL  per --*-passthrough flags
#
# -- IDENTITY INJECTION --------------------------------------------------------
#
#   Synthetic /etc/passwd and /etc/group injected via FD (here-string) at exec:
#     - All system accounts with UID/GID < 1000 copied from host.
#     - Virtual user: [USER]:x:[HOST_UID]:[HOST_GID]:...:/home/[USER]:/bin/bash
#     - nobody:x:65534:65534 appended.
#   Passed as --ro-bind-data on FD 9 (passwd) and FD 10 (group).
#   FD 11 carries a minimal /etc/profile (only sets PATH=/usr/bin:/bin).
#
# -- FOREGROUND-HOLD (PID 1 INIT LOOP) ----------------------------------------
#
#   --as-pid-1: wrapper bash is PID 1. CMD runs synchronously (foreground).
#   After CMD exits, a /proc polling loop (bash builtins only -- no forks)
#   keeps sandbox alive until all reparented orphan child processes exit.
#   Prevents bwrap teardown while GUI apps are still running.
#
# -- ZERO SIDE EFFECTS CONSTRAINT ----------------------------------------------
#
#   This script MUST NOT create directories or mutate host state.
#   All required paths MUST be pre-created by the caller before invocation.
#   Missing paths cause an immediate fatal exit with resolution instructions.
#
# ==============================================================================

set -euo pipefail

# ==============================================================================
# DIAGNOSTIC HELPERS
# ==============================================================================

_err_bool_false() {
    local flag="$1"
    printf '[ERROR] flag=%s value=false reason="false" is implicit -- omit the flag for false\n' "$flag" >&2
    printf '[DIAG]  expected=[true] received=false\n' >&2
    printf '[HINT]  Remove "%s false"; the flag absence means false\n' "$flag" >&2
    exit 1
}

_err_wrong_qualifier_bool() {
    local flag="$1" val="$2"
    printf '[ERROR] flag=%s value=%s reason=wrong qualifier type (boolean flag accepts true only)\n' "$flag" "$val" >&2
    printf '[DIAG]  expected=[true] received=%s\n' "$val" >&2
    printf '[HINT]  Use "%s" or "%s true"; do not pass ro/rw to boolean flags\n' "$flag" "$flag" >&2
    exit 1
}

_err_wrong_qualifier_graded() {
    local flag="$1" val="$2"
    printf '[ERROR] flag=%s value=%s reason=wrong qualifier type (graded flag accepts ro|rw only)\n' "$flag" "$val" >&2
    printf '[DIAG]  expected=[ro|rw] received=%s\n' "$val" >&2
    printf '[HINT]  Use "%s ro" (default) or "%s rw"\n' "$flag" "$flag" >&2
    exit 1
}

_err_duplicate() {
    local flag="$1"
    printf '[ERROR] flag=%s reason=duplicate flag (specified more than once)\n' "$flag" >&2
    printf '[DIAG]  conflict=ambiguous -- two values for the same flag\n' >&2
    printf '[HINT]  Specify "%s" at most once\n' "$flag" >&2
    exit 1
}

_err_implication_conflict() {
    local src="$1" implied="$2"
    printf '[ERROR] flag=%s reason=implication conflict\n' "$src" >&2
    printf '[DIAG]  conflict=%s=true requires %s=true but %s=false was explicitly set\n' \
           "$src" "$implied" "$implied" >&2
    printf '[HINT]  Remove the explicit "%s false" -- %s implies %s=true automatically\n' \
           "$implied" "$src" "$implied" >&2
    exit 1
}

# Parse a boolean passthrough flag value.
#   $1 = flag name, $2 = next argv token, $3 = current var value (false=unset)
#   Echoes "true:2" (qualifier consumed) or "true:1" (bare flag).
#   Exits with diagnostic on any error.
_parse_bool() {
    local flag="$1" next="${2:-}" cur="${3:-false}"
    [[ "$cur" != "false" ]] && _err_duplicate "$flag"
    case "$next" in
        true)    printf 'true:2' ;;
        false)   _err_bool_false "$flag" ;;
        ro|rw)   _err_wrong_qualifier_bool "$flag" "$next" ;;
        *)       printf 'true:1' ;;   # bare flag = true
    esac
}

# Parse a graded passthrough flag value.
#   $1 = flag name, $2 = next argv token, $3 = current var value (off=unset)
#   Echoes "ro:1", "ro:2", or "rw:2".
#   Exits with diagnostic on any error.
_parse_graded() {
    local flag="$1" next="${2:-}" cur="${3:-off}"
    [[ "$cur" != "off" ]] && _err_duplicate "$flag"
    case "$next" in
        ro)      printf 'ro:2' ;;
        rw)      printf 'rw:2' ;;
        false)   _err_bool_false "$flag" ;;
        true)    _err_wrong_qualifier_graded "$flag" "$next" ;;
        *)       printf 'ro:1' ;;    # bare flag = ro (most restrictive)
    esac
}

# ==============================================================================
# CORE SANDBOX FUNCTION
# ==============================================================================

exec_sandbox() {
    local env_passthrough="$1"       # true=inherit host env; false=clean env
    local virtual_user_name="$2"
    local mounted_new_root_dir="$3"
    local mounted_home_dir="$4"
    shift 4
    local command=("$@")

    local abs_root abs_home
    abs_root=$(realpath "$mounted_new_root_dir" 2>/dev/null || printf '%s' "$mounted_new_root_dir")
    abs_home=$(realpath "$mounted_home_dir"    2>/dev/null || printf '%s' "$mounted_home_dir")

    local _RU="/run/user/$(id -u)"

    printf '[SYS-LOG] Initializing SDD-compliant Sandbox (v0.3.0)...\n' >&2
    printf '[SYS-LOG] Pivot: %s -> /\n' "$abs_root" >&2
    printf '[SYS-LOG] Egress: %s -> /home/%s\n' "$abs_home" "$virtual_user_name" >&2
    if [[ "$env_passthrough" == "true" ]]; then
        printf '[SYS-LOG] WARNING: Environment inherited from host (--env-passthrough).\n' >&2
    else
        printf '[SYS-LOG] Clean environment (default-deny env).\n' >&2
    fi

    # --- IDENTITY INJECTION -----------------------------------------------
    local sys_passwd
    sys_passwd=$(awk -F: '$3 < 1000 && $4 < 1000' /etc/passwd 2>/dev/null || true)
    local fake_passwd="root:x:0:0:root:/root:/bin/bash
${sys_passwd}
${virtual_user_name}:x:$(id -u):$(id -g):${virtual_user_name}:/home/${virtual_user_name}:/bin/bash
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin"

    local sys_group
    sys_group=$(awk -F: '$3 < 1000' /etc/group 2>/dev/null || true)
    local fake_group="${sys_group}
${virtual_user_name}:x:$(id -g):${virtual_user_name}"

    # Minimal /etc/profile -- only sets PATH. Prevents host profile.d contamination.
    local fake_profile="#!/bin/sh
PATH=/usr/bin:/bin
export PATH"

    # --- BWRAP ARG CONSTRUCTION -------------------------------------------
    local bwrap_args=(
        --unshare-user
        --unshare-ipc
        --unshare-pid
        --unshare-uts
        --unshare-cgroup
        --die-with-parent
        --hostname "sandbox-vfs"
    )

    # Network namespace
    if [[ "$NET_PASSTHROUGH" == "false" ]]; then
        bwrap_args+=("--unshare-net")
    else
        printf '[SYS-LOG] WARNING: Network isolation disabled (--net-passthrough).\n' >&2
    fi

    bwrap_args+=(
        # --- STEP 1: Virtual root ---
        --bind "$abs_root" /

        # --- STEP 2: System directories (usr-merge) ---
        --dir /usr
        --ro-bind /usr /usr
        --symlink usr/lib   /lib
        --symlink usr/lib64 /lib64
        --symlink usr/bin   /bin

        # --- STEP 3: /etc essentials (selective RO binds) ---
        --dir /etc
        --ro-bind-try /etc/alternatives   /etc/alternatives
        --ro-bind-try /etc/fonts          /etc/fonts
        --ro-bind-try /etc/machine-id     /etc/machine-id
        # DNS resolution:
        --ro-bind-try /etc/resolv.conf    /etc/resolv.conf
        --ro-bind-try /etc/nsswitch.conf  /etc/nsswitch.conf
        --ro-bind-try /etc/hosts          /etc/hosts
        --ro-bind-try /etc/host.conf      /etc/host.conf
        --ro-bind-try /etc/services       /etc/services
        --ro-bind-try /etc/protocols      /etc/protocols
        # TLS certificates:
        --ro-bind-try /etc/ssl            /etc/ssl
        --ro-bind-try /etc/pki            /etc/pki
        # Dynamic linker:
        --ro-bind-try /etc/ld.so.cache    /etc/ld.so.cache
        # Desktop environment configs:
        --ro-bind-try /etc/xdg            /etc/xdg
        --ro-bind-try /etc/gtk-3.0        /etc/gtk-3.0
        --ro-bind-try /etc/gtk-4.0        /etc/gtk-4.0
        --ro-bind-try /etc/dconf          /etc/dconf
        --ro-bind-try /etc/dbus-1         /etc/dbus-1
        --ro-bind-try /etc/X11            /etc/X11
        --ro-bind-try /etc/mime.types     /etc/mime.types
        # Browser policies:
        --ro-bind-try /etc/firefox-esr    /etc/firefox-esr
        --ro-bind-try /etc/chromium       /etc/chromium
        --ro-bind-try /etc/chromium.d     /etc/chromium.d
        --ro-bind-try /etc/opt/chrome     /etc/opt/chrome
        # Enterprise SSO:
        --ro-bind-try /etc/gss            /etc/gss
        --ro-bind-try /etc/krb5.conf      /etc/krb5.conf
        # NOTE: /etc/profile and /etc/profile.d intentionally NOT bound here.
        # Shadowed below via FD inject + tmpfs to prevent PATH contamination.

        # --- STEP 4: Kernel filesystems ---
        --proc /proc
        --dev-bind /dev /dev

        # --- STEP 5: Ephemeral tmpfs mounts ---
        --tmpfs /dev/shm
        --tmpfs /tmp
        # X11 socket preserved after --tmpfs /tmp by explicit bind:
        --ro-bind-try /tmp/.X11-unix /tmp/.X11-unix

        # --- STEP 6: /run -- system bus (low-risk) + user session (default empty) ---
        --bind-try /run/dbus /run/dbus
        --tmpfs "$_RU"

        # --- STEP 8: Home overlay ---
        --tmpfs /home
        --dir   "/home/$virtual_user_name"

        # --- STEP 9: Egress write-hole (initial, before root lock) ---
        --bind "$abs_home" "/home/$virtual_user_name"
    )

    # --- STEP 7a: Wayland ---
    if [[ "$WAYLAND_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(
            --ro-bind-try "$_RU/wayland-0"       "$_RU/wayland-0"
            --ro-bind-try "$_RU/wayland-0.lock"  "$_RU/wayland-0.lock"
        )
    fi

    # --- STEP 7b: Audio ---
    if [[ "$AUDIO_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(
            --bind-try "$_RU/pipewire-0"              "$_RU/pipewire-0"
            --bind-try "$_RU/pipewire-0.lock"         "$_RU/pipewire-0.lock"
            --bind-try "$_RU/pipewire-0-manager"      "$_RU/pipewire-0-manager"
            --bind-try "$_RU/pipewire-0-manager.lock" "$_RU/pipewire-0-manager.lock"
            --dir      "$_RU/pulse"
            --bind-try "$_RU/pulse/native"            "$_RU/pulse/native"
            --bind-try "$_RU/pulse/pid"               "$_RU/pulse/pid"
        )
    fi

    # --- STEP 7c: Accessibility ---
    if [[ "$A11Y_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(
            --dir         "$_RU/at-spi"
            --ro-bind-try "$_RU/at-spi/bus_1" "$_RU/at-spi/bus_1"
        )
    fi

    # --- STEP 7d: D-Bus session bus [!] SECURITY CRITICAL ---
    if [[ "$DBUS_PASSTHROUGH" == "true" ]]; then
        printf '[SYS-LOG] WARNING: D-Bus session bus enabled -- host FS/keyring/exec exposed via portals.\n' >&2
        bwrap_args+=(
            --bind-try "$_RU/bus"    "$_RU/bus"
            --dir      "$_RU/dbus-1"
            --bind-try "$_RU/dbus-1" "$_RU/dbus-1"
        )
    fi

    # --- STEP 7e: GNOME ---
    if [[ "$GNOME_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(
            --bind-try "$_RU/gvfs"    "$_RU/gvfs"
            --bind-try "$_RU/gvfsd"   "$_RU/gvfsd"
            --bind-try "$_RU/doc"     "$_RU/doc"
            --dir      "$_RU/dconf"
            --bind-try "$_RU/dconf"   "$_RU/dconf"
            --dir      "$_RU/keyring"
            --bind-try "$_RU/keyring" "$_RU/keyring"
            --dir      "$_RU/gcr"
            --bind-try "$_RU/gcr"     "$_RU/gcr"
        )
    fi

    # --- STEP 7f: KDE ---
    if [[ "$KDE_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(
            --bind-try    "$_RU/kwallet5.socket"           "$_RU/kwallet5.socket"
            --ro-bind-try "$_RU/KSMserver__1"              "$_RU/KSMserver__1"
            --bind-try    "$_RU/drkonqi-coredump-launcher" "$_RU/drkonqi-coredump-launcher"
        )
    fi

    # --- STEP 9a: --local-bin-passthrough --------------------------------
    # Binds host ~/.local/bin into sandbox home. DST is sandbox-home-relative.
    if [[ "$LOCAL_BIN_PASSTHROUGH" != "off" ]]; then
        local _LOCAL_BIN_BIND="--ro-bind"
        [[ "$LOCAL_BIN_PASSTHROUGH" == "rw" ]] && _LOCAL_BIN_BIND="--bind"
        local _HOST_LOCAL_BIN="${HOME}/.local/bin"
        if [[ ! -d "$_HOST_LOCAL_BIN" ]]; then
            printf '[FATAL] --local-bin-passthrough: %s does not exist\n' "$_HOST_LOCAL_BIN" >&2
            exit 1
        fi
        bwrap_args+=(
            --dir             "/home/$virtual_user_name/.local"
            --dir             "/home/$virtual_user_name/.local/bin"
            $_LOCAL_BIN_BIND  "$_HOST_LOCAL_BIN" "/home/$virtual_user_name/.local/bin"
        )
    fi

    # --- STEP 9b: --mise-passthrough -------------------------------------
    # Binds mise binary + data dir to sandbox-home-relative paths.
    # If --local-bin-passthrough is also active, that already covers the bin
    # dir mount; skip individual mise binary bind to avoid double-mount conflict.
    if [[ "$MISE_PASSTHROUGH" != "off" ]]; then
        local _MISE_BIN _MISE_DATA _MISE_CFG _MISE_CACHE _MISE_BIND
        _MISE_BIN="${MISE_BIN:-$(command -v mise 2>/dev/null || printf '%s/.local/bin/mise' "$HOME")}"
        _MISE_DATA="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
        _MISE_CFG="${MISE_CONFIG_DIR:-$HOME/.config/mise}"
        _MISE_CACHE="${MISE_CACHE_DIR:-$HOME/.cache/mise}"

        if [[ ! -f "$_MISE_BIN" ]]; then
            printf '[FATAL] --mise-passthrough: mise binary not found at %s\n' "$_MISE_BIN" >&2
            exit 1
        fi
        if [[ ! -d "$_MISE_DATA" ]]; then
            printf '[FATAL] --mise-passthrough: MISE_DATA_DIR not found at %s\n' "$_MISE_DATA" >&2
            exit 1
        fi

        _MISE_BIND="--ro-bind"
        [[ "$MISE_PASSTHROUGH" == "rw" ]] && _MISE_BIND="--bind"

        # Bind mise binary only if --local-bin-passthrough is NOT already covering
        # the ~/.local/bin dir (which would include the mise binary).
        if [[ "$LOCAL_BIN_PASSTHROUGH" == "off" ]]; then
            bwrap_args+=(
                --dir     "/home/$virtual_user_name/.local"
                --dir     "/home/$virtual_user_name/.local/bin"
                --ro-bind "$_MISE_BIN" "/home/$virtual_user_name/.local/bin/mise"
            )
        fi

        # mise data dir (installs, shims, plugins) -> sandbox home path
        bwrap_args+=(
            --dir "/home/$virtual_user_name/.local/share"
            $_MISE_BIND "$_MISE_DATA" "/home/$virtual_user_name/.local/share/mise"
        )

        # Optional: mise config -> sandbox home (avoid same-path bind)
        if [[ -d "$_MISE_CFG" ]]; then
            bwrap_args+=(
                --dir         "/home/$virtual_user_name/.config"
                --ro-bind-try "$_MISE_CFG" "/home/$virtual_user_name/.config/mise"
            )
        else
            printf '[SYS-LOG] WARNING: --mise-passthrough: config not found at %s (skipping)\n' "$_MISE_CFG" >&2
        fi

        # Optional: mise cache -> sandbox home (avoid same-path bind)
        if [[ -d "$_MISE_CACHE" ]]; then
            bwrap_args+=(
                --dir         "/home/$virtual_user_name/.cache"
                --ro-bind-try "$_MISE_CACHE" "/home/$virtual_user_name/.cache/mise"
            )
        else
            printf '[SYS-LOG] WARNING: --mise-passthrough: cache not found at %s (skipping)\n' "$_MISE_CACHE" >&2
        fi

        # PATH: shims first, then sandbox local bin, then system.
        bwrap_args+=(
            --setenv PATH            "/home/$virtual_user_name/.local/share/mise/shims:/home/$virtual_user_name/.local/bin:/usr/bin:/bin"
            --setenv MISE_DATA_DIR   "/home/$virtual_user_name/.local/share/mise"
            --setenv MISE_CONFIG_DIR "/home/$virtual_user_name/.config/mise"
        )
    fi

    # --- STEP 10: Identity injection via FD ---
    bwrap_args+=(
        --ro-bind-data 9  /etc/passwd
        --ro-bind-data 10 /etc/group
        # Shadow /etc/profile and /etc/profile.d to prevent PATH contamination:
        --ro-bind-data 11 /etc/profile
        --tmpfs           /etc/profile.d
    )

    # --- MISC: Google Chrome in /opt (not under /usr, absent from virtual-roots) ---
    bwrap_args+=(
        --dir     /opt
        --ro-bind-try /opt/google /opt/google
    )

    # --- MISC: Shared data / font caches ---
    bwrap_args+=(
        --dir         /usr/share
        --ro-bind-try /usr/share /usr/share
        --dir         /var/cache
        --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig
    )

    # --- Environment variables always set inside sandbox ---
    bwrap_args+=(
        --setenv HOME          "/home/$virtual_user_name"
        --setenv USER          "$virtual_user_name"
        --setenv XDG_DATA_HOME "/home/$virtual_user_name/.local/share"
        --setenv XDG_STATE_HOME "/home/$virtual_user_name/.local/state"
        --setenv XDG_DATA_DIRS  "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
        --setenv MOZ_NO_REMOTE 1
        # Default PATH; overridden by --mise-passthrough or caller --setenv:
        --setenv PATH          "/usr/bin:/bin"
        --chdir "/home/$virtual_user_name"
    )

    # --- STEP 11: Lock root read-only ---
    # All --dir / --ro-bind mountpoints must be created ABOVE this line.
    bwrap_args+=(
        --remount-ro /
        # STEP 12: Re-apply home write-hole after root lockdown
        --bind "$abs_home" "/home/$virtual_user_name"
    )

    # --- Conditional env var injection (display, after root lock) ---
    if [[ "$WAYLAND_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(--setenv WAYLAND_DISPLAY "${WAYLAND_DISPLAY:-}")
    fi
    if [[ "$WAYLAND_PASSTHROUGH" == "true" || "$X11_PASSTHROUGH" == "true" ]]; then
        bwrap_args+=(--setenv DISPLAY "${DISPLAY:-}")
    fi
    if [[ "$X11_PASSTHROUGH" == "true" ]]; then
        if [[ -n "${XAUTHORITY:-}" && -f "$XAUTHORITY" ]]; then
            bwrap_args+=(
                --ro-bind "$XAUTHORITY" "/home/$virtual_user_name/.Xauthority"
                --setenv XAUTHORITY     "/home/$virtual_user_name/.Xauthority"
            )
        else
            bwrap_args+=(--setenv XAUTHORITY "${XAUTHORITY:-}")
        fi
    fi

    # --- Caller raw passthrough args (appended last; caller --setenv wins) ---
    if [[ ${#BWRAP_PASSTHROUGH_ARGS[@]} -gt 0 ]]; then
        bwrap_args+=("${BWRAP_PASSTHROUGH_ARGS[@]}")
    fi

    # --- Clean env prepend (default) / inherit env ---
    if [[ "$env_passthrough" != "true" ]]; then
        # Default: clear host env; prepend --clearenv + unset TERM
        bwrap_args=(
            "--clearenv"
            "${bwrap_args[@]}"
            --unsetenv TERM
        )
    else
        # Inherit mode: TERM passes through
        bwrap_args+=(--setenv TERM "${TERM:-dumb}")
    fi

    # --- PID 1 ---
    bwrap_args+=("--as-pid-1")

    # --- DRY-RUN GATE: print resolved argv, do not exec ---
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        printf '[DRY-RUN] bwrap argv (one token per line):\n'
        for _arg in bwrap "${bwrap_args[@]}"; do
            printf '  %s\n' "$_arg"
        done
        printf '[DRY-RUN] CMD: %s\n' "${command[*]}"
        return 0
    fi

    # FOREGROUND-HOLD PATTERN:
    # 1. --as-pid-1: our bash IS PID 1. CMD runs synchronously in foreground.
    # 2. After CMD exits, /proc polling loop (bash builtins ONLY -- no forks)
    #    keeps sandbox alive until all reparented orphan children exit.
    # 3. Exit with CMD exit code, not the poll loop code.
    exec bwrap "${bwrap_args[@]}" /bin/bash -c '
        trap ":" CHLD

        "$@"; _CMD_EXIT=$?

        while true; do
            children=""
            read -r children < /proc/1/task/1/children 2>/dev/null || true
            [ -z "$children" ] && break
            read -t 0.5 _ 2>/dev/null || true
        done

        exit "$_CMD_EXIT"
    ' -- "${command[@]}" \
        9<<<"$fake_passwd" \
        10<<<"$fake_group" \
        11<<<"$fake_profile"
}

# ==============================================================================
# USAGE / --help
# ==============================================================================

usage() {
    cat <<HELPEOF
$(basename "$0")  v0.3.0  --  Bubblewrap Sandbox Launcher
(c) 2026 Hanaden - Frederick Bloom. All rights reserved.

DESCRIPTION
  Launches a process inside a bubblewrap (bwrap) sandbox.
  Security model: default deny, empty virtual filesystem.
  Add only what is explicitly needed via --*-passthrough flags.

    !! IMPORTANT: --host-real-root becomes the sandbox's root filesystem
       itself via bind mount to /. It is used as-is from the host.
       Keep it as a clean OS skeleton plus your project-specific files.
       Default: ~/virtual-roots

SYNOPSIS
  $(basename "$0") [PASSTHROUGH]... [CONFIG]... [TESTING]... -- CMD [ARG...]

PASSTHROUGH FLAGS  (all default to most restrictive; ordered by implication)

  --net-passthrough       [true|false(default)]
      Share host network namespace. D-Bus is a local socket -- not network.
      Bare flag = true.

  --env-passthrough       [true|false(default)]
      Inherit host environment variables (copied by value; no write-back).
      Default (false) = clean environment. BREAKING CHANGE from v0.2.x
      (old default was inherit). Pass this flag to restore old behavior.
      Bare flag = true.

  --x11-passthrough       [true|false(default)]
      Bind X11 socket; inject DISPLAY, XAUTHORITY into sandbox.
      Also implied (true) by --wayland-passthrough, --gnome-passthrough,
      and --kde-passthrough.
      Bare flag = true.

  --wayland-passthrough   [true|false(default)]
      Bind Wayland compositor socket; inject WAYLAND_DISPLAY.
      -> implies --x11-passthrough true  (XWayland compat).
      Bare flag = true.

  --gnome-passthrough     [true|false(default)]
      Bind GNOME service sockets (dconf, keyring, gvfs, gcr).
      Enables native GTK theming and fonts.
      -> implies --x11-passthrough true.
      Does NOT imply --dbus-passthrough.
      Bare flag = true.

  --kde-passthrough       [true|false(default)]
      Bind KDE Plasma service sockets (kwallet5, KSMserver, drkonqi).
      Enables native Qt styling.
      -> implies --x11-passthrough true.
      Does NOT imply --dbus-passthrough.
      Bare flag = true.

  --audio-passthrough     [true|false(default)]
      Bind PipeWire and PulseAudio sockets. Required for sound.
      NOTE: PipeWire does not distinguish playback vs recording at socket level.
      Bare flag = true.

  --a11y-passthrough      [true|false(default)]
      Bind AT-SPI accessibility bus (/run/user/UID/at-spi/bus_1).
      Required for screen readers and accessibility tooling.
      Does NOT imply --dbus-passthrough.
      Bare flag = true.

  --dbus-passthrough      [true|false(default)]    *** SECURITY CRITICAL ***
      Bind D-Bus session bus (/run/user/UID/bus).
      [!] CRITICAL: Exposes host filesystem and services via portals:
        * File Pickers: Can read the FULL HOST filesystem (~/.ssh, ~/.aws, /etc).
        * Host Secret Stores: Queries GNOME Keyring / KWallet.
        * Host Process Execution: via org.freedesktop.systemd1.
      NEVER implied by any other flag. Must always be explicit.
      Bare flag = true.

  --mise-passthrough      [rw|ro(default)]
      Bind mise binary + data into sandbox home (.local/bin, .local/share/mise).
      Bound to /home/<user>/... paths inside sandbox.
      ro (default): existing tools work via shims; mise install blocked (EROFS).
      rw:           existing tools work; mise install writes to host data dir.
      Bare flag = ro. Combined with --local-bin-passthrough: bin dir is shared.

  --local-bin-passthrough [rw|ro(default)]
      Bind host ~/.local/bin -> sandbox /home/<user>/.local/bin.
      ro (default): host binaries visible and executable; no writes to bin dir.
      rw:           host binaries visible; sandbox can install to host bin dir.
      Bare flag = ro.

TESTING FLAGS

  --dry-run
      Resolve all flags and implication chains, print the final bwrap_args[]
      array (one argument per line), then exit 0. No bwrap is executed.
      Use to verify flag resolution and mount sequence before live invocation.

  --validate
      Run all conflict checks and implication chains; exit 0 if clean,
      exit 1 with [ERROR]/[DIAG]/[HINT] output if any problem found.
      No bwrap is executed. Stricter than --dry-run: also validates paths.

RAW BWRAP PASSTHROUGH (injected before --; appended after engine defaults)
  --ro-bind SRC DST   --bind SRC DST        --bind-try SRC DST
  --ro-bind-try SRC DST   --dev-bind SRC DST   --dev-bind-try SRC DST
  --symlink SRC DST   --setenv KEY VAL       --unsetenv KEY
  --dir PATH          --tmpfs PATH
  Caller --setenv overrides engine defaults (appended last; last wins).

CONFIGURATION FLAGS

  --virtual-user-name NAME
      Username inside sandbox. HOME=/home/NAME, USER=NAME.
      Default: sandbox_user

  --host-real-root PATH
      Host directory used as-is; bound as sandbox root /.
      Default: ~/virtual-roots

  --host-real-home-parent PATH
      Host directory containing user home subdirectories.
      Actual home bound: PATH/NAME -> /home/NAME.
      Default: HOST_REAL_ROOT/home

ERRORS -- any conflict or ambiguity exits 1 with structured output:
  [ERROR] flag=<flag> value=<value> reason=<why>
  [DIAG]  expected=[<valid-values>] received=<value>
  [DIAG]  conflict=<flag-a>:<value-a>  vs  <flag-b>:<value-b>
  [HINT]  <corrective action>

  Detected conflicts:
    boolean flag + ro|rw qualifier          -> wrong qualifier type
    graded  flag + true|false qualifier     -> wrong qualifier type
    any flag + false qualifier              -> false is implicit; omit the flag
    same flag specified twice               -> duplicate, ambiguous
    --wayland|gnome|kde true + --x11 false -> implication conflict
    missing -- before CMD                   -> missing command separator
    --host-real-root not a directory        -> path missing (zero side-effects)
    --host-real-home-parent/USER missing    -> home dir missing

SECURITY TIERS
  Tier 1 (media):      --net-passthrough --wayland-passthrough --audio-passthrough
    Network, display, audio via direct kernel sockets. No host FS escape.

  Tier 2 (accessible): Tier 1 + --a11y-passthrough
    Adds AT-SPI. No new host FS escape.

  Tier 3 (desktop):    Tier 2 + --gnome-passthrough / --kde-passthrough
    Native desktop themes, fonts, settings. No host FS escape.

  Tier 4 (portal):     Tier 3 + --dbus-passthrough
    [!] PUNCHES SECURITY HOLE. Portal file picker can exfiltrate host files.

EXAMPLE
  VIRTUAL_ROOT=~/virtual-roots/myproject
  mkdir -p \$VIRTUAL_ROOT/home/sandbox_user

  $(basename "$0")                              \\
    --net-passthrough                            \\
    --env-passthrough                            \\
    --wayland-passthrough                        \\
    --audio-passthrough                          \\
    --mise-passthrough      ro                   \\
    --local-bin-passthrough ro                   \\
    --host-real-root        \$VIRTUAL_ROOT        \\
    --host-real-home-parent \$VIRTUAL_ROOT/home   \\
    -- bash --norc --noprofile

  # Dry-run to inspect resolved bwrap_args before live invocation:
  $(basename "$0") --dry-run [FLAGS] -- bash

  # Validate flags only (no exec, checks paths):
  $(basename "$0") --validate [FLAGS] -- bash
HELPEOF
    exit 0
}

# ==============================================================================
# DEFAULTS
# ==============================================================================

_UID=$(id -u)

NET_PASSTHROUGH="false"
ENV_PASSTHROUGH="false"
X11_PASSTHROUGH="false"
WAYLAND_PASSTHROUGH="false"
AUDIO_PASSTHROUGH="false"
A11Y_PASSTHROUGH="false"
DBUS_PASSTHROUGH="false"
GNOME_PASSTHROUGH="false"
KDE_PASSTHROUGH="false"
MISE_PASSTHROUGH="off"         # off | ro | rw
LOCAL_BIN_PASSTHROUGH="off"    # off | ro | rw
DRY_RUN="false"
VALIDATE_ONLY="false"

VIRTUAL_USER_NAME_DEFAULT="sandbox_user"
HOST_REAL_ROOT_DIR_DEFAULT="${HOME}/virtual-roots"
# HOST_REAL_HOME_PARENT has no static default — derived post-parse as
# ${HOST_REAL_ROOT_DIR}/home, allowing --host-real-root to influence it.

VIRTUAL_USER_NAME="$VIRTUAL_USER_NAME_DEFAULT"
HOST_REAL_ROOT_DIR="$HOST_REAL_ROOT_DIR_DEFAULT"
HOST_REAL_HOME_PARENT=""   # empty = derive from HOST_REAL_ROOT_DIR after parse
TARGET_CMD=()
BWRAP_PASSTHROUGH_ARGS=()

# ==============================================================================
# HOST PREFLIGHT (runs BEFORE argument parsing — BwrapPreflight.feat)
# ==============================================================================

preflight_check() {
    # PF-BIN: bwrap binary MUST be on PATH
    if ! command -v bwrap >/dev/null 2>&1; then
        printf '[FATAL] bwrap binary not found on PATH\n' >&2
        printf '[DIAG]  command -v bwrap returned non-zero\n' >&2
        printf '[HINT]  Install: apt install bubblewrap  OR  dnf install bubblewrap\n' >&2
        exit 2
    fi

    # PF-UID: newuidmap binary MUST be on PATH
    if ! command -v newuidmap >/dev/null 2>&1; then
        printf '[FATAL] newuidmap binary not found on PATH\n' >&2
        printf '[DIAG]  command -v newuidmap returned non-zero\n' >&2
        printf '[HINT]  Install: apt install uidmap  OR  dnf install shadow-utils\n' >&2
        exit 2
    fi

    # PF-GID: newgidmap binary MUST be on PATH
    if ! command -v newgidmap >/dev/null 2>&1; then
        printf '[FATAL] newgidmap binary not found on PATH\n' >&2
        printf '[DIAG]  command -v newgidmap returned non-zero\n' >&2
        printf '[HINT]  Install: apt install uidmap  OR  dnf install shadow-utils\n' >&2
        exit 2
    fi

    # PF-NS: Unprivileged user namespaces MUST be enabled
    # BWRAP_PREFLIGHT_PROC_BASE allows test injection (default: /proc/sys)
    local proc_base="${BWRAP_PREFLIGHT_PROC_BASE:-/proc/sys}"
    local userns_file="${proc_base}/kernel/unprivileged_userns_clone"
    local maxns_file="${proc_base}/user/max_user_namespaces"
    local ns_val=""

    if [ -r "$userns_file" ]; then
        ns_val="$(cat "$userns_file" 2>/dev/null | tr -d '[:space:]')"
        if [ "$ns_val" = "0" ]; then
            printf '[FATAL] Unprivileged user namespaces are disabled\n' >&2
            printf '[DIAG]  %s = 0\n' "$userns_file" >&2
            printf '[HINT]  Enable: sudo sysctl -w kernel.unprivileged_userns_clone=1\n' >&2
            exit 2
        fi
    elif [ -r "$maxns_file" ]; then
        ns_val="$(cat "$maxns_file" 2>/dev/null | tr -d '[:space:]')"
        if [ "$ns_val" = "0" ]; then
            printf '[FATAL] Unprivileged user namespaces are disabled\n' >&2
            printf '[DIAG]  %s = 0\n' "$maxns_file" >&2
            printf '[HINT]  Enable: sudo sysctl -w user.max_user_namespaces=65536\n' >&2
            exit 2
        fi
    fi
    # If neither file exists, skip check (kernel may not expose these knobs)
}

preflight_check

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================


while [[ "$#" -gt 0 ]]; do
    case "$1" in

        # --- BOOLEAN PASSTHROUGHS ---

        --net-passthrough)
            _r=$(_parse_bool "--net-passthrough" "${2:-}" "$NET_PASSTHROUGH")
            NET_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --env-passthrough)
            _r=$(_parse_bool "--env-passthrough" "${2:-}" "$ENV_PASSTHROUGH")
            ENV_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --x11-passthrough)
            _r=$(_parse_bool "--x11-passthrough" "${2:-}" "$X11_PASSTHROUGH")
            X11_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --wayland-passthrough)
            _r=$(_parse_bool "--wayland-passthrough" "${2:-}" "$WAYLAND_PASSTHROUGH")
            WAYLAND_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --audio-passthrough)
            _r=$(_parse_bool "--audio-passthrough" "${2:-}" "$AUDIO_PASSTHROUGH")
            AUDIO_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --a11y-passthrough)
            _r=$(_parse_bool "--a11y-passthrough" "${2:-}" "$A11Y_PASSTHROUGH")
            A11Y_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --dbus-passthrough)
            _r=$(_parse_bool "--dbus-passthrough" "${2:-}" "$DBUS_PASSTHROUGH")
            DBUS_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --gnome-passthrough)
            _r=$(_parse_bool "--gnome-passthrough" "${2:-}" "$GNOME_PASSTHROUGH")
            GNOME_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --kde-passthrough)
            _r=$(_parse_bool "--kde-passthrough" "${2:-}" "$KDE_PASSTHROUGH")
            KDE_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        # --- GRADED PASSTHROUGHS ---

        --mise-passthrough)
            _r=$(_parse_graded "--mise-passthrough" "${2:-}" "$MISE_PASSTHROUGH")
            MISE_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        --local-bin-passthrough)
            _r=$(_parse_graded "--local-bin-passthrough" "${2:-}" "$LOCAL_BIN_PASSTHROUGH")
            LOCAL_BIN_PASSTHROUGH="${_r%%:*}"
            [[ "${_r##*:}" == "2" ]] && shift 2 || shift 1
            ;;

        # --- CONFIGURATION FLAGS ---

        --virtual-user-name)
            [[ -z "${2:-}" ]] && { printf '[ERROR] --virtual-user-name requires NAME argument\n' >&2; exit 1; }
            [[ -n "${_VIRTUAL_USER_NAME_SET:-}" ]] && {
                printf '[ERROR] --virtual-user-name specified more than once\n' >&2
                printf '[DIAG]  First value: %s  Duplicate: %s\n' "$VIRTUAL_USER_NAME" "$2" >&2
                printf '[HINT]  Specify --virtual-user-name exactly once.\n' >&2
                exit 1
            }
            VIRTUAL_USER_NAME="$2"; _VIRTUAL_USER_NAME_SET=1; shift 2
            ;;

        --host-real-root)
            [[ -z "${2:-}" ]] && { printf '[ERROR] --host-real-root requires PATH argument\n' >&2; exit 1; }
            [[ -n "${_HOST_REAL_ROOT_SET:-}" ]] && {
                printf '[ERROR] --host-real-root specified more than once\n' >&2
                printf '[DIAG]  First value: %s  Duplicate: %s\n' "$HOST_REAL_ROOT_DIR" "$2" >&2
                printf '[HINT]  Specify --host-real-root exactly once.\n' >&2
                exit 1
            }
            HOST_REAL_ROOT_DIR="${2/#\~/$HOME}"
            HOST_REAL_ROOT_DIR="${HOST_REAL_ROOT_DIR%/}"  # strip trailing slash
            _HOST_REAL_ROOT_SET=1; shift 2
            ;;

        --host-real-home-parent)
            [[ -z "${2:-}" ]] && { printf '[ERROR] --host-real-home-parent requires PATH argument\n' >&2; exit 1; }
            [[ -n "${_HOST_REAL_HOME_PARENT_SET:-}" ]] && {
                printf '[ERROR] --host-real-home-parent specified more than once\n' >&2
                printf '[DIAG]  First value: %s  Duplicate: %s\n' "$HOST_REAL_HOME_PARENT" "$2" >&2
                printf '[HINT]  Specify --host-real-home-parent exactly once.\n' >&2
                exit 1
            }
            HOST_REAL_HOME_PARENT="${2/#\~/$HOME}"
            HOST_REAL_HOME_PARENT="${HOST_REAL_HOME_PARENT%/}"  # strip trailing slash
            _HOST_REAL_HOME_PARENT_SET=1; shift 2
            ;;

        # --- RAW BWRAP PASSTHROUGH FLAGS ---

        --ro-bind|--ro-bind-try|--bind|--bind-try|--dev-bind|--dev-bind-try)
            BWRAP_PASSTHROUGH_ARGS+=("$1" "$2" "$3"); shift 3 ;;
        --symlink)
            BWRAP_PASSTHROUGH_ARGS+=("$1" "$2" "$3"); shift 3 ;;
        --setenv)
            BWRAP_PASSTHROUGH_ARGS+=("$1" "$2" "$3"); shift 3 ;;
        --unsetenv)
            BWRAP_PASSTHROUGH_ARGS+=("$1" "$2"); shift 2 ;;
        --dir)
            BWRAP_PASSTHROUGH_ARGS+=("$1" "$2"); shift 2 ;;
        --tmpfs)
            BWRAP_PASSTHROUGH_ARGS+=("$1" "$2"); shift 2 ;;

        # --- META ---

        -h|--help) usage ;;

        --dry-run)
            DRY_RUN="true"
            shift 1
            ;;

        --validate)
            VALIDATE_ONLY="true"
            shift 1
            ;;

        --)
            shift; TARGET_CMD=("$@"); break ;;

        -*)
            printf '[ERROR] Unknown flag: %s\n' "$1" >&2
            printf '[HINT]  Run with --help to see valid flags\n' >&2
            exit 1
            ;;

        *)
            printf '[ERROR] Missing -- separator before CMD: %s\n' "$1" >&2
            printf '[DIAG]  reason=missing command separator\n' >&2
            printf '[HINT]  Add -- before your command: bwrap-enhanced.sh [FLAGS] -- %s\n' "$*" >&2
            exit 1
            ;;
    esac
done

# ==============================================================================
# POST-PARSE: IMPLICATION CHAINS
# wayland -> x11, gnome -> x11, kde -> x11
# ==============================================================================

for _implied_by in wayland gnome kde; do
    _var="${_implied_by^^}_PASSTHROUGH"
    if [[ "${!_var}" == "true" && "$X11_PASSTHROUGH" == "false" ]]; then
        X11_PASSTHROUGH="true"
    fi
done

# ==============================================================================
# VALIDATION
# ==============================================================================

# Derive HOST_REAL_HOME_PARENT from HOST_REAL_ROOT_DIR if not explicitly set
[[ -z "$HOST_REAL_HOME_PARENT" ]] && HOST_REAL_HOME_PARENT="${HOST_REAL_ROOT_DIR}/home"

HOST_REAL_HOME_DIR="${HOST_REAL_HOME_PARENT}/${VIRTUAL_USER_NAME}"

if [[ ${#TARGET_CMD[@]} -eq 0 ]]; then
    printf '[ERROR] No CMD provided\n' >&2
    printf '[DIAG]  reason=missing required target command\n' >&2
    printf '[HINT]  Add -- CMD after flags, e.g.: bwrap-enhanced.sh [FLAGS] -- bash\n' >&2
    printf '\n' >&2
    usage
fi

if [[ "$DRY_RUN" != "true" && ! -d "$HOST_REAL_ROOT_DIR" ]]; then
    printf '[ERROR] --host-real-root path does not exist\n' >&2
    printf '[DIAG]  path=%s\n' "$HOST_REAL_ROOT_DIR" >&2
    printf '[HINT]  Create it first (zero side-effects: script will not create dirs):\n' >&2
    printf '        mkdir -p "%s"\n' "$HOST_REAL_ROOT_DIR" >&2
    exit 1
fi

if [[ "$DRY_RUN" != "true" && ! -d "$HOST_REAL_HOME_DIR" ]]; then
    printf '[ERROR] sandbox home directory does not exist on host\n' >&2
    printf '[DIAG]  resolved=%s\n' "$HOST_REAL_HOME_DIR" >&2
    printf '[DIAG]  VIRTUAL_USER_NAME=%s\n' "$VIRTUAL_USER_NAME" >&2
    printf '[DIAG]  HOST_REAL_HOME_PARENT=%s\n' "$HOST_REAL_HOME_PARENT" >&2
    printf '[HINT]  Create it first (zero side-effects: script will not create dirs):\n' >&2
    printf '        mkdir -p "%s"\n' "$HOST_REAL_HOME_DIR" >&2
    exit 1
fi

# ==============================================================================
# DRY-RUN / VALIDATE GATE
# ==============================================================================

if [[ "$VALIDATE_ONLY" == "true" ]]; then
    printf '[OK] Validation passed. No conflicts detected.\n'
    printf '[DIAG] NET=%s ENV=%s X11=%s WAYLAND=%s GNOME=%s KDE=%s\n' \
        "$NET_PASSTHROUGH" "$ENV_PASSTHROUGH" "$X11_PASSTHROUGH" \
        "$WAYLAND_PASSTHROUGH" "$GNOME_PASSTHROUGH" "$KDE_PASSTHROUGH"
    printf '[DIAG] AUDIO=%s A11Y=%s DBUS=%s MISE=%s LOCALBIN=%s\n' \
        "$AUDIO_PASSTHROUGH" "$A11Y_PASSTHROUGH" "$DBUS_PASSTHROUGH" \
        "$MISE_PASSTHROUGH" "$LOCAL_BIN_PASSTHROUGH"
    printf '[DIAG] VIRTUAL_USER=%s\n' "$VIRTUAL_USER_NAME"
    printf '[DIAG] HOST_REAL_ROOT=%s\n' "$HOST_REAL_ROOT_DIR"
    printf '[DIAG] HOST_REAL_HOME=%s\n' "$HOST_REAL_HOME_DIR"
    exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
    # Build bwrap_args without executing — reuse exec_sandbox in print mode.
    # We reconstruct the args array here so the user sees the exact argv bwrap
    # would receive, one token per line.
    printf '[DRY-RUN] Resolved bwrap_args (one token per line):\n'
    # Call exec_sandbox with DRY_RUN exported so it prints instead of exec-ing.
    DRY_RUN="true" exec_sandbox \
        "$ENV_PASSTHROUGH" \
        "$VIRTUAL_USER_NAME" \
        "$HOST_REAL_ROOT_DIR" \
        "$HOST_REAL_HOME_DIR" \
        "${TARGET_CMD[@]}"
    exit 0
fi

# ==============================================================================
# INVOKE
# ==============================================================================

exec_sandbox \
    "$ENV_PASSTHROUGH" \
    "$VIRTUAL_USER_NAME" \
    "$HOST_REAL_ROOT_DIR" \
    "$HOST_REAL_HOME_DIR" \
    "${TARGET_CMD[@]}"
