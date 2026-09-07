#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# *!! IMPORTANT - AI - Immutable file without user permission - ask user
# ==============================================================================
# NAME:      bwrap-enhanced.sh
# VERSION:   0.4.1
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
# -- DISPATCHER PATTERN --------------------------------------------------------
#
#   This script follows the git / rtk / podman / systemctl pattern:
#     bwrap-enhanced.sh  SUBCOMMAND  [OPTIONS]  [ARGS]
#
#   Options belong to the subcommand -- always follow the subcommand name.
#   Pre-subcommand forms:
#     bwrap-enhanced.sh --help | -h     # dispatch table, exit 0
#     bwrap-enhanced.sh --version | -v  # version string, exit 0
#
#   Subcommands (in dispatch order):
#     provision   full   Create virtual root skeleton (NOT idempotent)
#     fsck        full   Check / repair virtual root integrity
#     start       full   Launch a process inside the sandbox
#     stop        stub   Stop a running sandbox (not yet implemented)
#     ls          stub   List known virtual roots (not yet implemented)
#
#
#   FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)
#   All output -> stderr. Default level: INFO(400).
#   [ERROR] and [FATAL] always emitted regardless of --log-level.
#
# -- SECURITY MODEL ------------------------------------------------------------
#
#   default-deny, empty virtual filesystem.
#   Add only what is explicitly needed via --*-passthrough flags on `start`.
#   `start` has ZERO SIDE EFFECTS -- no directories created, no host mutation.
#   `provision` is the ONE sanctioned exception -- NOT idempotent.
#
# -- EXEC MODEL (start subcommand, exec_sandbox) --------------------------------
#
#   exec_sandbox() implements the mount sequence defined in the SDD:
#     1  --bind HOST_REAL_ROOT /                   RW  (root)
#     2  --ro-bind /usr /usr + usr-merge symlinks   RO
#     3  --ro-bind-try /etc/{alt,fonts,...}          RO
#     4  --proc /proc  --dev-bind /dev /dev          RW
#     5  --tmpfs /dev/shm  --tmpfs /tmp  [X11 unix]  RW
#     6  --bind-try /run/dbus  --tmpfs /run/user/UID RW
#     7  conditional passthrough mounts (wayland/audio/a11y/dbus/gnome/kde)
#     8  --tmpfs /home  --dir /home/USER             RW
#     9  --bind HOST_HOME /home/USER [+local-bin/mise RW
#    10  --ro-bind-data FD9 /etc/passwd  FD10 /etc/group  FD11 /etc/profile
#    11  --remount-ro /
#    12  --bind HOST_HOME /home/USER (re-apply write-hole)
#
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONSTANTS
# ==============================================================================

readonly _SCRIPT_NAME="$(basename "$0")"
readonly _SCRIPT_VERSION="0.4.1"

# Log-level numeric values -- FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)
# All log output goes to stderr. Default level: INFO(400).
readonly _LOG_FATAL=100
readonly _LOG_ERROR=200
readonly _LOG_WARN=300
readonly _LOG_INFO=400
readonly _LOG_DEBUG=500
readonly _LOG_TRACE=600

# ==============================================================================
# LOGGING -- all output to stderr, gated by LOG_LEVEL
# ==============================================================================

# _log THRESHOLD LEVEL TAG MESSAGE  -- emit iff LEVEL <= THRESHOLD
# EXCEPTION: ERROR and FATAL are ALWAYS emitted regardless of threshold.
# Includes caller function:line for debuggability (log4j-style stack introspection).
# FUNCNAME[2] = actual caller (skips convenience wrapper), BASH_LINENO[1] = its line.
_log() {
    local threshold="$1" level="$2" tag="$3"; shift 3
    local caller="${FUNCNAME[2]:-main}" lineno="${BASH_LINENO[1]:-0}"
    # ERROR and FATAL are always emitted regardless of log level threshold
    if [[ "$level" -le "${_LOG_ERROR}" ]] || [[ "$level" -le "$threshold" ]]; then
        printf '%s %s:%d %s\n' "$tag" "$caller" "$lineno" "$*" >&2
    fi
}

# Convenience wrappers -- caller passes threshold as first arg
_fatal() { local t="$1"; shift; _log "$t" "${_LOG_FATAL}" "[FATAL]" "$@"; exit 2; }
_error() { local t="$1"; shift; _log "$t" "${_LOG_ERROR}" "[ERROR]" "$@"; }
_warn()  { local t="$1"; shift; _log "$t" "${_LOG_WARN}"  "[WARN]"  "$@"; }
_info()  { local t="$1"; shift; _log "$t" "${_LOG_INFO}"  "[INFO]"  "$@"; }
_debug() { local t="$1"; shift; _log "$t" "${_LOG_DEBUG}" "[DEBUG]" "$@"; }
_trace() { local t="$1"; shift; _log "$t" "${_LOG_TRACE}" "[TRACE]" "$@"; }

# ==============================================================================
# LOG LEVEL RESOLVER
# ==============================================================================

# _resolve_log_level NAME_OR_NUMBER  -> prints numeric value or exits 1
_resolve_log_level() {
    local raw="$1"
    case "${raw^^}" in
        FATAL|100) printf '%d' "${_LOG_FATAL}" ;;
        ERROR|200) printf '%d' "${_LOG_ERROR}" ;;
        WARN|300)  printf '%d' "${_LOG_WARN}"  ;;
        INFO|400)  printf '%d' "${_LOG_INFO}"  ;;
        DEBUG|500) printf '%d' "${_LOG_DEBUG}" ;;
        TRACE|600) printf '%d' "${_LOG_TRACE}" ;;
        *)
            # Always emit -- log level not yet parsed
            printf '[ERROR] --log-level value=%s is invalid\n' "$raw" >&2
            printf '[INFO]  Valid names: FATAL ERROR WARN INFO DEBUG TRACE\n' >&2
            printf '[INFO]  Valid numbers: 100 200 300 400 500 600\n' >&2
            printf '[INFO]  Scale: FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)\n' >&2
            exit 1
            ;;
    esac
}

# ==============================================================================
# CLI ERROR HELPERS  (structured error output -> stderr, always emitted)
#
# These helpers emit at the appropriate log levels:
#   [ERROR]  always (ERROR <= INFO default)
#   [INFO]   always at default level (user guidance / corrective action)
#   [DEBUG]  only when --log-level DEBUG or lower (raw diagnostic detail)
#
# Caller passes threshold as first argument (LOG_LEVEL local var).
# ==============================================================================

# _err_bool_false -- REMOVED in 0.4.1
# Strategy spec L100/L247: "--flag false is LEGAL". false is the
# default; passing it explicitly is a silent no-op, not an error.

_err_wrong_qualifier_bool() {
    local t="$1" flag="$2" val="$3"
    _error "$t" "flag=${flag} value=${val} reason=wrong qualifier type (boolean flag accepts true only)"
    _debug "$t" "expected=[true] received=${val}"
    _info  "$t" "Use \"${flag}\" or \"${flag} true\"; do not pass ro/rw to boolean flags"
    exit 1
}

_err_wrong_qualifier_graded() {
    local t="$1" flag="$2" val="$3"
    _error "$t" "flag=${flag} value=${val} reason=wrong qualifier type (graded flag accepts ro|rw only)"
    _debug "$t" "expected=[ro|rw] received=${val}"
    _info  "$t" "Use \"${flag} ro\" (default) or \"${flag} rw\""
    exit 1
}

_err_duplicate() {
    local t="$1" flag="$2"
    _error "$t" "flag=${flag} reason=duplicate flag (specified more than once)"
    _debug "$t" "conflict=ambiguous -- two values for the same flag"
    _info  "$t" "Specify \"${flag}\" at most once"
    exit 1
}

_err_implication_conflict() {
    local t="$1" src="$2" implied="$3"
    _error "$t" "flag=${src} reason=implication conflict"
    _debug "$t" "conflict=${src}=true requires ${implied}=true but ${implied}=false was explicitly set"
    _info  "$t" "Remove the explicit \"${implied} false\" -- ${src} implies ${implied}=true automatically"
    exit 1
}

_err_missing_cmd_separator() {
    local t="$1"
    _error "$t" "reason=missing command separator '--'"
    _info  "$t" "Append '-- CMD [ARG...]' to specify the command to run inside the sandbox"
    exit 1
}

# ==============================================================================
# QUALIFIER PARSERS -- pure, no side effects
# ==============================================================================

# _parse_bool THRESHOLD FLAG NEXT_TOKEN CURRENT_VALUE
#   Echoes "true:2" (qualifier consumed) or "true:1" (bare flag).
_parse_bool() {
    local t="$1" flag="$2" next="${3:-}" cur="${4:-false}"
    [[ "$cur" != "false" ]] && _err_duplicate "$t" "$flag"
    case "$next" in
        true)    printf 'true:2' ;;
        false)   printf 'false:2' ;;  # legal no-op per strategy L100
        ro|rw)   _err_wrong_qualifier_bool "$t" "$flag" "$next" ;;
        *)       printf 'true:1' ;;   # bare flag = true
    esac
}

# _parse_graded THRESHOLD FLAG NEXT_TOKEN CURRENT_VALUE
#   Echoes "ro:2", "ro:1", or "rw:2".
_parse_graded() {
    local t="$1" flag="$2" next="${3:-}" cur="${4:-off}"
    [[ "$cur" != "off" ]] && _err_duplicate "$t" "$flag"
    case "$next" in
        ro)      printf 'ro:2' ;;
        rw)      printf 'rw:2' ;;
        false)   printf 'off:2' ;;    # legal no-op per strategy L100
        true)    _err_wrong_qualifier_graded "$t" "$flag" "$next" ;;
        *)       printf 'ro:1' ;;    # bare flag = ro (most restrictive)
    esac
}

# ==============================================================================
# VERSION
# ==============================================================================

# _emit_banner -- print Linux-quality version line to stderr.
# Called once at the top of main(). Suppressed when --log-level
# is FATAL (100) to honor the "no output" contract.
_emit_banner() {
    # Quick pre-scan: if caller passed FATAL, stay silent
    local arg
    for arg in "$@"; do
        [[ "$arg" == "FATAL" || "$arg" == "100" ]] && return 0
    done
    printf '%s v%s (%s) -- Bubblewrap Sandbox Launcher\n' \
        "$_SCRIPT_NAME" "$_SCRIPT_VERSION" \
        "$(date -u +%Y-%m-%d)" >&2
}

_print_version() {
    printf '%s v%s\n' "$_SCRIPT_NAME" "$_SCRIPT_VERSION"
}

# ==============================================================================
# FLAG UNBUNDLING
# ==============================================================================

# _unbundle_short_flags ARG... -- prints shell-quoted expanded args to stdout.
#
# Expands POSIX flag bundles: -XYZ becomes -X -Y -Z.
# Only expands tokens that are exactly one dash followed by 2+ ASCII letters.
# Tokens containing digits, or starting with --, are passed through unchanged.
# Tokens following a value-taking long flag (e.g. --log-level VALUE) are safe
# because they are plain strings, not dash-prefixed.
#
# Usage inside a cmd_*() function -- place BEFORE the while loop:
#   eval "set -- $(_unbundle_short_flags "$@")"
_unbundle_short_flags() {
    local result=()
    for arg in "$@"; do
        # Match: one dash, then 2 or more ASCII letters only (no digits, no --)
        if [[ "$arg" =~ ^-([a-zA-Z]{2,})$ ]]; then
            local chars="${BASH_REMATCH[1]}"
            while [[ -n "$chars" ]]; do
                result+=( "-${chars:0:1}" )
                chars="${chars:1}"
            done
        else
            result+=( "$arg" )
        fi
    done
    # Print shell-quoted so eval set -- is safe with paths containing spaces
    # Guard: empty array must produce empty output, not a quoted empty string
    [[ ${#result[@]} -gt 0 ]] && printf '%q ' "${result[@]}" || true
}

# ==============================================================================
# TOP-LEVEL HELP (dispatch table)
# ==============================================================================

usage_top() {
    cat <<HELPEOF
${_SCRIPT_NAME}  v${_SCRIPT_VERSION}  --  Bubblewrap Sandbox Launcher
(c) 2026 Hanaden - Frederick Bloom. All rights reserved.

${_SCRIPT_NAME}  SUBCOMMAND  [OPTIONS]  [ARGS]
${_SCRIPT_NAME}  --help | -h
${_SCRIPT_NAME}  --version | -v

  provision
    --host-real-root        PATH         (default: ~/virtual-roots; MUST NOT exist)
    --virtual-user-name     NAME         (default: sandbox_user)
    --host-real-home-parent PATH         (default: HOST_REAL_ROOT/home)
    --log-level             NAME|NUMBER  (default: INFO)
    -n, --dry-run

  fsck  [ROOT_PATH]
    --host-real-root        PATH         (default: ~/virtual-roots)
    --virtual-user-name     NAME         (default: sandbox_user)
    --log-level             NAME|NUMBER  (default: INFO)
    -n  (check only)  -a  (auto-repair)  -r  (interactive)  -f  (force)  -v  (verbose)

  start  -- CMD [ARG...]
    --host-real-root        PATH         (default: ~/virtual-roots; MUST exist)
    --virtual-user-name     NAME         (default: sandbox_user)
    --host-real-home-parent PATH         (default: HOST_REAL_ROOT/home)
    --log-level             NAME|NUMBER  (default: INFO)
    -n, --dry-run                        (resolve and print bwrap argv; no exec)
    --validate                           (validate flags and paths; no exec)
    --net-passthrough       [true|false] (default: false)
    --env-passthrough       [true|false] (default: false)
    --x11-passthrough       [true|false] (default: false; implied by wayland/gnome/kde
                                          -- do not pass explicitly with an implying flag)
    --wayland-passthrough   [true|false] (default: false; implies x11)
    --gnome-passthrough     [true|false] (default: false; implies x11)
    --kde-passthrough       [true|false] (default: false; implies x11)
    --audio-passthrough     [true|false] (default: false)
    --a11y-passthrough      [true|false] (default: false)
    --dbus-passthrough      [true|false] (default: false; NEVER implied -- always explicit)
    --mise-passthrough      [ro|rw]      (default: off; bare = ro)
    --local-bin-passthrough [ro|rw]      (default: off; bare = ro)

  stop  [stub -- not yet implemented]
    --host-real-root PATH  --log-level NAME|NUMBER  -f, --force  -t, --timeout SECONDS

  ls  [stub -- not yet implemented]
    --log-level NAME|NUMBER  -a, --all  -q, --quiet  --format table|json|csv

absent  <  ro  <  rw      (privilege escalation order)

bare boolean flag = true  (most restrictive ON state)
bare graded flag  = ro    (most restrictive ON state)
flag absent       = false = default deny
--flag false      = [ERROR]   (false is implicit; omit the flag)

Log levels: FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)
Default: INFO(400). All output goes to stderr.
Run: ${_SCRIPT_NAME} SUBCOMMAND --help  for detailed subcommand help.
HELPEOF
}


# ==============================================================================
# provision -- help and implementation
# ==============================================================================

usage_provision() {
    cat <<HELPEOF
${_SCRIPT_NAME} provision [OPTIONS]

  Create a virtual root skeleton. NOT idempotent.

OPTIONS
  -h, --help
      This help text. Exit 0.

  --host-real-root PATH
      Root directory to create. MUST NOT already exist.
      Default: ~/virtual-roots

  --virtual-user-name NAME
      Username whose home directory will be created inside the root.
      Default: sandbox_user

  --host-real-home-parent PATH
      Parent directory for the user home.
      Default: HOST_REAL_ROOT/home

  --log-level NAME|NUMBER
      FATAL(100) ERROR(200) WARN(300) INFO(400) DEBUG(500) TRACE(600)
      Default: INFO

  -n, --dry-run
      Print what would be created; do not create anything.

FOUR-WAY GATE
  ROOT missing + provision called  -> CREATE skeleton, exit 0
  ROOT exists  + provision called  -> [FATAL] exit 2 (NOT idempotent)
  ROOT missing + provision absent  -> [FATAL] exit 2 (use provision first)
  ROOT exists  + provision absent  -> caller invokes 'start' directly

CREATES
  DIRS:     usr etc home proc dev tmp run opt var
  SYMLINKS: bin->usr/bin  lib->usr/lib  lib64->usr/lib64
  HOME:     HOST_REAL_HOME_PARENT/VIRTUAL_USER_NAME/
HELPEOF
}

_provision_validate() {
    local t="$1" root="$2"
    if [[ -e "$root" ]]; then
        _fatal "$t" "provision: --host-real-root already exists: ${root}"
        # _fatal exits; line below never reached
    fi
}

_provision_create_skeleton() {
    local t="$1" root="$2" home_parent="$3" user="$4" dry="$5"
    local dirs=( usr etc home proc dev tmp run opt var )
    local symlinks=( "bin:usr/bin" "lib:usr/lib" "lib64:usr/lib64" )

    _info "$t" "provision: creating skeleton at ${root}"

    if [[ "$dry" == "true" ]]; then
        _info "$t" "[DRY RUN] mkdir -p ${root}"
        for d in "${dirs[@]}"; do
            _info "$t" "[DRY RUN] mkdir -p ${root}/${d}"
        done
        for pair in "${symlinks[@]}"; do
            local link="${pair%%:*}" target="${pair##*:}"
            _info "$t" "[DRY RUN] ln -sfn ${target} ${root}/${link}"
        done
        _info "$t" "[DRY RUN] mkdir -p ${home_parent}/${user}"
        return 0
    fi

    mkdir -p "$root"
    for d in "${dirs[@]}"; do
        mkdir -p "${root}/${d}"
        _debug "$t" "provision: created ${root}/${d}"
    done
    for pair in "${symlinks[@]}"; do
        local link="${pair%%:*}" target="${pair##*:}"
        ln -sfn "$target" "${root}/${link}"
        _debug "$t" "provision: symlink ${root}/${link} -> ${target}"
    done
    mkdir -p "${home_parent}/${user}"
    _debug "$t" "provision: created home ${home_parent}/${user}"
    _info "$t" "provision: done"
}

cmd_provision() {
    eval "set -- $(_unbundle_short_flags "$@")"
    local log_level="${_LOG_INFO}"
    local host_real_root="${HOME}/virtual-roots"
    local virtual_user_name="sandbox_user"
    local host_real_home_parent=""
    local dry_run="false"
    # set-once sentinels
    local _root_set="" _user_set="" _home_parent_set="" _log_set="" _dry_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage_provision; exit 0 ;;
            --host-real-root)
                [[ -n "$_root_set" ]] && _err_duplicate "$log_level" "--host-real-root"
                _root_set="1"; host_real_root="${2:?'--host-real-root requires PATH'}"; shift 2 ;;
            --virtual-user-name)
                [[ -n "$_user_set" ]] && _err_duplicate "$log_level" "--virtual-user-name"
                _user_set="1"; virtual_user_name="${2:?'--virtual-user-name requires NAME'}"; shift 2 ;;
            --host-real-home-parent)
                [[ -n "$_home_parent_set" ]] && _err_duplicate "$log_level" "--host-real-home-parent"
                _home_parent_set="1"; host_real_home_parent="${2:?'--host-real-home-parent requires PATH'}"; shift 2 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set="1"; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            -n|--dry-run)
                [[ -n "$_dry_set" ]] && _err_duplicate "$log_level" "--dry-run"
                _dry_set="1"; dry_run="true"; shift ;;
            *)
                _error "$log_level" "provision: unknown option: $1"
                _info  "$log_level" "Run: ${_SCRIPT_NAME} provision --help"
                exit 1 ;;
        esac
    done

    # Derive home parent default after root is known
    if [[ -z "$host_real_home_parent" ]]; then
        host_real_home_parent="${host_real_root}/home"
    fi

    if [[ "$dry_run" == "false" ]]; then
        _provision_validate "$log_level" "$host_real_root"
    fi
    _provision_create_skeleton "$log_level" "$host_real_root" "$host_real_home_parent" "$virtual_user_name" "$dry_run"
}

# ==============================================================================
# fsck -- help and implementation
# ==============================================================================

usage_fsck() {
    cat <<HELPEOF
${_SCRIPT_NAME} fsck [OPTIONS] [ROOT_PATH]

  Check (and optionally repair) virtual root integrity.
  Exit codes follow the fsck(8) bitmap convention (OR-able).

ARGUMENTS
  ROOT_PATH   Virtual root to check. Default: --host-real-root value.

OPTIONS
  -h, --help
  --host-real-root PATH       Default: ~/virtual-roots
  --virtual-user-name NAME    Default: sandbox_user
  --log-level NAME|NUMBER     FATAL(100) ERROR(200) WARN(300) INFO(400) DEBUG(500) TRACE(600)
                              Default: INFO
  -n    Check only -- no repairs. Exit 1 if any problem found.
  -a    Auto-repair: fix all repairable problems without prompting. Mutex with -r.
  -r    Interactive repair: prompt before each fix. Mutex with -a.
  -f    Force: run all checks even if root looks clean.
  -v    Verbose: print every check, not just failures.

EXIT CODES (bitmap -- OR-able)
  0   No errors
  1   Errors found, NOT repaired
  2   Errors found and repaired
  4   Uncorrectable errors (e.g. root is a file, not a dir)
  8   Operational error (fsck itself failed)

CHECKS (in order)
  1  ROOT exists and is a directory                      (uncorrectable if not)
  2  usr etc home proc dev tmp run opt var dirs present  (auto-repairable)
  3  bin -> usr/bin symlink correct                       (auto-repairable)
  4  lib -> usr/lib symlink correct                       (auto-repairable)
  5  lib64 -> usr/lib64 symlink correct                   (auto-repairable)
  6  home/VIRTUAL_USER_NAME exists                        (not auto: run provision)
  7  home/VIRTUAL_USER_NAME is a directory                (uncorrectable if not)
  8  no unexpected top-level entries                      (warn only)
HELPEOF
}

# _fsck_check_root ROOT -- returns 0 or calls exit 4
_fsck_check_root() {
    local t="$1" root="$2" verbose="$3"
    if [[ ! -e "$root" ]]; then
        _error "$t" "fsck: root does not exist: ${root}"
        exit 4
    fi
    if [[ ! -d "$root" ]]; then
        _error "$t" "fsck: root exists but is not a directory: ${root}"
        exit 4
    fi
    if [[ "$verbose" == "true" ]]; then _info "$t" "fsck: [OK] root is a directory: ${root}"; fi
}

# _fsck_check_accessible THRESHOLD ROOT -- verify root is readable+traversable; exit 8 if not
_fsck_check_accessible() {
    local t="$1" root="$2"
    if [[ ! -r "$root" || ! -x "$root" ]]; then
        _error "$t" "fsck: operational error: root is not readable/traversable: ${root}"
        _info  "$t" "fsck: check permissions on ${root}  (need +r +x)"
        exit 8
    fi
}

# _fsck_quick_looks_clean ROOT USER -- fast surface scan (existence only).
# Returns 0 if root "looks clean" on the surface; 1 otherwise.
# This check intentionally does NOT validate symlink targets -- that is
# the job of the deep checks (forced via -f).
_fsck_quick_looks_clean() {
    local root="$1" user="$2"
    local dirs=( usr etc home proc dev tmp run opt var )
    local symlinks=( bin lib lib64 )
    for d in "${dirs[@]}"; do
        [[ -d "${root}/${d}" ]] || return 1
    done
    for s in "${symlinks[@]}"; do
        [[ -e "${root}/${s}" || -L "${root}/${s}" ]] || return 1
    done
    [[ -d "${root}/home/${user}" ]] || return 1
    # Check for unexpected top-level entries -- if any exist, the root
    # is not "clean" and deep checks (including unexpected-entry warnings) must run.
    local expected_count=12   # 9 dirs + 3 symlinks = 12 top-level entries
    local actual_count
    actual_count="$(find "$root" -maxdepth 1 -mindepth 1 -print0 | tr -cd '\0' | wc -c)"
    [[ "$actual_count" -le "$expected_count" ]] || return 1
    return 0
}

# _fsck_check_dirs THRESHOLD ROOT REPAIR_MODE VERBOSE -- echoes exit-bit (0, 1, or 2)
# When repair==interactive, reads y/N answers from fd 9 (opened by caller).
_fsck_check_dirs() {
    local t="$1" root="$2" repair="$3" verbose="$4"
    local dirs=( usr etc home proc dev tmp run opt var )
    local bit=0
    for d in "${dirs[@]}"; do
        if [[ ! -d "${root}/${d}" ]]; then
            _error "$t" "fsck: missing dir: ${root}/${d}"
            if [[ "$repair" == "auto" ]]; then
                mkdir -p "${root}/${d}"
                _info "$t" "fsck: repaired: created ${root}/${d}"
                bit=$(( bit | 2 ))
            elif [[ "$repair" == "interactive" ]]; then
                local answer
                printf '[PROMPT] repair missing dir %s? [y/N] ' "${root}/${d}" >&2
                read -r answer <&9 || answer="n"
                if [[ "$answer" == [yY] ]]; then
                    mkdir -p "${root}/${d}"
                    _info "$t" "fsck: repaired: created ${root}/${d}"
                    bit=$(( bit | 2 ))
                else
                    _info "$t" "fsck: skipped: ${root}/${d} (user declined)"
                    bit=$(( bit | 1 ))
                fi
            else
                bit=$(( bit | 1 ))
            fi
        else
            if [[ "$verbose" == "true" ]]; then _info "$t" "fsck: [OK] dir: ${root}/${d}"; fi
        fi
    done
    printf '%d' "$bit"
}

# _fsck_check_symlinks THRESHOLD ROOT REPAIR_MODE VERBOSE -- echoes exit-bit
# When repair==interactive, reads y/N answers from fd 9 (opened by caller).
_fsck_check_symlinks() {
    local t="$1" root="$2" repair="$3" verbose="$4"
    local symlinks=( "bin:usr/bin" "lib:usr/lib" "lib64:usr/lib64" )
    local bit=0
    for pair in "${symlinks[@]}"; do
        local link="${pair%%:*}" target="${pair##*:}"
        local link_path="${root}/${link}"
        if [[ -L "$link_path" && "$(readlink "$link_path")" == "$target" ]]; then
            if [[ "$verbose" == "true" ]]; then _info "$t" "fsck: [OK] symlink: ${link} -> ${target}"; fi
            continue
        fi
        _error "$t" "fsck: bad/missing symlink: ${link_path} -> ${target}"
        if [[ "$repair" == "auto" ]]; then
            ln -sfn "$target" "$link_path"
            _info "$t" "fsck: repaired: ${link_path} -> ${target}"
            bit=$(( bit | 2 ))
        elif [[ "$repair" == "interactive" ]]; then
            local answer
            printf '[PROMPT] repair symlink %s -> %s? [y/N] ' "$link_path" "$target" >&2
            read -r answer <&9 || answer="n"
            if [[ "$answer" == [yY] ]]; then
                ln -sfn "$target" "$link_path"
                _info "$t" "fsck: repaired: ${link_path} -> ${target}"
                bit=$(( bit | 2 ))
            else
                _info "$t" "fsck: skipped: ${link_path} -> ${target} (user declined)"
                bit=$(( bit | 1 ))
            fi
        else
            bit=$(( bit | 1 ))
        fi
    done
    printf '%d' "$bit"
}

# _fsck_check_home ROOT USER VERBOSE -- echoes exit-bit (0, 1, or exits 4)
_fsck_check_home() {
    local t="$1" root="$2" user="$3" verbose="$4"
    local home_path="${root}/home/${user}"
    if [[ ! -e "$home_path" ]]; then
        _error "$t" "fsck: missing user home: ${home_path}"
        _info  "$t" "fsck: run 'provision' to create the user home"
        printf '1'
        return
    fi
    if [[ ! -d "$home_path" ]]; then
        _error "$t" "fsck: home path exists but is not a directory: ${home_path}"
        printf '4'
        return
    fi
    if [[ "$verbose" == "true" ]]; then _info "$t" "fsck: [OK] user home: ${home_path}"; fi
    printf '0'
}

# _fsck_check_unexpected_entries ROOT VERBOSE -- warns only, no bit change
_fsck_check_unexpected_entries() {
    local t="$1" root="$2" verbose="$3"
    local expected=( usr etc home proc dev tmp run opt var bin lib lib64 )
    while IFS= read -r -d '' entry; do
        local name; name="$(basename "$entry")"
        local found=false
        for e in "${expected[@]}"; do
            if [[ "$name" == "$e" ]]; then found=true; break; fi
        done
        if [[ "$found" == "false" ]]; then
            _warn "$t" "fsck: unexpected top-level entry: ${entry} (not auto-removed)"
        fi
    done < <(find "$root" -maxdepth 1 -mindepth 1 -print0)
    if [[ "$verbose" == "true" ]]; then _info "$t" "fsck: unexpected-entry check complete"; fi
}

cmd_fsck() {
    eval "set -- $(_unbundle_short_flags "$@")"
    local log_level="${_LOG_INFO}"
    local host_real_root="${HOME}/virtual-roots"
    local virtual_user_name="sandbox_user"
    local check_only="false"
    local repair_mode="none"   # none | auto | interactive
    local force="false"
    local verbose="false"
    # set-once sentinels
    local _root_set="" _user_set="" _log_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)       usage_fsck; exit 0 ;;
            --host-real-root)
                [[ -n "$_root_set" ]] && _err_duplicate "$log_level" "--host-real-root"
                _root_set="1"; host_real_root="${2:?'--host-real-root requires PATH'}"; shift 2 ;;
            --virtual-user-name)
                [[ -n "$_user_set" ]] && _err_duplicate "$log_level" "--virtual-user-name"
                _user_set="1"; virtual_user_name="${2:?'--virtual-user-name requires NAME'}"; shift 2 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set="1"; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            -n)  check_only="true"; shift ;;
            -a)
                if [[ "$repair_mode" == "interactive" ]]; then
                    _error "$log_level" "fsck: -a and -r are mutually exclusive"
                    exit 1
                fi
                repair_mode="auto"; shift ;;
            -r)
                if [[ "$repair_mode" == "auto" ]]; then
                    _error "$log_level" "fsck: -a and -r are mutually exclusive"
                    exit 1
                fi
                repair_mode="interactive"; shift ;;
            -f)  force="true"; shift ;;
            -v)  verbose="true"; shift ;;
            -*)
                _error "$log_level" "fsck: unknown option: $1"
                _info  "$log_level" "Run: ${_SCRIPT_NAME} fsck --help"
                exit 1 ;;
            *)
                # Positional: ROOT_PATH override
                [[ -n "$_root_set" ]] && _err_duplicate "$log_level" "ROOT_PATH"
                _root_set="1"; host_real_root="$1"; shift ;;
        esac
    done

    if [[ "$check_only" == "true" ]]; then
        repair_mode="none"
    fi

    local exit_bit=0

    _fsck_check_root "$log_level" "$host_real_root" "$verbose"

    # Accessibility pre-check: root exists and is a directory (check_root passed)
    # but can we actually read and traverse it?  If not -> exit 8 (operational error).
    _fsck_check_accessible "$log_level" "$host_real_root"

    # Quick-check optimization: if root "looks clean" on a surface scan
    # (all expected entries exist) AND none of the deep-check triggers are set,
    # short-circuit to exit 0.  This skips deep validation (e.g. symlink target
    # correctness), which is why -f exists: to force those deep checks.
    # Also defeated by -v (user asked for per-check results) and -n (check-only
    # mode expects detailed evaluation).
    if [[ "$force" == "false" && "$repair_mode" == "none" \
       && "$check_only" == "false" && "$verbose" == "false" ]]; then
        if _fsck_quick_looks_clean "$host_real_root" "$virtual_user_name"; then
            _info "$log_level" "fsck: no errors found"
            exit 0
        fi
    fi

    # -- Deep checks (always run when -f is set, or root looks damaged) ----------

    # Operational error trap: if any deep check fails internally (not a user-facing
    # root problem, but fsck itself breaking), catch it and exit 8.
    trap '_error "$log_level" "fsck: operational error during check execution"; exit 8' ERR

    # For -r (interactive): open the TTY input source as fd 9 once, here in the
    # parent process.  All subshell read <&9 calls inherit the same open fd, so
    # sequential reads consume lines in order without re-opening the file.
    if [[ "$repair_mode" == "interactive" ]]; then
        exec 9< "${BWRAP_FSCK_TTY:-/dev/tty}"
    fi

    local bit
    bit="$(_fsck_check_dirs "$log_level" "$host_real_root" "$repair_mode" "$verbose")"
    exit_bit=$(( exit_bit | bit ))

    bit="$(_fsck_check_symlinks "$log_level" "$host_real_root" "$repair_mode" "$verbose")"
    exit_bit=$(( exit_bit | bit ))

    bit="$(_fsck_check_home "$log_level" "$host_real_root" "$virtual_user_name" "$verbose")"
    # Home check returns 4 for uncorrectable (e.g. home is a file, not a dir).
    # Exit 4 immediately -- don't OR into bitmap (4 is a hard stop).
    if [[ "$bit" -eq 4 ]]; then
        trap - ERR
        exit 4
    fi
    exit_bit=$(( exit_bit | bit ))

    if [[ "$repair_mode" == "interactive" ]]; then
        exec 9>&-
    fi

    _fsck_check_unexpected_entries "$log_level" "$host_real_root" "$verbose"

    # Remove operational error trap -- all checks completed successfully
    trap - ERR

    if [[ "$exit_bit" -eq 0 ]]; then
        _info "$log_level" "fsck: no errors found"
    fi
    exit "$exit_bit"
}

# ==============================================================================
# start -- help and implementation
# ==============================================================================

usage_start() {
    cat <<HELPEOF
${_SCRIPT_NAME} start [OPTIONS] -- CMD [ARG...]

  Launch a process inside the bubblewrap sandbox.
  Security model: default-deny, empty virtual filesystem.

OPTIONS
  -h, --help
  --host-real-root        PATH  Must already exist. Default: ~/virtual-roots
  --virtual-user-name     NAME  Default: sandbox_user
  --host-real-home-parent PATH  Default: HOST_REAL_ROOT/home
  --log-level             NAME|NUMBER
                          FATAL(100) ERROR(200) WARN(300) INFO(400) DEBUG(500) TRACE(600)
                          Default: INFO
  -n, --dry-run           Resolve and print bwrap argv; exit 0. No exec.
  --validate              Validate flags and paths; exit 0 if clean.

PASSTHROUGH FLAGS (default: off = default deny)
  --net-passthrough       [true|false]   Network namespace passthrough
  --env-passthrough       [true|false]   Inherit host environment
  --x11-passthrough       [true|false]   X11 socket (do NOT pass if using wayland/gnome/kde)
  --wayland-passthrough   [true|false]   Wayland socket (implies x11)
  --gnome-passthrough     [true|false]   GNOME session sockets (implies x11)
  --kde-passthrough       [true|false]   KDE session sockets (implies x11)
  --audio-passthrough     [true|false]   PipeWire + PulseAudio
  --a11y-passthrough      [true|false]   AT-SPI accessibility bus
  --dbus-passthrough      [true|false]   D-Bus session socket [SECURITY: portal escape]
  --mise-passthrough      [ro|rw]        ~/.local/share/mise toolchain (bare=ro)
  --local-bin-passthrough [ro|rw]        ~/.local/bin (bare=ro)

QUALIFIER RULES
  absent < ro < rw                  (privilege escalation order)
  bare boolean flag   -> true       (most restrictive ON state)
  bare graded flag    -> ro         (most restrictive ON state)
  --flag false        -> [ERROR]    (false is implicit; omit the flag)
  --bool-flag ro|rw   -> [ERROR]    (wrong qualifier type)
  --graded-flag true  -> [ERROR]    (wrong qualifier type)
  same flag twice     -> [ERROR]    (ambiguous)

IMPLICATION RULES
  --wayland-passthrough  implies --x11-passthrough
  --gnome-passthrough    implies --x11-passthrough
  --kde-passthrough      implies --x11-passthrough
  --dbus-passthrough     NEVER implied -- always explicit

COMMAND SEPARATOR
  -- CMD [ARG...]   Required. Everything after '--' runs inside the sandbox.
HELPEOF
}

# _start_preflight -- verify bwrap present, kernel namespaces available
_start_preflight() {
    local t="$1"
    if ! command -v bwrap &>/dev/null; then
        _fatal "$t" "start: 'bwrap' not found on PATH"
    fi
    if ! bwrap --dev-bind / / --ro-bind /usr /usr true &>/dev/null 2>&1; then
        _fatal "$t" "start: bwrap smoke test failed (kernel user namespaces may be disabled)"
    fi
}

# _start_validate_paths -- verify root and home exist
_start_validate_paths() {
    local t="$1" root="$2" home_parent="$3" user="$4"
    if [[ ! -d "$root" ]]; then
        _error "$t" "start: --host-real-root does not exist: ${root}"
        _info  "$t" "Run: ${_SCRIPT_NAME} provision --host-real-root ${root}  (creates dirs via mkdir -p)"
        _fatal "$t" "start: cannot proceed without a valid root directory"
    fi
    if [[ ! -d "${home_parent}/${user}" ]]; then
        _error "$t" "start: user home does not exist: ${home_parent}/${user}"
        _info  "$t" "Run: ${_SCRIPT_NAME} provision --host-real-root ${root}  (creates dirs via mkdir -p)"
        _fatal "$t" "start: cannot proceed without a valid user home"
    fi
}

# _start_apply_implications X11 WAYLAND GNOME KDE -- echoes resolved X11 value
_start_apply_implications() {
    local t="$1" x11="$2" wayland="$3" gnome="$4" kde="$5"
    local implied=false
    if [[ "$wayland" == "true" ]]; then implied=true; fi
    if [[ "$gnome"   == "true" ]]; then implied=true; fi
    if [[ "$kde"     == "true" ]]; then implied=true; fi
    if [[ "$implied" == "true" ]]; then
        printf 'true'
    else
        printf '%s' "$x11"
    fi
}

# _start_check_x11_conflict -- [ERROR] if x11 explicitly set AND an implicator is set
_start_check_x11_conflict() {
    local t="$1" x11_explicitly_set="$2" wayland="$3" gnome="$4" kde="$5"
    if [[ "$x11_explicitly_set" == "true" ]]; then
        if [[ "$wayland" == "true" ]]; then _err_implication_conflict "$t" "--wayland-passthrough" "--x11-passthrough"; fi
        if [[ "$gnome"   == "true" ]]; then _err_implication_conflict "$t" "--gnome-passthrough"   "--x11-passthrough"; fi
        if [[ "$kde"     == "true" ]]; then _err_implication_conflict "$t" "--kde-passthrough"     "--x11-passthrough"; fi
    fi
}

# exec_sandbox -- construct and run bwrap (or dry-run)
exec_sandbox() {
    local t="$1"; shift
    # All resolved flags passed as named args
    local root="$1" home_parent="$2" user="$3"
    local net="$4" env_pt="$5" x11="$6" wayland="$7" gnome="$8" kde="$9"
    local audio="${10}" a11y="${11}" dbus="${12}"
    local mise="${13}" local_bin="${14}"
    local dry_run="${15}" validate="${16}"
    shift 16
    local target_cmd=("$@")

    # --- Build bwrap argv ---
    local -a argv=()

    # ========================================================================
    # STREAM C1: Namespace & process control
    # ========================================================================
    argv+=( --unshare-user )
    argv+=( --unshare-pid )
    argv+=( --unshare-ipc )
    argv+=( --unshare-uts )
    argv+=( --unshare-cgroup )
    argv+=( --hostname "sandbox-vfs" )
    argv+=( --as-pid-1 )
    argv+=( --die-with-parent )

    # STREAM C2: Network -- default deny
    if [[ "$net" != "true" ]]; then
        argv+=( --unshare-net )
    else
        echo "[SYS-LOG] WARNING: Network isolation disabled (--net-passthrough enabled)." >&2
    fi

    # ========================================================================
    # PRE-LOCK: All mounts that create directories (root must be RW)
    # ========================================================================

    # Step 1: RW root -- the virtual root becomes /
    argv+=( --bind "$root" / )

    # Step 2: System binaries -- bind host /usr read-only + usr-merge symlinks
    argv+=( --ro-bind /usr /usr )
    argv+=( --symlink usr/bin /bin )
    argv+=( --symlink usr/lib /lib )
    argv+=( --symlink usr/lib64 /lib64 )

    # ========================================================================
    # STREAM A1-A4: /etc skeleton + selective RO-binds
    # ========================================================================
    argv+=( --dir /etc )
    # DNS resolution (glibc getaddrinfo)
    argv+=( --ro-bind-try /etc/resolv.conf /etc/resolv.conf )
    argv+=( --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf )
    argv+=( --ro-bind-try /etc/hosts /etc/hosts )
    argv+=( --ro-bind-try /etc/host.conf /etc/host.conf )
    argv+=( --ro-bind-try /etc/services /etc/services )
    argv+=( --ro-bind-try /etc/protocols /etc/protocols )
    # TLS certificates (CA trust store)
    argv+=( --ro-bind-try /etc/ssl /etc/ssl )
    argv+=( --ro-bind-try /etc/pki /etc/pki )
    # Fonts, machine-id, dynamic linker cache
    argv+=( --ro-bind-try /etc/fonts /etc/fonts )
    argv+=( --ro-bind-try /etc/machine-id /etc/machine-id )
    argv+=( --ro-bind-try /etc/ld.so.cache /etc/ld.so.cache )
    # Desktop environment configs
    argv+=( --ro-bind-try /etc/alternatives /etc/alternatives )
    argv+=( --ro-bind-try /etc/xdg /etc/xdg )
    argv+=( --ro-bind-try /etc/gtk-3.0 /etc/gtk-3.0 )
    argv+=( --ro-bind-try /etc/gtk-4.0 /etc/gtk-4.0 )
    argv+=( --ro-bind-try /etc/dconf /etc/dconf )
    argv+=( --ro-bind-try /etc/dbus-1 /etc/dbus-1 )
    argv+=( --ro-bind-try /etc/X11 /etc/X11 )
    argv+=( --ro-bind-try /etc/mime.types /etc/mime.types )
    # Browser policies
    argv+=( --ro-bind-try /etc/firefox-esr /etc/firefox-esr )
    argv+=( --ro-bind-try /etc/chromium /etc/chromium )
    argv+=( --ro-bind-try /etc/chromium.d /etc/chromium.d )
    argv+=( --ro-bind-try /etc/opt/chrome /etc/opt/chrome )
    # Enterprise auth
    argv+=( --ro-bind-try /etc/gss /etc/gss )
    argv+=( --ro-bind-try /etc/krb5.conf /etc/krb5.conf )

    # ========================================================================
    # STREAM A6: Shared data
    # ========================================================================
    argv+=( --dir /usr/share )
    argv+=( --ro-bind-try /usr/share /usr/share )
    argv+=( --dir /var/cache )
    argv+=( --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig )

    # ========================================================================
    # STREAM B1-B3: Device + ephemeral tmpfs
    # ========================================================================
    argv+=( --proc /proc )
    argv+=( --dev-bind /dev /dev )
    argv+=( --tmpfs /dev/shm )
    argv+=( --tmpfs /tmp )
    # X11 socket passthrough (bind back into fresh /tmp)
    argv+=( --ro-bind-try /tmp/.X11-unix /tmp/.X11-unix )
    # D-Bus system bus (low-risk -- no portal file picker)
    argv+=( --bind-try /run/dbus /run/dbus )
    # /run/user tmpfs -- foundation for all socket passthroughs
    argv+=( --tmpfs "/run/user/$(id -u)" )

    # ========================================================================
    # HOME: overlay + user directory
    # ========================================================================
    argv+=( --tmpfs /home )
    argv+=( --dir "/home/${user}" )
    argv+=( --bind "${home_parent}/${user}" "/home/${user}" )

    # ========================================================================
    # STREAM A5: Identity injection (FD 9/10/11)
    # ========================================================================
    # Generate synthetic /etc/passwd for virtual user
    local _uid; _uid="$(id -u)"
    local _gid; _gid="$(id -g)"
    local _passwd_content="${user}:x:${_uid}:${_gid}:${user}:/home/${user}:/bin/bash"
    local _group_content="${user}:x:${_gid}:"
    local _profile_content="# Minimal sandbox profile
export PATH=/usr/bin:/bin
export HOME=/home/${user}"

    # Inject via file descriptors -- bwrap reads from FD and creates read-only mounts
    argv+=( --ro-bind-data 9 /etc/passwd )
    argv+=( --ro-bind-data 10 /etc/group )
    argv+=( --ro-bind-data 11 /etc/profile )
    # Suppress host profile.d scripts (PATH contamination)
    argv+=( --tmpfs /etc/profile.d )

    # ========================================================================
    # STREAM A7: Chrome /opt
    # ========================================================================
    argv+=( --dir /opt )
    argv+=( --ro-bind /opt/google /opt/google )

    # ========================================================================
    # STREAM F1: Mise passthrough (PRE-LOCK mounts)
    # ========================================================================
    if [[ "$mise" != "off" ]]; then
        local _MISE_BIN
        _MISE_BIN="${MISE_BIN:-$(command -v mise 2>/dev/null || echo "$HOME/.local/bin/mise")}"
        local _MISE_DATA="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
        local _MISE_CFG="${MISE_CONFIG_DIR:-$HOME/.config/mise}"
        local _MISE_CACHE="${MISE_CACHE_DIR:-$HOME/.cache/mise}"

        # FATAL: mise binary and data dir MUST exist (exit 1 = user-correctable error)
        if [[ ! -f "$_MISE_BIN" ]]; then
            echo "[FATAL] --mise-passthrough: mise binary not found at $_MISE_BIN" >&2
            exit 1
        fi
        if [[ ! -d "$_MISE_DATA" ]]; then
            echo "[FATAL] --mise-passthrough: MISE_DATA_DIR not found at $_MISE_DATA" >&2
            exit 1
        fi

        # Warnings for optional dirs (non-fatal)
        [[ ! -d "$_MISE_CFG" ]]   && _warn "$t" "start: --mise-passthrough: config dir not found at $_MISE_CFG (skipping)"
        [[ ! -d "$_MISE_CACHE" ]] && _warn "$t" "start: --mise-passthrough: cache dir not found at $_MISE_CACHE (skipping)"

        # RO (default) or RW bind based on qualifier
        local _MISE_BIND="--ro-bind"
        [[ "$mise" == "rw" ]] && _MISE_BIND="--bind"

        # mise binary (always RO)
        argv+=( --ro-bind "$_MISE_BIN" "$_MISE_BIN" )
        # mise data dir (installs, shims, plugins)
        argv+=( $_MISE_BIND "$_MISE_DATA" "$_MISE_DATA" )
        # Optional dirs
        [[ -d "$_MISE_CFG" ]]   && argv+=( --ro-bind-try "$_MISE_CFG" "$_MISE_CFG" )
        [[ -d "$_MISE_CACHE" ]] && argv+=( --ro-bind-try "$_MISE_CACHE" "$_MISE_CACHE" )
    fi

    # ========================================================================
    # STREAM F2: Local-bin passthrough (PRE-LOCK mounts)
    # ========================================================================
    if [[ "$local_bin" != "off" ]]; then
        local _LOCAL_BIN="$HOME/.local/bin"
        if [[ ! -d "$_LOCAL_BIN" ]]; then
            echo "[FATAL] --local-bin-passthrough: directory not found at $_LOCAL_BIN" >&2
            exit 1
        fi
        if [[ "$local_bin" == "rw" ]]; then
            argv+=( --bind "$_LOCAL_BIN" "$_LOCAL_BIN" )
        else
            argv+=( --ro-bind "$_LOCAL_BIN" "$_LOCAL_BIN" )
        fi
    fi

    # ========================================================================
    # STREAM C3: Environment variables
    # ========================================================================
    if [[ "$env_pt" != "true" ]]; then
        argv+=( --clearenv )
        argv+=( --setenv HOME "/home/${user}" )
        argv+=( --setenv USER "${user}" )
        argv+=( --setenv PATH "/usr/bin:/bin" )
        argv+=( --setenv XDG_DATA_HOME "/home/${user}/.local/share" )
        argv+=( --setenv XDG_STATE_HOME "/home/${user}/.local/state" )
        argv+=( --setenv XDG_DATA_DIRS "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" )
        argv+=( --setenv MOZ_NO_REMOTE 1 )
    fi

    # ========================================================================
    # KEYSTONE: Lock root read-only + re-apply home RW write-hole
    # ========================================================================
    argv+=( --remount-ro / )
    argv+=( --bind "${home_parent}/${user}" "/home/${user}" )
    argv+=( --chdir "/home/${user}" )

    # ========================================================================
    # POST-LOCK: Socket passthroughs into /run/user tmpfs
    # ========================================================================
    local _RU="/run/user/$(id -u)"

    # STREAM D1: X11 passthrough
    if [[ "$x11" == "true" ]]; then
        argv+=( --setenv DISPLAY "${DISPLAY:-}" )
        if [[ -n "${XAUTHORITY:-}" && -f "${XAUTHORITY:-}" ]]; then
            argv+=( --ro-bind "$XAUTHORITY" "/home/${user}/.Xauthority" )
            argv+=( --setenv XAUTHORITY "/home/${user}/.Xauthority" )
        else
            argv+=( --setenv XAUTHORITY "${XAUTHORITY:-}" )
        fi
    fi

    # STREAM D2: Wayland passthrough
    if [[ "$wayland" == "true" ]]; then
        argv+=( --ro-bind-try "$_RU/wayland-0"     "$_RU/wayland-0" )
        argv+=( --ro-bind-try "$_RU/wayland-0.lock" "$_RU/wayland-0.lock" )
        argv+=( --setenv WAYLAND_DISPLAY "${WAYLAND_DISPLAY:-}" )
    fi

    # STREAM E1: Audio passthrough (PipeWire + PulseAudio)
    if [[ "$audio" == "true" ]]; then
        argv+=( --bind-try "$_RU/pipewire-0"              "$_RU/pipewire-0" )
        argv+=( --bind-try "$_RU/pipewire-0.lock"          "$_RU/pipewire-0.lock" )
        argv+=( --bind-try "$_RU/pipewire-0-manager"       "$_RU/pipewire-0-manager" )
        argv+=( --bind-try "$_RU/pipewire-0-manager.lock"  "$_RU/pipewire-0-manager.lock" )
        argv+=( --dir "$_RU/pulse" )
        argv+=( --bind-try "$_RU/pulse/native" "$_RU/pulse/native" )
        argv+=( --bind-try "$_RU/pulse/pid"    "$_RU/pulse/pid" )
    fi

    # STREAM E2: A11y passthrough (AT-SPI accessibility bus)
    if [[ "$a11y" == "true" ]]; then
        argv+=( --dir "$_RU/at-spi" )
        argv+=( --ro-bind-try "$_RU/at-spi/bus_1" "$_RU/at-spi/bus_1" )
    fi

    # STREAM E3: D-Bus session bus passthrough (SECURITY: portal escape risk)
    if [[ "$dbus" == "true" ]]; then
        echo "[SYS-LOG] WARNING: D-Bus session bus enabled -- portal file picker can see host FS." >&2
        argv+=( --bind-try "$_RU/bus"     "$_RU/bus" )
        argv+=( --dir "$_RU/dbus-1" )
        argv+=( --bind-try "$_RU/dbus-1"  "$_RU/dbus-1" )
    fi

    # STREAM E4: GNOME passthrough (gvfs, dconf, keyring, gcr)
    if [[ "$gnome" == "true" ]]; then
        argv+=( --bind-try "$_RU/gvfs"    "$_RU/gvfs" )
        argv+=( --bind-try "$_RU/gvfsd"   "$_RU/gvfsd" )
        argv+=( --bind-try "$_RU/doc"     "$_RU/doc" )
        argv+=( --dir "$_RU/dconf" )
        argv+=( --bind-try "$_RU/dconf"   "$_RU/dconf" )
        argv+=( --dir "$_RU/keyring" )
        argv+=( --bind-try "$_RU/keyring" "$_RU/keyring" )
        argv+=( --dir "$_RU/gcr" )
        argv+=( --bind-try "$_RU/gcr"     "$_RU/gcr" )
    fi

    # STREAM E5: KDE passthrough (kwallet, KSMserver, drkonqi)
    if [[ "$kde" == "true" ]]; then
        argv+=( --bind-try "$_RU/kwallet5.socket"           "$_RU/kwallet5.socket" )
        argv+=( --ro-bind-try "$_RU/KSMserver__1"           "$_RU/KSMserver__1" )
        argv+=( --bind-try "$_RU/drkonqi-coredump-launcher" "$_RU/drkonqi-coredump-launcher" )
    fi

    # STREAM F1 (cont): Mise PATH injection (post-lock env)
    if [[ "$mise" != "off" ]]; then
        local _MISE_BIN_POST
        _MISE_BIN_POST="${MISE_BIN:-$(command -v mise 2>/dev/null || echo "$HOME/.local/bin/mise")}"
        local _MISE_DATA_POST="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
        local _MISE_CFG_POST="${MISE_CONFIG_DIR:-$HOME/.config/mise}"
        argv+=( --setenv PATH "$_MISE_DATA_POST/shims:$(dirname "$_MISE_BIN_POST"):/usr/bin:/bin" )
        argv+=( --setenv MISE_DATA_DIR "$_MISE_DATA_POST" )
        argv+=( --setenv MISE_CONFIG_DIR "$_MISE_CFG_POST" )
    fi

    # ========================================================================
    # Command separator and target
    # ========================================================================
    argv+=( -- "${target_cmd[@]}" )

    # ========================================================================
    # Mode dispatch
    # ========================================================================
    if [[ "$dry_run" == "true" ]]; then
        # Print one-arg-per-line so tests can grep -n for ordering
        echo "[DRY RUN] bwrap" >&2
        local _a
        for _a in "${argv[@]}"; do
            echo "  $_a" >&2
        done
        exit 0
    fi
    if [[ "$validate" == "true" ]]; then
        _info "$t" "[VALIDATE] all flags and paths validated cleanly"
        exit 0
    fi

    # Normal mode: exec bwrap (replaces this shell)
    # FD injection: pipe synthetic content to bwrap on FDs 9, 10, 11
    _debug "$t" "start: exec bwrap ${argv[*]}"
    exec bwrap "${argv[@]}" \
        9<<< "$_passwd_content" \
        10<<< "$_group_content" \
        11<<< "$_profile_content"
}

cmd_start() {
    eval "set -- $(_unbundle_short_flags "$@")"
    local log_level="${_LOG_INFO}"
    local host_real_root="${HOME}/virtual-roots"
    local virtual_user_name="sandbox_user"
    local host_real_home_parent=""
    local dry_run="false"
    local validate_only="false"
    # Passthrough booleans
    local net_pt="false" env_pt="false" x11_pt="false" wayland_pt="false"
    local gnome_pt="false" kde_pt="false" audio_pt="false" a11y_pt="false" dbus_pt="false"
    # Passthrough graded
    local mise_pt="off" local_bin_pt="off"
    # set-once sentinels
    local _root_set="" _user_set="" _home_set="" _log_set="" _dry_set="" _val_set=""
    local _net_set="" _env_set="" _x11_set="" _wayland_set="" _gnome_set="" _kde_set=""
    local _audio_set="" _a11y_set="" _dbus_set="" _mise_set="" _local_bin_set=""
    local _x11_explicit="false"   # tracks whether --x11-passthrough was passed directly
    local target_cmd=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)      usage_start; exit 0 ;;
            --host-real-root)
                [[ -n "$_root_set" ]] && _err_duplicate "$log_level" "--host-real-root"
                _root_set="1"; host_real_root="${2:?'--host-real-root requires PATH'}"; shift 2 ;;
            --virtual-user-name)
                [[ -n "$_user_set" ]] && _err_duplicate "$log_level" "--virtual-user-name"
                _user_set="1"; virtual_user_name="${2:?'--virtual-user-name requires NAME'}"; shift 2 ;;
            --host-real-home-parent)
                [[ -n "$_home_set" ]] && _err_duplicate "$log_level" "--host-real-home-parent"
                _home_set="1"; host_real_home_parent="${2:?'--host-real-home-parent requires PATH'}"; shift 2 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set="1"; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            -n|--dry-run)
                [[ -n "$_dry_set" ]] && _err_duplicate "$log_level" "--dry-run"
                _dry_set="1"; dry_run="true"; shift ;;
            --validate)
                [[ -n "$_val_set" ]] && _err_duplicate "$log_level" "--validate"
                _val_set="1"; validate_only="true"; shift ;;
            --net-passthrough)
                [[ -n "$_net_set" ]] && _err_duplicate "$log_level" "--net-passthrough"
                _net_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--net-passthrough" "${2:-}" "$net_pt")"
                net_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --env-passthrough)
                [[ -n "$_env_set" ]] && _err_duplicate "$log_level" "--env-passthrough"
                _env_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--env-passthrough" "${2:-}" "$env_pt")"
                env_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --x11-passthrough)
                [[ -n "$_x11_set" ]] && _err_duplicate "$log_level" "--x11-passthrough"
                _x11_set="1"; _x11_explicit="true"
                local _r; _r="$(_parse_bool "$log_level" "--x11-passthrough" "${2:-}" "$x11_pt")"
                x11_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --wayland-passthrough)
                [[ -n "$_wayland_set" ]] && _err_duplicate "$log_level" "--wayland-passthrough"
                _wayland_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--wayland-passthrough" "${2:-}" "$wayland_pt")"
                wayland_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --gnome-passthrough)
                [[ -n "$_gnome_set" ]] && _err_duplicate "$log_level" "--gnome-passthrough"
                _gnome_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--gnome-passthrough" "${2:-}" "$gnome_pt")"
                gnome_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --kde-passthrough)
                [[ -n "$_kde_set" ]] && _err_duplicate "$log_level" "--kde-passthrough"
                _kde_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--kde-passthrough" "${2:-}" "$kde_pt")"
                kde_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --audio-passthrough)
                [[ -n "$_audio_set" ]] && _err_duplicate "$log_level" "--audio-passthrough"
                _audio_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--audio-passthrough" "${2:-}" "$audio_pt")"
                audio_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --a11y-passthrough)
                [[ -n "$_a11y_set" ]] && _err_duplicate "$log_level" "--a11y-passthrough"
                _a11y_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--a11y-passthrough" "${2:-}" "$a11y_pt")"
                a11y_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --dbus-passthrough)
                [[ -n "$_dbus_set" ]] && _err_duplicate "$log_level" "--dbus-passthrough"
                _dbus_set="1"
                local _r; _r="$(_parse_bool "$log_level" "--dbus-passthrough" "${2:-}" "$dbus_pt")"
                dbus_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --mise-passthrough)
                [[ -n "$_mise_set" ]] && _err_duplicate "$log_level" "--mise-passthrough"
                _mise_set="1"
                local _r; _r="$(_parse_graded "$log_level" "--mise-passthrough" "${2:-}" "$mise_pt")"
                mise_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --local-bin-passthrough)
                [[ -n "$_local_bin_set" ]] && _err_duplicate "$log_level" "--local-bin-passthrough"
                _local_bin_set="1"
                local _r; _r="$(_parse_graded "$log_level" "--local-bin-passthrough" "${2:-}" "$local_bin_pt")"
                local_bin_pt="${_r%%:*}"; [[ "${_r##*:}" -eq 2 ]] && shift 2 || shift ;;
            --)
                shift; target_cmd=("$@"); break ;;
            *)
                _error "$log_level" "start: unknown option: $1"
                printf '[DIAG] Unknown flag "%s" is not recognized.\n' "$1" >&2
                printf '[HINT] Run: %s start --help\n' "$_SCRIPT_NAME" >&2
                exit 1 ;;
        esac
    done

    # Derive defaults
    [[ -z "$host_real_home_parent" ]] && host_real_home_parent="${host_real_root}/home"

    # Check implication conflicts before applying implications
    _start_check_x11_conflict "$log_level" "$_x11_explicit" "$wayland_pt" "$gnome_pt" "$kde_pt"

    # Apply x11 implication
    x11_pt="$(_start_apply_implications "$log_level" "$x11_pt" "$wayland_pt" "$gnome_pt" "$kde_pt")"

    # CMD required unless dry-run or validate
    if [[ "${#target_cmd[@]}" -eq 0 && "$dry_run" == "false" && "$validate_only" == "false" ]]; then
        _err_missing_cmd_separator "$log_level"
    fi

    # Preflight (skip for dry-run and validate-only)
    if [[ "$dry_run" == "false" && "$validate_only" == "false" ]]; then
        _start_preflight "$log_level"
    fi

    # Path validation: always run unless dry-run (validate-only DOES validate paths per spec)
    if [[ "$dry_run" == "false" ]]; then
        _start_validate_paths "$log_level" "$host_real_root" "$host_real_home_parent" "$virtual_user_name"
    fi

    exec_sandbox "$log_level" \
        "$host_real_root" "$host_real_home_parent" "$virtual_user_name" \
        "$net_pt" "$env_pt" "$x11_pt" "$wayland_pt" "$gnome_pt" "$kde_pt" \
        "$audio_pt" "$a11y_pt" "$dbus_pt" \
        "$mise_pt" "$local_bin_pt" \
        "$dry_run" "$validate_only" \
        "${target_cmd[@]}"
}

# ==============================================================================
# stop -- stub
# ==============================================================================

usage_stop() {
    cat <<HELPEOF
${_SCRIPT_NAME} stop [OPTIONS]

  Stop a running sandbox.

  [stub -- not yet implemented]

OPTIONS
  -h, --help
  --host-real-root PATH   Identify sandbox by root path. Default: ~/virtual-roots
  --log-level NAME|NUMBER Default: INFO
  -f, --force             Send SIGKILL instead of SIGTERM.
  -t, --timeout SECONDS   Grace period before SIGKILL. Default: 10.
HELPEOF
}

cmd_stop() {
    eval "set -- $(_unbundle_short_flags "$@")"
    local log_level="${_LOG_INFO}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_stop; exit 0 ;;
            --log-level)
                log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            --host-real-root) shift 2 ;;   # accepted, not yet used
            -f|--force)       shift ;;
            -t|--timeout)     shift 2 ;;
            *)
                _error "$log_level" "stop: unknown option: $1"
                _info  "$log_level" "Run: ${_SCRIPT_NAME} stop --help"
                exit 1 ;;
        esac
    done

    _error "$log_level" "stop: not yet implemented"
    exit 1
}

# ==============================================================================
# ls -- stub
# ==============================================================================

usage_ls() {
    cat <<HELPEOF
${_SCRIPT_NAME} ls [OPTIONS]

  List known virtual roots and their run state.

  [stub -- not yet implemented]

OPTIONS
  -h, --help
  --log-level NAME|NUMBER  Default: INFO
  -a, --all                Show all roots (not just running).
  -q, --quiet              Print root paths only, one per line (scriptable).
  --format FMT             table (default) | json | csv
HELPEOF
}

cmd_ls() {
    eval "set -- $(_unbundle_short_flags "$@")"
    local log_level="${_LOG_INFO}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)       usage_ls; exit 0 ;;
            --log-level)
                log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            -a|--all)        shift ;;
            -q|--quiet)      shift ;;
            --format)        shift 2 ;;
            *)
                _error "$log_level" "ls: unknown option: $1"
                _info  "$log_level" "Run: ${_SCRIPT_NAME} ls --help"
                exit 1 ;;
        esac
    done

    _error "$log_level" "ls: not yet implemented"
    exit 1
}

# ==============================================================================
# MAIN -- dispatcher
# ==============================================================================

main() {
    _emit_banner "$@"

    # Pre-subcommand: --help / --version only
    case "${1:-}" in
        --help|-h)    usage_top;       exit 0 ;;
        --version|-v) _print_version;  exit 0 ;;
        "")
            usage_top; exit 0 ;;
    esac

    local subcmd="$1"; shift

    case "$subcmd" in
        provision) cmd_provision "$@" ;;
        fsck)      cmd_fsck      "$@" ;;
        start)     cmd_start     "$@" ;;
        stop)      cmd_stop      "$@" ;;
        ls)        cmd_ls        "$@" ;;
        *)
            printf '[ERROR] Unknown subcommand: %s\n' "$subcmd" >&2
            printf '[DIAG] "%s" is not a recognized subcommand.\n' "$subcmd" >&2
            printf '[HINT] Run: %s --help\n' "$_SCRIPT_NAME" >&2
            exit 1 ;;
    esac
}

main "$@"
