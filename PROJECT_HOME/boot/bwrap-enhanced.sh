#!/usr/bin/env bash
# *!! IMPORTANT - AI - Immutable file without user permission - ask user
# ==============================================================================
# NAME:      bwrap-enhanced.sh
# VERSION:   1.0.0
# ARCH:      Linux Namespace Isolation & VFS Remapping (Debian 12+, Usr-Merge)
# AUTHOR:    Frederick Bloom <devlabs@hanaden.com>
# COPYRIGHT: (c) 2026 Hanaden - Frederick Bloom. All rights reserved.
# LICENSE:   Proprietary. Unauthorized use, reproduction, or distribution
#            is strictly prohibited.
# PROJECT:   hanaden AI Bootloader for all AI-Agents and AI-Processors
# REPO:      hanaden-ai-booter
# ==============================================================================
#
# ── FUNCTION: exec_sandbox ────────────────────────────────────────────────────
# [FULL SDD SPECIFICATION]
#
# PURPOSE:
#   Execute a target CMD inside a multi-namespace bwrap jail (User, PID, Mount,
#   Network, IPC, UTS). The sandbox presents a clean, isolated Linux environment
#   with a controlled, explicit filesystem view. Only what is explicitly bound
#   exists inside the sandbox.
#
# IDENTITY FILES:
#   A synthetic /etc/passwd and /etc/group are injected via FD at runtime:
#     - All system accounts with UID/GID < 1000 are copied from the host.
#     - A virtual user entry is added:
#         [VIRTUAL_USER_NAME]:x:[HOST_UID]:[HOST_GID]:...:/home/[VIRTUAL_USER_NAME]:/bin/bash
#     - nobody:x:65534:65534 is appended.
#   These are passed as here-strings on FD 9 and FD 10 via --ro-bind-data.
#   Test: bwrap-enhanced.sh bash -c 'tail -n2 /etc/passwd; id'
#
# ── MOUNT SEQUENCE (ORDER-DEPENDENT) ─────────────────────────────────────────
#
#   bwrap processes --bind/--ro-bind/--remount-ro arguments LEFT TO RIGHT.
#   The sequence below is the exact order applied in exec_sandbox():
#
#   STEP │ bwrap flag                              │ Mode │ Persists to Host?
#   ─────┼─────────────────────────────────────────┼──────┼──────────────────
#    1   │ --bind $HOST_REAL_ROOT_DIR /             │  RW  │ Yes (host root)
#    2   │ --ro-bind /usr /usr                      │  RO  │ No
#    2   │ --symlink usr/lib /lib                   │  —   │ No (symlink)
#    2   │ --symlink usr/lib64 /lib64               │  —   │ No (symlink)
#    2   │ --symlink usr/bin /bin                   │  —   │ No (symlink)
#    3   │ --ro-bind-try /etc/alternatives ...      │  RO  │ No
#    3   │ --ro-bind-try /etc/resolv.conf ...       │  RO  │ No
#    3   │ --ro-bind-try /etc/ssl, /etc/pki ...     │  RO  │ No
#    3   │ --ro-bind-try /etc/ld.so.cache ...       │  RO  │ No
#    4   │ --ro-bind /homes /homes                  │  RO  │ No (visible, ro)
#    5   │ --proc /proc                             │  RW* │ No (kernel API)
#    5   │ --dev-bind /dev /dev                     │  RW  │ Pass-through
#    6   │ --tmpfs /dev/shm                         │  RW  │ No (lost on exit)
#    6   │ --tmpfs /tmp                             │  RW  │ No (lost on exit)
#    6   │ --ro-bind-try /tmp/.X11-unix ...         │  RO  │ No (X11 socket)
#    7   │ --bind-try /run/dbus /run/dbus           │  RW  │ Pass-through
#    7   │ --bind-try /run/user/UID /run/user/UID   │  RW  │ Pass-through
#    8   │ --tmpfs /home                            │  RW  │ No (anon layer)
#    8   │ --dir /home/[VIRTUAL_USER_NAME]          │  —   │ No (mkdir only)
#    9   │ --bind $HOST_REAL_HOME_DIR               │  RW  │ *** YES ***
#    │   │       /home/[VIRTUAL_USER_NAME]          │      │ (write-hole open)
#   10   │ --ro-bind-data 9 /etc/passwd             │  RO  │ No (injected FD)
#   10   │ --ro-bind-data 10 /etc/group             │  RO  │ No (injected FD)
#   11   │ --remount-ro /                           │  —   │ Locks root RO
#   12   │ --bind $HOST_REAL_HOME_DIR               │  RW  │ *** YES ***
#    │   │       /home/[VIRTUAL_USER_NAME]          │      │ (write-hole re-confirmed)
#
#   KEY NOTES:
#   - Steps 9 and 12 both bind the SAME host dir to the SAME virtual path.
#     Step 9 is the initial bind (before root lockdown).
#     Step 12 re-applies the bind AFTER --remount-ro to guarantee it stays RW.
#     This is the "write-hole" / "EGRESS" pattern: the root is immutable,
#     but /home/[VIRTUAL_USER_NAME] is punched through as a live RW overlay.
#   - /tmp is a FRESH tmpfs every sandbox invocation. Nothing written to /tmp
#     survives sandbox exit. Do NOT use /tmp for output that must be collected.
#   - /homes is visible read-only inside the sandbox (host paths accessible).
#
# ── PERSISTENCE CONTRACT ──────────────────────────────────────────────────────
#
#   PATH inside sandbox                   │ Persists to host?  │ Why
#   ──────────────────────────────────────┼────────────────────┼────────────────
#   /home/[VIRTUAL_USER_NAME]/**          │ YES ✅             │ RW --bind
#   /home/[VIRTUAL_USER_NAME]/coverage/** │ YES ✅             │ RW --bind (subdir)
#   /tmp/**                               │ NO  ❌             │ tmpfs, lost on exit
#   /dev/**                               │ PASSTHROUGH        │ real device nodes
#   /usr/**, /etc/**                      │ NO  ❌             │ read-only bind
#   /homes/**                             │ NO  ❌             │ read-only bind
#
#   COVERAGE IMPLICATION (bashcov / SimpleCov):
#     SimpleCov reads its output directory from the env var SIMPLECOV_COVERAGE_DIR.
#     This MUST be set to a path under /home/[VIRTUAL_USER_NAME]/ (e.g.
#     /home/[VIRTUAL_USER_NAME]/coverage) when running inside this sandbox.
#     If it is set to /tmp/ or any other non-home path, the .resultset.json
#     file will be LOST when the sandbox exits and coverage will read as 0%.
#     The --coverage-dir CLI flag passed to bashcov is IGNORED by SimpleCov;
#     only the env var is honored.
#
# ── ENVIRONMENT ───────────────────────────────────────────────────────────────
#
#   --clear-env flag:
#     If passed, ALL host env vars are discarded before entering the sandbox.
#     Only explicitly set vars (HOME, USER, PATH, DISPLAY, TERM, XAUTHORITY,
#     XDG_DATA_HOME, XDG_STATE_HOME) are available inside.
#   Without --clear-env:
#     Host env is inherited, then the explicit --setenv values override it.
#
#   Env vars set inside sandbox (via --setenv):
#     HOME=/home/[VIRTUAL_USER_NAME]
#     USER=[VIRTUAL_USER_NAME]
#     PATH=/usr/bin:/bin   ← caller should override via `env PATH=... CMD`
#     DISPLAY, TERM, XAUTHORITY  ← passed from host
#     XDG_DATA_HOME=/home/[VIRTUAL_USER_NAME]/.local/share
#     XDG_STATE_HOME=/home/[VIRTUAL_USER_NAME]/.local/state
#     MOZ_NO_REMOTE=1
#
# ── USAGE ─────────────────────────────────────────────────────────────────────
#
#   $0 [OPTIONS] [-- CMD...]
#
#   OPTIONS:
#     --clear-env
#         Strip host env before entering sandbox.
#     --virtual-user-name NAME       [default: sandbox-user]
#         Username inside sandbox. HOME=/home/NAME, USER=NAME.
#     --host-real-root PATH          [default: ~/virtual-roots]
#         Host path bound to VFS /. Must exist. Typically use / for host-native.
#     --host-real-home-parent PATH   [default: ~/virtual-roots/home]
#         Host directory containing [NAME] subdirectory. Must exist.
#         Actual home bound: HOST_REAL_HOME_PARENT/NAME -> /home/NAME
#     --                             Separator. Remaining args = CMD.
#
#   TYPICAL INVOCATION (run_tests.sh pattern):
#     bwrap-enhanced.sh \
#       --host-real-root / \
#       --host-real-home-parent /path/to/sandbox-run-dir \
#       --virtual-user-name testuser_abc123 \
#       -- env \
#         HOME=/home/testuser_abc123 \
#         SIMPLECOV_COVERAGE_DIR=/home/testuser_abc123/coverage \
#         PATH=/usr/local/bin:/usr/bin:/bin \
#         bats --timing --tap test_foo.bats
#
# ── CONSTRAINTS ───────────────────────────────────────────────────────────────
#
#   ZERO SIDE EFFECTS: This script MUST NOT create directories or mutate host
#   state. All required paths must be pre-created by the caller before invocation.
#   Violations are caught by the validation block and cause an immediate fatal exit.
#
# ── FOREGROUND-HOLD STRATEGY ──────────────────────────────────────────────────
#
#   Uses --as-pid-1: the wrapper bash IS PID 1 inside the sandbox.
#   The user CMD runs synchronously in the foreground (no background fork).
#   After CMD exits, a /proc polling loop (bash builtins only — no forks) keeps
#   the sandbox alive until all reparented orphan child processes have exited.
#   This prevents bwrap from tearing down the sandbox while GUI apps are still
#   running after their launcher script has exited.
#
# ── IDENTITY INJECTION EXAMPLE ────────────────────────────────────────────────
#
#   Run this to verify passwd/group/id behavior inside the sandbox:
#     ./bwrap-enhanced.sh --host-real-root / -- bash -c \
#       'echo "=PASSWD="; tail -n2 /etc/passwd; echo "=GROUP="; tail -n2 /etc/group; echo "=ID="; id'
#
# ==============================================================================

set -e

function exec_sandbox() {
    local clear_env_flag="$1"
    local virtual_user_name="$2"
    local mounted_new_root_dir="$3"
    local mounted_home_dir="$4"
    shift 4
    local command=("$@")

    # Resolve absolute paths to prevent VFS resolution ambiguity
    local abs_root=$(realpath "$mounted_new_root_dir")
    local abs_home=$(realpath "$mounted_home_dir")

    echo "[SYS-LOG] Initializing SDD-compliant Sandbox..." >&2
    echo "[SYS-LOG] Pivot: $abs_root -> /" >&2
    echo "[SYS-LOG] Egress: $abs_home -> /home/$virtual_user_name" >&2
    if [[ "$clear_env_flag" == "true" ]]; then
        echo "[SYS-LOG] Sanitizing Environment (--clear-env passed)." >&2
    else
        echo "[SYS-LOG] Inheriting Environment." >&2
    fi

    local sys_passwd
    sys_passwd=$(awk -F: '$3 < 1000 && $4 < 1000' /etc/passwd 2>/dev/null || true)
    local fake_passwd="root:x:0:0:root:/root:/bin/bash
${sys_passwd}
${virtual_user_name}:x:$(id -u):$(id -g):${virtual_user_name}:/home/${virtual_user_name}:/bin/bash
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin"

    local sys_group
    sys_group=$(awk -F: '$3 < 1000' /etc/group 2>/dev/null || true)
    local fake_group="${sys_group}
${virtual_user_name}:x:$(id -g):${virtual_user_name}:/home/${virtual_user_name}:/bin/bash"

    # Inline /etc/profile — self-contained, no sibling file dependency (RELOC-01)
    local fake_profile
    fake_profile="#!/bin/sh
PATH=/usr/bin:/bin
export PATH"

    # Build base bwrap arguments as an array to safely inject the clear-env logic
    local bwrap_args=(
        --unshare-user
        --unshare-ipc
        --unshare-pid
        --unshare-uts
        --unshare-cgroup
    )

    # Apply Default-Deny network posture
    if [[ "$SHARE_NETWORK" == "false" ]]; then
        bwrap_args+=("--unshare-net")
    else
        echo "[SYS-LOG] WARNING: Network isolation disabled (--share-net passed)." >&2
    fi



    bwrap_args+=(
        --die-with-parent
        --hostname "sandbox-vfs"
        --bind "$abs_root" /
        --dir /usr
        --ro-bind /usr /usr
        --symlink usr/lib /lib
        --symlink usr/lib64 /lib64
        --symlink usr/bin /bin
        --dir /etc
        --ro-bind-try /etc/alternatives /etc/alternatives
        --ro-bind-try /etc/fonts /etc/fonts
        --ro-bind-try /etc/machine-id /etc/machine-id
        # SHELL INIT — intentionally NOT binding /etc/profile, /etc/profile.d,
        # or /etc/bash.bashrc. These can mutate PATH and contaminate isolation.
        # The sandbox virtual home's .bashrc is the only shell init in scope.
        # DNS RESOLUTION:
        # Without these, glibc's resolver (getaddrinfo) cannot resolve hostnames.
        --ro-bind-try /etc/resolv.conf /etc/resolv.conf
        --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf
        --ro-bind-try /etc/hosts /etc/hosts
        --ro-bind-try /etc/host.conf /etc/host.conf
        --ro-bind-try /etc/services /etc/services
        --ro-bind-try /etc/protocols /etc/protocols
        # SSL/TLS CERTIFICATES:
        # Firefox and any HTTPS client need the CA trust store to validate certs.
        --ro-bind-try /etc/ssl /etc/ssl
        --ro-bind-try /etc/pki /etc/pki
        # TIMEZONE & DYNAMIC LINKER:
        # TIMEZONE: /etc/localtime is often a symlink; bwrap can't bind-mount
        # symlink targets into --dir /etc. TZ is set via env var if needed.
        # --ro-bind-try /etc/localtime /etc/localtime
        --ro-bind-try /etc/ld.so.cache /etc/ld.so.cache
        # DESKTOP ENVIRONMENT & GUI INFRASTRUCTURE:
        # XDG app configs (KDE, GNOME, XFCE, Cinnamon all use /etc/xdg)
        --ro-bind-try /etc/xdg /etc/xdg
        # GTK theming (GNOME, XFCE, Cinnamon)
        --ro-bind-try /etc/gtk-3.0 /etc/gtk-3.0
        --ro-bind-try /etc/gtk-4.0 /etc/gtk-4.0
        # dconf system defaults (GNOME, Cinnamon)
        --ro-bind-try /etc/dconf /etc/dconf
        # D-Bus system bus config
        --ro-bind-try /etc/dbus-1 /etc/dbus-1
        # X11 server config
        --ro-bind-try /etc/X11 /etc/X11
        # MIME type associations (xdg-open, browsers)
        --ro-bind-try /etc/mime.types /etc/mime.types
        # BROWSER-SPECIFIC POLICIES:
        --ro-bind-try /etc/firefox-esr /etc/firefox-esr
        --ro-bind-try /etc/chromium /etc/chromium
        --ro-bind-try /etc/chromium.d /etc/chromium.d
        --ro-bind-try /etc/opt/chrome /etc/opt/chrome
        # GSS/Kerberos (enterprise SSO login flows)
        --ro-bind-try /etc/gss /etc/gss
        --ro-bind-try /etc/krb5.conf /etc/krb5.conf
        --dir /usr/share
        --ro-bind-try /usr/share /usr/share
        --dir /var/cache
        --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig
        --proc /proc
        --dev-bind /dev /dev
        --tmpfs /dev/shm
        --tmpfs /tmp
        # X11 SOCKET PASSTHROUGH:
        # The tmpfs above wipes /tmp lean. GUI apps (Electron, GTK, Qt) need
        # /tmp/.X11-unix to connect to the X display server. Without this bind,
        # graphical applications will silently fail to open and exit immediately.
        --ro-bind-try /tmp/.X11-unix /tmp/.X11-unix
        # DBUS & XDG RUNTIME PASSTHROUGH:
        # Wayland compositors, PulseAudio, and D-Bus use /run.
        # GUI apps depend on DBus and XDG_RUNTIME_DIR to create IPC sockets.
        # These MUST be bound as writable (--bind-try), otherwise apps like
        # Cursor/VSCode will crash with "EROFS: read-only file system" when
        # trying to create their local domain sockets.
        --bind-try /run/dbus /run/dbus
        --bind-try /run/user/$(id -u) /run/user/$(id -u)
        # HOME OVERLAY:
        # Use a tmpfs on /home so bwrap can mkdir the user directory without
        # needing write permission on the bound root filesystem (critical when
        # --host-real-root is / on the live host).
        --tmpfs /home
        --dir "/home/$virtual_user_name"
        --bind "$abs_home" "/home/$virtual_user_name"
        --ro-bind-data 9 /etc/passwd
        --ro-bind-data 10 /etc/group
        --remount-ro /
        # Shadow host-only mount subtrees that must never be visible inside ex:
        #   /homes  — host autofs tree leaked via --bind / /
        #   /etc/profile.d — host login scripts contaminate PATH
        #   /etc/profile — replaced with a minimal version that only sets PATH
        --tmpfs /homes
        --ro-bind-data 11 /etc/profile
        --tmpfs /etc/profile.d
        --bind "$abs_home" "/home/$virtual_user_name"
        --setenv HOME "/home/$virtual_user_name"
        --setenv USER "$virtual_user_name"
        --setenv PATH /usr/bin:/bin
        --setenv XDG_DATA_HOME "/home/$virtual_user_name/.local/share"
        --setenv XDG_STATE_HOME "/home/$virtual_user_name/.local/state"
        --setenv MOZ_NO_REMOTE 1
        # GUI safety-net: profile.d is shadowed; ensure XDG_DATA_DIRS is always set
        # so GTK/Qt/Electron apps find themes, icons, and .desktop files.
        # Preserve parent value if set; fall back to Debian default otherwise.
        --setenv XDG_DATA_DIRS "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
        # Wayland display passthrough (Wayland compositors use this + XDG_RUNTIME_DIR)
        --setenv WAYLAND_DISPLAY "${WAYLAND_DISPLAY:-}"
        --chdir "/home/$virtual_user_name"
    )

    # Append caller-supplied passthrough args AFTER engine defaults.
    # bwrap processes flags in order — last --setenv PATH wins.
    # This ensures caller overrides (e.g., CAL-01 tool binding) take precedence.
    if [[ ${#BWRAP_PASSTHROUGH_ARGS[@]} -gt 0 ]]; then
        bwrap_args+=("${BWRAP_PASSTHROUGH_ARGS[@]}")
    fi

    # Conditionally prepend --clearenv if requested.
    # DISPLAY, TERM, XAUTHORITY are host-session vars — only pass them when
    # inheriting host env. With --clear-env they MUST NOT be visible inside.
    # Note: some bwrap builds inject TERM=dumb on non-tty even with --clearenv;
    # --unsetenv after --clearenv guarantees these vars are absent.
    if [[ "$clear_env_flag" == "true" ]]; then
        bwrap_args=(
            "--clearenv"
            "${bwrap_args[@]}"
            --unsetenv TERM
            --unsetenv DISPLAY
            --unsetenv XAUTHORITY
        )
    else
        bwrap_args+=(
            --setenv DISPLAY "${DISPLAY:-}"
            --setenv TERM "${TERM:-dumb}"
            --setenv XAUTHORITY "${XAUTHORITY:-}"
        )
    fi

    # FOREGROUND-HOLD (PID 1 INIT LOOP) - FIX FOR GUI APPS & INTERACTIVE SHELLS:
    # 1. We use --as-pid-1 so bwrap does NOT install its own init process,
    #    making our wrapper bash the actual PID 1.
    # 2. We launch the user's command synchronously in the foreground ("$@").
    #    This ensures interactive shells (like `bash`) retain full TTY access
    #    and job control without background suspension errors.
    # 3. GUI apps (Cursor, Firefox) typically fork/daemonize and the parent
    #    launcher exits. Since --unshare-pid gives us a PID namespace, the
    #    orphaned GUI processes are reparented to our bash (PID 1).
    #    So, AFTER the main command exits, we run a /proc polling loop to
    #    keep the sandbox alive until all reparented orphans have closed.
    bwrap_args+=("--as-pid-1")

    exec bwrap "${bwrap_args[@]}" /bin/bash -c '
        # Trap SIGCHLD to automatically reap zombie children
        trap ":" CHLD

        # 1. Launch the user command SYNCHRONOUSLY in the foreground.
        #    Capture exit code BEFORE the polling loop overwrites it.
        "$@"; _CMD_EXIT=$?

        # 2. Poll /proc until all children (including reparented orphans) exit.
        #
        # CRITICAL: Every command in this loop MUST be a bash builtin.
        # External commands (cat, sleep, etc.) fork child processes that
        # appear in /proc/1/task/1/children, creating false positives and
        # infinite loops.
        while true; do
            children=""
            read -r children < /proc/1/task/1/children 2>/dev/null || true
            if [ -z "$children" ]; then
                break
            fi
            read -t 0.5 _ 2>/dev/null || true
        done

        # 3. Exit with CMD exit code (not the poll loop exit code).
        exit "$_CMD_EXIT"
    ' -- "${command[@]}" 9<<<"$fake_passwd" 10<<<"$fake_group" 11<<<"$fake_profile"
}

# --- CLI INTERFACE ---
function usage() {
    cat << EOF
================================================================================
                        bwrap-enhanced Sandbox Launcher
================================================================================

Usage: $0 [OPTIONS] [CMD...]

OPTIONS:
  --clear-env
      Clears all environment variables from the host before passing them into
      the sandbox. Only explicit values like HOME, USER, PATH, DISPLAY, and TERM
      will be passed in.

  --virtual-user-name [USER_NAME]
      Sets the virtual user name inside the sandbox.
      Inside the sandbox, \$USER will be this value, and the home directory
      will be set to /home/[USER_NAME].
      [Default: sandbox-user]

  --host-real-root [PATH]
      The path on the host system that should act as the root filesystem (/)
      inside the sandbox. This directory must exist and typically contains
      a bootable linux filesystem tree.
      [Default: ~/virtual-roots]

  --host-real-home-parent [PATH]
      The path on the host system that contains the user home directories.
      The actual home directory bound into the sandbox will be resolved as:
      \${HOST_REAL_HOME_PARENT}/\${VIRTUAL_USER_NAME}
      [Default: ~/virtual-roots/home]

CMD:
  The command and its arguments to run inside the sandbox (e.g., /bin/bash).
  Must be provided.

EXAMPLES:
  1. TEST CASE 1: Fast-exit CLI command (Verifies basic sandbox function)
     $0 --host-real-root / --host-real-home-parent ~/virtual-roots/home /bin/echo "Works"
     * Expected: Prints "Works" and exits immediately cleanly.

  2. TEST CASE 2: Interactive Shell (Verifies TTY and Job Control)
     $0 --host-real-root / --host-real-home-parent ~/virtual-roots/home /bin/bash
     * Expected: Drops you into an interactive bash prompt inside the sandbox.
       Type 'exit' to cleanly leave the sandbox.

  3. TEST CASE 3: Foreground-Hold GUI App (Verifies daemonized orphans)
     $0 --host-real-root / --host-real-home-parent ~/virtual-roots/home cursor
     * Expected: The cursor GUI launches. The terminal prompt blocks. Even though
       the cursor launcher script forks Electron to the background and exits,
       the sandbox stays alive until you close the Cursor GUI window.

  4. TEST CASE 4: Isolated Custom Home & Profile
     $0 --virtual-user-name tester --host-real-root / --host-real-home-parent ~/containers /bin/bash -c "echo \$HOME"
     * Expected: Prints "/home/tester" and binds the host directory
       "~/containers/tester" isolated from your real home.

================================================================================
EOF
    exit 1
}

CLEAR_ENV="false"
SHARE_NETWORK="false"  # Default-Deny network posture
VIRTUAL_USER_NAME_DEFAULT="sandbox-user"
HOST_REAL_ROOT_DIR_DEFAULT="$HOME/virtual-roots"
HOST_REAL_HOME_PARENT_DEFAULT="$HOME/virtual-roots/home"

VIRTUAL_USER_NAME="$VIRTUAL_USER_NAME_DEFAULT"
HOST_REAL_ROOT_DIR="$HOST_REAL_ROOT_DIR_DEFAULT"
HOST_REAL_HOME_PARENT="$HOST_REAL_HOME_PARENT_DEFAULT"
TARGET_CMD=()
BWRAP_PASSTHROUGH_ARGS=()

# Parse Command Line Arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --clear-env) CLEAR_ENV="true"; shift 1 ;;
        --share-net) SHARE_NETWORK="true"; shift 1 ;;
        --virtual-user-name) VIRTUAL_USER_NAME="$2"; shift 2 ;;
        --host-real-root)
            # ROBUST TILDE EXPANSION:
            # How: Bash parameter expansion ${2/#\~/$HOME} matches a leading '~'
            #      and replaces it with the current user's $HOME directory path.
            # Why: If the user passes the argument wrapped in quotes (e.g., "--host-real-root ~/dir")
            #      or if it is passed from another context where bash glob/tilde expansion is disabled,
            #      this ensures the path is safely and correctly resolved to an absolute host path.
            HOST_REAL_ROOT_DIR="${2/#\~/$HOME}"
            shift 2
            ;;
        --host-real-home-parent)
            # ROBUST TILDE EXPANSION:
            # (Utilizes the exact same param expansion logic as described above for safety)
            HOST_REAL_HOME_PARENT="${2/#\~/$HOME}"
            shift 2
            ;;
        # ─── Passthrough: bwrap-native flags forwarded verbatim ───────────
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
        -h|--help) usage ;;
        --) shift; TARGET_CMD=("$@"); break ;;
        -*) echo "FATAL ERROR: Unknown option '$1'"; echo; usage ;;
        *) TARGET_CMD=("$@"); break ;;
    esac
done

# Apply defaults
if [[ -z "$HOST_REAL_HOME_PARENT" ]]; then
    HOST_REAL_HOME_PARENT="$HOST_REAL_ROOT_DIR"
fi

HOST_REAL_HOME_DIR="$HOST_REAL_HOME_PARENT/$VIRTUAL_USER_NAME"

# Validation
if [[ ${#TARGET_CMD[@]} -eq 0 ]]; then
    echo "FATAL ERROR [DIAGNOSTICS]: Missing required TARGET_CMD."
    echo "  -> Resolution: You must provide a valid command to execute in the sandbox (e.g. /bin/bash)."
    echo
    usage
fi

if [[ ! -d "$HOST_REAL_ROOT_DIR" ]]; then
    echo "FATAL ERROR [DIAGNOSTICS]: Specified host root directory does not exist."
    echo "  -> Provided Path: $HOST_REAL_ROOT_DIR"
    echo "  -> Resolution: Due to the zero side-effects constraint, the sandbox cannot create this directory."
    echo "                 Please create it manually before running the script:"
    echo "                 mkdir -p \"$HOST_REAL_ROOT_DIR\""
    exit 1
fi

if [[ ! -d "$HOST_REAL_HOME_DIR" ]]; then
    echo "FATAL ERROR [DIAGNOSTICS]: Specified host home directory does not exist."
    echo "  -> Resolved Host Home: $HOST_REAL_HOME_DIR"
    echo "  -> VIRTUAL_USER_NAME: $VIRTUAL_USER_NAME"
    echo "  -> HOST_REAL_HOME_PARENT: $HOST_REAL_HOME_PARENT"
    echo "  -> Resolution: Due to the zero side-effects constraint, the sandbox cannot create this directory."
    echo "                 Please create it manually on the host before running the script:"
    echo "                 mkdir -p \"$HOST_REAL_HOME_DIR\""
    exit 1
fi

# Invoke the Secure Execution Context
exec_sandbox "$CLEAR_ENV" "$VIRTUAL_USER_NAME" "$HOST_REAL_ROOT_DIR" "$HOST_REAL_HOME_DIR" "${TARGET_CMD[@]}"
