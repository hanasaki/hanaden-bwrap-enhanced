#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# *!! IMPORTANT - AI - Do not modify without explicit user permission
# ==============================================================================
# NAME:      bwrap-enhanced-test-harness-runner.sh
# VERSION:   0.2.0
# AUTHOR:    Frederick Bloom <devlabs@hanaden.com>
# COPYRIGHT: (c) 2026 Hanaden - Frederick Bloom. All rights reserved.
# LICENSE:   Proprietary. Unauthorized use, reproduction, or distribution
#            is strictly prohibited.
# PROJECT:   hanaden AI Bootloader — bwrap-enhanced test harness
# ==============================================================================
# PURPOSE:
#   The canonical test runner for bwrap-enhanced. This is the ONLY supported
#   way to discover and execute the test suite.
#
#   Subcommand dispatcher following the git / rtk / podman / systemctl pattern.
#   Each subcommand owns its own options; global pre-subcommand forms are
#   limited to --help / -h and --version / -v.
#
# SUITES LAYOUT:
#   suites/
#     <FEAT>.feat/
#       <SPEC>.spec/
#         test_<name>.bats
#
# ==============================================================================
set -euo pipefail

# ==============================================================================
# CONSTANTS
# ==============================================================================
readonly _HARNESS_NAME="$(basename "$0")"
readonly _HARNESS_VERSION="0.2.0"
readonly _HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly _SUITES_DIR="${_HARNESS_DIR}/suites"
readonly _PROJECT_HOME="$(cd "${_HARNESS_DIR}/../../.." && pwd)"
readonly _LIB_DIR="${_PROJECT_HOME}/src/lib"

# ==============================================================================
# LOG SYSTEM
# Log-level numeric values:
#   FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)
# All output goes to stderr.
# ==============================================================================
readonly _LL_FATAL=100
readonly _LL_ERROR=200
readonly _LL_WARN=300
readonly _LL_INFO=400
readonly _LL_DEBUG=500
readonly _LL_TRACE=600

_resolve_log_level() {
    local raw="${1:-INFO}"
    local upper
    upper="$(printf '%s' "$raw" | tr '[:lower:]' '[:upper:]')"
    case "$upper" in
        FATAL)   printf '%d' $_LL_FATAL ;;
        ERROR)   printf '%d' $_LL_ERROR ;;
        WARN)    printf '%d' $_LL_WARN  ;;
        INFO)    printf '%d' $_LL_INFO  ;;
        DEBUG)   printf '%d' $_LL_DEBUG ;;
        TRACE)   printf '%d' $_LL_TRACE ;;
        100|200|300|400|500|600) printf '%s' "$raw" ;;
        *) printf '[ERROR] --log-level: unknown level: %s\n' "$raw" >&2; exit 1 ;;
    esac
}

_ll_name() {
    case "$1" in
        100) printf 'FATAL' ;;  200) printf 'ERROR' ;;
        300) printf 'WARN'  ;;  400) printf 'INFO'  ;;
        500) printf 'DEBUG' ;;  600) printf 'TRACE' ;;
        *)   printf '?'    ;;
    esac
}

_log() {
    local threshold="$1" current="$2" label="$3"; shift 3
    if [[ "$current" -ge "$threshold" ]]; then
        printf '[%s] %s\n' "$label" "$*" >&2
    fi
}

_fatal() { local t="$1"; shift; _log $_LL_FATAL "$t" FATAL "$@"; exit 1; }
_error() { local t="$1"; shift; _log $_LL_ERROR "$t" ERROR "$@"; }
_warn()  { local t="$1"; shift; _log $_LL_WARN  "$t" WARN  "$@"; }
_info()  { local t="$1"; shift; _log $_LL_INFO  "$t" INFO  "$@"; }
_debug() { local t="$1"; shift; _log $_LL_DEBUG "$t" DEBUG "$@"; }
_trace() { local t="$1"; shift; _log $_LL_TRACE "$t" TRACE "$@"; }

# ==============================================================================
# COMMON OPTION PARSER HELPERS
# ==============================================================================
_err_duplicate() { _error "$1" "${_HARNESS_NAME}: duplicate option: $2"; exit 1; }
_err_unknown()   { _error "$1" "${_HARNESS_NAME} $2: unknown option: $3"
                   _info  "$1" "Run: ${_HARNESS_NAME} $2 --help"
                   exit 1; }

# ==============================================================================
# PREFLIGHT — verify bats is available
# ==============================================================================
_preflight_bats() {
    local t="$1"
    if ! command -v bats &>/dev/null; then
        _fatal "$t" "bats not found in PATH. Install via: mise install bats"
    fi
    _debug "$t" "bats: $(bats --version)"
}

# ==============================================================================
# DISCOVERY HELPERS
# ==============================================================================

# _list_bats_files [feat_filter] [spec_filter]
#   Prints absolute paths to .bats files, optionally filtered.
_list_bats_files() {
    local feat_filter="${1:-*}" spec_filter="${2:-*}"
    find "${_SUITES_DIR}" \
        -mindepth 3 -maxdepth 3 \
        -path "*/${feat_filter}.feat/${spec_filter}.spec/*.bats" \
        -type f \
    | sort
}

# _list_feat_dirs — prints one line per .feat directory (just the basename stem)
_list_feat_dirs() {
    find "${_SUITES_DIR}" -maxdepth 1 -type d -name "*.feat" | sort \
        | while IFS= read -r d; do basename "$d" .feat; done
}

# _list_spec_dirs FEAT — prints spec stems under a .feat dir
_list_spec_dirs() {
    local feat="$1"
    find "${_SUITES_DIR}/${feat}.feat" -maxdepth 1 -type d -name "*.spec" 2>/dev/null | sort \
        | while IFS= read -r d; do basename "$d" .spec; done
}

# _count_tests FILE — counts @test lines in a bats file
_count_tests() {
    grep -c '^@test ' "$1" 2>/dev/null || printf '0'
}

# _extract_test_names FILE — prints one test name per line
_extract_test_names() {
    grep '^@test ' "$1" 2>/dev/null \
        | sed 's/^@test "\(.*\)" {$/\1/' \
        | sed "s/^@test '\(.*\)' {\$/\1/"
}

# _extract_test_id NAME — first word of name (the ID prefix like BOOL-NET-001), colon stripped
_extract_test_id() {
    printf '%s' "$1" | awk '{print $1}' | tr -d ':'
}

# ==============================================================================
# VERSION
# ==============================================================================
_print_version() {
    printf '%s v%s\n' "$_HARNESS_NAME" "$_HARNESS_VERSION"
}

# ==============================================================================
# TOP-LEVEL HELP
# ==============================================================================
usage_top() {
    cat <<HELPEOF
${_HARNESS_NAME}  v${_HARNESS_VERSION}  --  bwrap-enhanced Test Harness Runner
(c) 2026 Hanaden - Frederick Bloom. All rights reserved.

This is the ONLY supported way to discover and run the bwrap-enhanced test suite.

${_HARNESS_NAME}  SUBCOMMAND  [OPTIONS]  [ARGS]
${_HARNESS_NAME}  --help | -h
${_HARNESS_NAME}  --version | -v

  list-suites
    --feat     PATTERN       Filter by feat name (fnmatch glob, no .feat suffix)
    --spec     PATTERN       Filter by spec name (fnmatch glob, no .spec suffix)
    --populated              Show only suites that contain .bats files
    --format   table|names   Output format (default: table)
    --log-level NAME|NUMBER  (default: INFO)

  list-tests  [FEAT]
    --feat     PATTERN       Filter by feat name (fnmatch glob)
    --spec     PATTERN       Filter by spec name (fnmatch glob)
    --format   table|ids     Output format (default: table)
    --log-level NAME|NUMBER  (default: INFO)

  run
    --feat     PATTERN       Run only suites matching this feat glob
    --spec     PATTERN       Run only specs matching this spec glob
    --filter   REGEX         Run only tests whose name matches this regex
    --format   pretty|tap|tap13|junit  (default: pretty)
    --timed                  Enable timing + JSONL emission to target/test.run.report/
    --log-level NAME|NUMBER  (default: INFO)
    -n, --dry-run            Print bats invocation; do not run

  run-all
    --populated-only         Skip empty suites (default: true)
    --format   pretty|tap|tap13|junit  (default: pretty)
    --timed                  Enable timing + JSONL emission to target/test.run.report/
    --log-level NAME|NUMBER  (default: INFO)
    -n, --dry-run            Print bats invocation; do not run

  report  SUBCOMMAND
    junit-xml   --input JSONL   Convert JSONL → JUnit XML
    jacoco-xml  --input JSONL   Convert JSONL → JaCoCo XML
    html        --junit XML     Generate JUnit HTML site
                --jacoco XML    Generate JaCoCo HTML site
                --junit + --jacoco  Generate unified HTML site
                --output DIR    Output directory (optional)

Log levels: FATAL(100) < ERROR(200) < WARN(300) < INFO(400) < DEBUG(500) < TRACE(600)
Default: INFO(400). All output goes to stderr; test results go to stdout.
Run: ${_HARNESS_NAME} SUBCOMMAND --help  for detailed subcommand help.
HELPEOF
}

# ==============================================================================
# list-suites — help and implementation
# ==============================================================================
usage_list_suites() {
    cat <<HELPEOF
${_HARNESS_NAME} list-suites [OPTIONS]

  Discover and display all feat/spec pairs in the suites directory.

OPTIONS
  -h, --help
  --feat     PATTERN       Filter by feat name (fnmatch glob, omit .feat suffix)
                           Example: --feat CliContract
  --spec     PATTERN       Filter by spec name (fnmatch glob, omit .spec suffix)
                           Example: --spec Bool*
  --populated              Show only suites that contain at least one .bats file
  --format   table|names   Output format (default: table)
                             table:  aligned columns (FEAT  SPEC  TESTS  STATUS)
                             names:  bare <FEAT>/<SPEC> one per line
  --log-level NAME|NUMBER  (default: INFO)

EXIT CODES
  0   success
  1   option parse error

EXAMPLES
  ${_HARNESS_NAME} list-suites
  ${_HARNESS_NAME} list-suites --populated
  ${_HARNESS_NAME} list-suites --feat CliContract
  ${_HARNESS_NAME} list-suites --format names
HELPEOF
}

cmd_list_suites() {
    local log_level=$_LL_INFO
    local feat_pat="*" spec_pat="*" populated_only=false fmt="table"
    local _log_set="" _feat_set="" _spec_set="" _fmt_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)          usage_list_suites; exit 0 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set=1; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            --feat)
                [[ -n "$_feat_set" ]] && _err_duplicate "$log_level" "--feat"
                _feat_set=1; feat_pat="${2:?'--feat requires PATTERN'}"; shift 2 ;;
            --spec)
                [[ -n "$_spec_set" ]] && _err_duplicate "$log_level" "--spec"
                _spec_set=1; spec_pat="${2:?'--spec requires PATTERN'}"; shift 2 ;;
            --populated)        populated_only=true; shift ;;
            --format)
                [[ -n "$_fmt_set" ]] && _err_duplicate "$log_level" "--format"
                _fmt_set=1
                case "${2:-}" in
                    table|names) fmt="$2" ;;
                    *) _error "$log_level" "list-suites: --format must be table|names"; exit 1 ;;
                esac
                shift 2 ;;
            *) _err_unknown "$log_level" "list-suites" "$1" ;;
        esac
    done

    _debug "$log_level" "list-suites: feat=${feat_pat} spec=${spec_pat} populated=${populated_only} fmt=${fmt}"
    _debug "$log_level" "suites dir: ${_SUITES_DIR}"

    local feat_dir feat spec_dir spec bats_file count status
    local -a feat_dirs

    mapfile -t feat_dirs < <(find "${_SUITES_DIR}" -maxdepth 1 -type d -name "*.feat" | sort)

    # Print header for table mode
    if [[ "$fmt" == "table" ]]; then
        printf '%-30s  %-30s  %5s  %s\n' "FEAT" "SPEC" "TESTS" "STATUS"
        printf '%s\n' "$(printf '%-30s  %-30s  %5s  %s\n' "-----" "----" "-----" "------" | tr ' ' '-')"
    fi

    local printed=0
    for feat_dir in "${feat_dirs[@]}"; do
        feat="$(basename "$feat_dir" .feat)"
        # Apply feat glob
        # shellcheck disable=SC2254
        case "$feat" in $feat_pat) ;; *) continue ;; esac

        local -a spec_dirs
        mapfile -t spec_dirs < <(find "$feat_dir" -maxdepth 1 -type d -name "*.spec" | sort)

        if [[ ${#spec_dirs[@]} -eq 0 ]]; then
            # feat with no specs at all — treat as one empty entry
            spec="(no specs)"
            if [[ "$populated_only" == "true" ]]; then continue; fi
            if [[ "$fmt" == "table" ]]; then
                printf '%-30s  %-30s  %5d  %s\n' "$feat" "$spec" 0 "empty"
            else
                printf '%s/%s\n' "$feat" "$spec"
            fi
            (( printed++ )) || true
            continue
        fi

        for spec_dir in "${spec_dirs[@]}"; do
            spec="$(basename "$spec_dir" .spec)"
            # Apply spec glob
            # shellcheck disable=SC2254
            case "$spec" in $spec_pat) ;; *) continue ;; esac

            # Count tests
            count=0
            while IFS= read -r bats_file; do
                n="$(_count_tests "$bats_file")"
                count=$(( count + n ))
            done < <(find "$spec_dir" -maxdepth 1 -name "*.bats" -type f)

            if [[ "$populated_only" == "true" && "$count" -eq 0 ]]; then continue; fi
            status="populated"
            [[ "$count" -eq 0 ]] && status="empty"

            if [[ "$fmt" == "table" ]]; then
                printf '%-30s  %-30s  %5d  %s\n' "$feat" "$spec" "$count" "$status"
            else
                printf '%s/%s\n' "$feat" "$spec"
            fi
            (( printed++ )) || true
        done
    done

    _info "$log_level" "list-suites: ${printed} entries"
}

# ==============================================================================
# list-tests — help and implementation
# ==============================================================================
usage_list_tests() {
    cat <<HELPEOF
${_HARNESS_NAME} list-tests [OPTIONS]

  List all @test cases discovered in the suites directory.

OPTIONS
  -h, --help
  --feat     PATTERN       Filter by feat name (fnmatch glob, omit .feat suffix)
  --spec     PATTERN       Filter by spec name (fnmatch glob, omit .spec suffix)
  --format   table|ids     Output format (default: table)
                             table:  FEAT  SPEC  ID  NAME
                             ids:    bare test IDs (first token of test name)
  --log-level NAME|NUMBER  (default: INFO)

EXIT CODES
  0   success (even if 0 tests found)
  1   option parse error

EXAMPLES
  ${_HARNESS_NAME} list-tests
  ${_HARNESS_NAME} list-tests --feat CliContract
  ${_HARNESS_NAME} list-tests --feat ErrorDiagnostics --format ids
  ${_HARNESS_NAME} list-tests --spec BoolFlagParsing
HELPEOF
}

cmd_list_tests() {
    local log_level=$_LL_INFO
    local feat_pat="*" spec_pat="*" fmt="table"
    local _log_set="" _feat_set="" _spec_set="" _fmt_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)          usage_list_tests; exit 0 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set=1; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            --feat)
                [[ -n "$_feat_set" ]] && _err_duplicate "$log_level" "--feat"
                _feat_set=1; feat_pat="${2:?'--feat requires PATTERN'}"; shift 2 ;;
            --spec)
                [[ -n "$_spec_set" ]] && _err_duplicate "$log_level" "--spec"
                _spec_set=1; spec_pat="${2:?'--spec requires PATTERN'}"; shift 2 ;;
            --format)
                [[ -n "$_fmt_set" ]] && _err_duplicate "$log_level" "--format"
                _fmt_set=1
                case "${2:-}" in
                    table|ids) fmt="$2" ;;
                    *) _error "$log_level" "list-tests: --format must be table|ids"; exit 1 ;;
                esac
                shift 2 ;;
            *) _err_unknown "$log_level" "list-tests" "$1" ;;
        esac
    done

    if [[ "$fmt" == "table" ]]; then
        printf '%-25s  %-25s  %-16s  %s\n' "FEAT" "SPEC" "ID" "NAME"
        printf '%s\n' "$(printf '%-25s  %-25s  %-16s  %s\n' "----" "----" "--" "----" | tr ' ' '-')"
    fi

    local count=0
    local feat_dir feat spec_dir spec bats_file name id

    while IFS= read -r feat_dir; do
        feat="$(basename "$feat_dir" .feat)"
        # shellcheck disable=SC2254
        case "$feat" in $feat_pat) ;; *) continue ;; esac

        while IFS= read -r spec_dir; do
            spec="$(basename "$spec_dir" .spec)"
            # shellcheck disable=SC2254
            case "$spec" in $spec_pat) ;; *) continue ;; esac

            while IFS= read -r bats_file; do
                while IFS= read -r name; do
                    id="$(_extract_test_id "$name")"
                    if [[ "$fmt" == "table" ]]; then
                        printf '%-25s  %-25s  %-16s  %s\n' "$feat" "$spec" "$id" "$name"
                    else
                        printf '%s\n' "$id"
                    fi
                    (( count++ )) || true
                done < <(_extract_test_names "$bats_file")
            done < <(find "$spec_dir" -maxdepth 1 -name "*.bats" -type f | sort)

        done < <(find "$feat_dir" -maxdepth 1 -type d -name "*.spec" | sort)

    done < <(find "${_SUITES_DIR}" -maxdepth 1 -type d -name "*.feat" | sort)

    _info "$log_level" "list-tests: ${count} test(s)"
}

# ==============================================================================
# run — help and implementation
# ==============================================================================
usage_run() {
    cat <<HELPEOF
${_HARNESS_NAME} run [OPTIONS]

  Run bats tests matching the given filters.

OPTIONS
  -h, --help
  --feat     PATTERN       Run only suites in matching .feat dirs (fnmatch glob)
                           Example: --feat CliContract
  --spec     PATTERN       Run only .spec dirs matching this glob
                           Example: --spec Bool*
  --filter   REGEX         Pass --filter REGEX to bats (match by test name)
                           Example: --filter 'BOOL-NET-0'
  --format   pretty|tap|tap13|junit   Bats formatter (default: pretty)
  --log-level NAME|NUMBER  (default: INFO)
  -n, --dry-run            Print the bats invocation; do not run

EXIT CODES
  0   all tests passed
  1   one or more tests failed (bats exit code propagated)
  2   no .bats files matched the given filters
  3   option parse error

EXAMPLES
  ${_HARNESS_NAME} run --feat CliContract
  ${_HARNESS_NAME} run --feat ErrorDiagnostics --spec BoolFalseRejection
  ${_HARNESS_NAME} run --filter 'BOOL-NET-001'
  ${_HARNESS_NAME} run --feat Dispatch --format tap
  ${_HARNESS_NAME} run --dry-run
HELPEOF
}

cmd_run() {
    local log_level=$_LL_INFO
    local feat_pat="*" spec_pat="*" bats_filter="" bats_fmt="pretty" dry_run=false timed=false
    local _log_set="" _feat_set="" _spec_set="" _filter_set="" _fmt_set="" _dry_set="" _timed_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)          usage_run; exit 0 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set=1; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            --feat)
                [[ -n "$_feat_set" ]] && _err_duplicate "$log_level" "--feat"
                _feat_set=1; feat_pat="${2:?'--feat requires PATTERN'}"; shift 2 ;;
            --spec)
                [[ -n "$_spec_set" ]] && _err_duplicate "$log_level" "--spec"
                _spec_set=1; spec_pat="${2:?'--spec requires PATTERN'}"; shift 2 ;;
            --filter)
                [[ -n "$_filter_set" ]] && _err_duplicate "$log_level" "--filter"
                _filter_set=1; bats_filter="${2:?'--filter requires REGEX'}"; shift 2 ;;
            --format)
                [[ -n "$_fmt_set" ]] && _err_duplicate "$log_level" "--format"
                _fmt_set=1
                case "${2:-}" in
                    pretty|tap|tap13|junit) bats_fmt="$2" ;;
                    *) _error "$log_level" "run: --format must be pretty|tap|tap13|junit"; exit 1 ;;
                esac
                shift 2 ;;
            --timed)
                [[ -n "$_timed_set" ]] && _err_duplicate "$log_level" "--timed"
                _timed_set=1; timed=true; shift ;;
            -n|--dry-run)
                [[ -n "$_dry_set" ]] && _err_duplicate "$log_level" "--dry-run"
                _dry_set=1; dry_run=true; shift ;;
            *) _err_unknown "$log_level" "run" "$1" ;;
        esac
    done

    _preflight_bats "$log_level"

    # Collect matching .bats files
    local -a bats_files
    mapfile -t bats_files < <(_list_bats_files "$feat_pat" "$spec_pat")

    if [[ ${#bats_files[@]} -eq 0 ]]; then
        _error "$log_level" "run: no .bats files match feat=${feat_pat} spec=${spec_pat}"
        exit 2
    fi

    _info "$log_level" "run: ${#bats_files[@]} .bats file(s) matched"
    if [[ "$log_level" -ge "$_LL_DEBUG" ]]; then
        for f in "${bats_files[@]}"; do
            _debug "$log_level" "  $f"
        done
    fi

    # Build scope label for --timed directory name
    local scope="run"
    if [[ "$feat_pat" != "*" ]]; then
        scope="run--feat-${feat_pat}"
        if [[ "$spec_pat" != "*" ]]; then
            scope="run--feat-${feat_pat}--spec-${spec_pat}"
        fi
    fi

    # Build bats argv
    local -a bats_argv
    bats_argv=( bats "--formatter" "$bats_fmt" )
    if [[ -n "$bats_filter" ]]; then
        bats_argv+=( "--filter" "$bats_filter" )
    fi

    # --timed: add dual formatter + timing, prepare output dir
    local run_dir=""
    if [[ "$timed" == "true" ]]; then
        if ! command -v jq &>/dev/null; then
            _fatal "$log_level" "--timed requires jq in PATH"
        fi
        # Source emitter library
        # shellcheck source=../../lib/test-emit.sh
        source "${_LIB_DIR}/test-emit.sh"
        emit_init "$scope" "$_PROJECT_HOME"
        run_dir="$_EMIT_RUN_DIR"
        bats_argv+=( "--report-formatter" "junit" "--output" "${run_dir}/_bats-junit-raw" "--timing" )
        _info "$log_level" "run: --timed enabled → ${run_dir}"
    fi

    bats_argv+=( "${bats_files[@]}" )

    if [[ "$dry_run" == "true" ]]; then
        printf '[DRY RUN] %s\n' "${bats_argv[*]}" >&2
        if [[ -n "$run_dir" ]]; then
            printf '[DRY RUN] Post-process: bats-junit-to-jsonl.sh → %s/streaming.jsonl\n' "$run_dir" >&2
        fi
        exit 0
    fi

    _info "$log_level" "run: invoking bats"
    local bats_exit=0
    "${bats_argv[@]}" || bats_exit=$?

    # --timed: post-process bats JUnit XML → JSONL
    if [[ "$timed" == "true" ]]; then
        if [[ -f "${run_dir}/_bats-junit-raw/report.xml" ]]; then
            _info "$log_level" "run: post-processing bats JUnit XML → JSONL"
            bash "${_LIB_DIR}/bats-junit-to-jsonl.sh" \
                "${run_dir}/_bats-junit-raw/report.xml" \
                "${run_dir}/streaming.jsonl"
            # Write run metadata
            local bats_ver
            bats_ver="$(bats --version 2>/dev/null || echo 'unknown')"
            source "${_LIB_DIR}/test-emit.sh"  # ensure emit functions available
            emit_run_metadata "$bats_ver" "$_HARNESS_VERSION" "$scope" \
                "feat=${feat_pat},spec=${spec_pat}" "${#bats_files[@]}" "$bats_exit"
            emit_close
            _info "$log_level" "run: JSONL written → ${run_dir}/streaming.jsonl"
        else
            _warn "$log_level" "run: bats did not produce JUnit XML at ${run_dir}/_bats-junit-raw/report.xml"
        fi
    fi

    exit "$bats_exit"
}

# ==============================================================================
# run-all — help and implementation
# ==============================================================================
usage_run_all() {
    cat <<HELPEOF
${_HARNESS_NAME} run-all [OPTIONS]

  Run the entire test suite (all populated suites).

OPTIONS
  -h, --help
  --populated-only         Skip suites with no .bats files (default: true)
  --no-populated-only      Include empty suites (will produce no tests)
  --format   pretty|tap|tap13|junit   Bats formatter (default: pretty)
  --log-level NAME|NUMBER  (default: INFO)
  -n, --dry-run            Print the bats invocation; do not run

EXIT CODES
  0   all tests passed
  1   one or more tests failed (bats exit code propagated)
  3   option parse error

EXAMPLES
  ${_HARNESS_NAME} run-all
  ${_HARNESS_NAME} run-all --format tap
  ${_HARNESS_NAME} run-all --dry-run
  ${_HARNESS_NAME} run-all --log-level DEBUG
HELPEOF
}

cmd_run_all() {
    local log_level=$_LL_INFO
    local populated_only=true bats_fmt="pretty" dry_run=false timed=false
    local _log_set="" _fmt_set="" _dry_set="" _timed_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)          usage_run_all; exit 0 ;;
            --log-level)
                [[ -n "$_log_set" ]] && _err_duplicate "$log_level" "--log-level"
                _log_set=1; log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            --populated-only)    populated_only=true;  shift ;;
            --no-populated-only) populated_only=false; shift ;;
            --format)
                [[ -n "$_fmt_set" ]] && _err_duplicate "$log_level" "--format"
                _fmt_set=1
                case "${2:-}" in
                    pretty|tap|tap13|junit) bats_fmt="$2" ;;
                    *) _error "$log_level" "run-all: --format must be pretty|tap|tap13|junit"; exit 1 ;;
                esac
                shift 2 ;;
            --timed)
                [[ -n "$_timed_set" ]] && _err_duplicate "$log_level" "--timed"
                _timed_set=1; timed=true; shift ;;
            -n|--dry-run)
                [[ -n "$_dry_set" ]] && _err_duplicate "$log_level" "--dry-run"
                _dry_set=1; dry_run=true; shift ;;
            *) _err_unknown "$log_level" "run-all" "$1" ;;
        esac
    done

    _preflight_bats "$log_level"

    # Collect all .bats files, optionally skipping empty suites
    local -a bats_files
    if [[ "$populated_only" == "true" ]]; then
        mapfile -t bats_files < <(
            find "${_SUITES_DIR}" -name "*.bats" -type f | sort
        )
    else
        mapfile -t bats_files < <(
            find "${_SUITES_DIR}" -name "*.bats" -type f | sort
        )
    fi

    if [[ ${#bats_files[@]} -eq 0 ]]; then
        _warn "$log_level" "run-all: no .bats files found under ${_SUITES_DIR}"
        exit 0
    fi

    _info "$log_level" "run-all: ${#bats_files[@]} .bats file(s) found"

    local -a bats_argv
    bats_argv=( bats "--formatter" "$bats_fmt" )

    # --timed: add dual formatter + timing, prepare output dir
    local run_dir=""
    if [[ "$timed" == "true" ]]; then
        if ! command -v jq &>/dev/null; then
            _fatal "$log_level" "--timed requires jq in PATH"
        fi
        # shellcheck source=../../lib/test-emit.sh
        source "${_LIB_DIR}/test-emit.sh"
        emit_init "run-all" "$_PROJECT_HOME"
        run_dir="$_EMIT_RUN_DIR"
        bats_argv+=( "--report-formatter" "junit" "--output" "${run_dir}/_bats-junit-raw" "--timing" )
        _info "$log_level" "run-all: --timed enabled → ${run_dir}"
    fi

    bats_argv+=( "${bats_files[@]}" )

    if [[ "$dry_run" == "true" ]]; then
        printf '[DRY RUN] %s\n' "${bats_argv[*]}" >&2
        if [[ -n "$run_dir" ]]; then
            printf '[DRY RUN] Post-process: bats-junit-to-jsonl.sh → %s/streaming.jsonl\n' "$run_dir" >&2
        fi
        exit 0
    fi

    _info "$log_level" "run-all: invoking bats"
    local bats_exit=0
    "${bats_argv[@]}" || bats_exit=$?

    # --timed: post-process bats JUnit XML → JSONL
    if [[ "$timed" == "true" ]]; then
        if [[ -f "${run_dir}/_bats-junit-raw/report.xml" ]]; then
            _info "$log_level" "run-all: post-processing bats JUnit XML → JSONL"
            bash "${_LIB_DIR}/bats-junit-to-jsonl.sh" \
                "${run_dir}/_bats-junit-raw/report.xml" \
                "${run_dir}/streaming.jsonl"
            local bats_ver
            bats_ver="$(bats --version 2>/dev/null || echo 'unknown')"
            source "${_LIB_DIR}/test-emit.sh"
            emit_run_metadata "$bats_ver" "$_HARNESS_VERSION" "run-all" \
                "all" "${#bats_files[@]}" "$bats_exit"
            emit_close
            _info "$log_level" "run-all: JSONL written → ${run_dir}/streaming.jsonl"
        else
            _warn "$log_level" "run-all: bats did not produce JUnit XML at ${run_dir}/_bats-junit-raw/report.xml"
        fi
    fi

    exit "$bats_exit"
}

# ==============================================================================
# report — subcommand for XML conversion and HTML generation
# ==============================================================================
usage_report() {
    cat <<HELPEOF
${_HARNESS_NAME} report SUBCOMMAND [OPTIONS]

  Generate structured reports from JSONL streaming data.

SUBCOMMANDS
  junit-xml   --input JSONL     Convert JSONL → JUnit XML
  jacoco-xml  --input JSONL     Convert JSONL → JaCoCo XML
  html        [--junit XML] [--jacoco XML] [--output DIR]
              Generate HTML site from JUnit and/or JaCoCo XML.
              Provide --junit for JUnit-only, --jacoco for JaCoCo-only,
              or both for a unified report.

OPTIONS
  -h, --help
  --log-level NAME|NUMBER  (default: INFO)

EXAMPLES
  ${_HARNESS_NAME} report junit-xml  --input target/test.run.report/*/streaming.jsonl
  ${_HARNESS_NAME} report jacoco-xml --input target/test.run.report/*/streaming.jsonl
  ${_HARNESS_NAME} report html --junit target/test.run.report/*/junit.xml
  ${_HARNESS_NAME} report html --junit RUN_DIR/junit.xml --jacoco RUN_DIR/jacoco.xml
HELPEOF
}

cmd_report() {
    local log_level=$_LL_INFO

    if [[ $# -eq 0 ]]; then
        _error "$log_level" "report: subcommand required (junit-xml, jacoco-xml, html)"
        usage_report >&2
        exit 1
    fi

    case "$1" in
        -h|--help)   usage_report; exit 0 ;;
        junit-xml)   shift; _cmd_report_junit_xml  "$@" ;;
        jacoco-xml)  shift; _cmd_report_jacoco_xml "$@" ;;
        html)        shift; _cmd_report_html       "$@" ;;
        *)
            _error "$log_level" "report: unknown subcommand: $1"
            _info  "$log_level" "report: valid subcommands: junit-xml, jacoco-xml, html"
            exit 1 ;;
    esac
}

_cmd_report_junit_xml() {
    local log_level=$_LL_INFO input=""
    local _input_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                printf '%s report junit-xml --input <JSONL>\n' "$_HARNESS_NAME"
                printf '  Convert JSONL streaming records to JUnit XML.\n'
                exit 0 ;;
            --input)
                [[ -n "$_input_set" ]] && _err_duplicate "$log_level" "--input"
                _input_set=1; input="${2:?'--input requires JSONL path'}"; shift 2 ;;
            --log-level)
                log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            *) _err_unknown "$log_level" "report junit-xml" "$1" ;;
        esac
    done

    if [[ -z "$input" ]]; then
        _error "$log_level" "report junit-xml: --input is required"
        exit 1
    fi
    if [[ ! -f "$input" ]]; then
        _error "$log_level" "report: JSONL file not found: $input"
        exit 2
    fi

    _info "$log_level" "report junit-xml: converting $input"
    bash "${_LIB_DIR}/jsonl-to-junit-xml.sh" "$input"
}

_cmd_report_jacoco_xml() {
    local log_level=$_LL_INFO input=""
    local _input_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                printf '%s report jacoco-xml --input <JSONL>\n' "$_HARNESS_NAME"
                printf '  Convert JSONL streaming records to JaCoCo XML.\n'
                exit 0 ;;
            --input)
                [[ -n "$_input_set" ]] && _err_duplicate "$log_level" "--input"
                _input_set=1; input="${2:?'--input requires JSONL path'}"; shift 2 ;;
            --log-level)
                log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            *) _err_unknown "$log_level" "report jacoco-xml" "$1" ;;
        esac
    done

    if [[ -z "$input" ]]; then
        _error "$log_level" "report jacoco-xml: --input is required"
        exit 1
    fi
    if [[ ! -f "$input" ]]; then
        _error "$log_level" "report: JSONL file not found: $input"
        exit 2
    fi

    _info "$log_level" "report jacoco-xml: converting $input"
    bash "${_LIB_DIR}/jsonl-to-jacoco-xml.sh" "$input"
}

_cmd_report_html() {
    local log_level=$_LL_INFO junit_xml="" jacoco_xml="" output_dir=""
    local _junit_set="" _jacoco_set="" _output_set=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                printf '%s report html [--junit XML] [--jacoco XML] [--output DIR]\n' "$_HARNESS_NAME"
                printf '  Generate HTML site from JUnit and/or JaCoCo XML.\n'
                printf '  Provide --junit for JUnit-only, --jacoco for JaCoCo-only,\n'
                printf '  or both for a unified report.\n'
                exit 0 ;;
            --junit)
                [[ -n "$_junit_set" ]] && _err_duplicate "$log_level" "--junit"
                _junit_set=1; junit_xml="${2:?'--junit requires XML path'}"; shift 2 ;;
            --jacoco)
                [[ -n "$_jacoco_set" ]] && _err_duplicate "$log_level" "--jacoco"
                _jacoco_set=1; jacoco_xml="${2:?'--jacoco requires XML path'}"; shift 2 ;;
            --output)
                [[ -n "$_output_set" ]] && _err_duplicate "$log_level" "--output"
                _output_set=1; output_dir="${2:?'--output requires DIR'}"; shift 2 ;;
            --log-level)
                log_level="$(_resolve_log_level "${2:?'--log-level requires NAME|NUMBER'}")"; shift 2 ;;
            *) _err_unknown "$log_level" "report html" "$1" ;;
        esac
    done

    if [[ -z "$junit_xml" && -z "$jacoco_xml" ]]; then
        _error "$log_level" "report html: requires --junit and/or --jacoco"
        exit 1
    fi

    # Validate inputs exist
    if [[ -n "$junit_xml" && ! -f "$junit_xml" ]]; then
        _error "$log_level" "report: JUnit XML not found: $junit_xml"
        exit 2
    fi
    if [[ -n "$jacoco_xml" && ! -f "$jacoco_xml" ]]; then
        _error "$log_level" "report: JaCoCo XML not found: $jacoco_xml"
        exit 2
    fi

    # Check python3
    if ! command -v python3 &>/dev/null; then
        _fatal "$log_level" "report: python3 not found in PATH"
    fi

    local generators_dir="${_LIB_DIR}/report-generators"

    if [[ -n "$junit_xml" && -n "$jacoco_xml" ]]; then
        # Unified report
        local -a py_args=( python3 "${generators_dir}/unified_html_report.py"
            --junit "$junit_xml" --jacoco "$jacoco_xml" )
        [[ -n "$output_dir" ]] && py_args+=( --output "$output_dir" )
        _info "$log_level" "report html: generating unified HTML site"
        "${py_args[@]}"
    elif [[ -n "$junit_xml" ]]; then
        # JUnit-only
        local -a py_args=( python3 "${generators_dir}/junit_html_report.py"
            --input "$junit_xml" )
        [[ -n "$output_dir" ]] && py_args+=( --output "$output_dir" )
        _info "$log_level" "report html: generating JUnit HTML site"
        "${py_args[@]}"
    else
        # JaCoCo-only
        local -a py_args=( python3 "${generators_dir}/jacoco_html_report.py"
            --input "$jacoco_xml" )
        [[ -n "$output_dir" ]] && py_args+=( --output "$output_dir" )
        _info "$log_level" "report html: generating JaCoCo HTML site"
        "${py_args[@]}"
    fi
}

# ==============================================================================
# MAIN DISPATCH
# ==============================================================================
if [[ $# -eq 0 ]]; then
    usage_top
    exit 0
fi

case "$1" in
    --help|-h)    usage_top;    exit 0 ;;
    --version|-v) _print_version; exit 0 ;;
    list-suites)  shift; cmd_list_suites "$@" ;;
    list-tests)   shift; cmd_list_tests  "$@" ;;
    run)          shift; cmd_run         "$@" ;;
    run-all)      shift; cmd_run_all     "$@" ;;
    report)       shift; cmd_report      "$@" ;;
    *)
        _error "$_LL_INFO" "unknown subcommand: $1"
        _info  "$_LL_INFO" "Run: ${_HARNESS_NAME} --help"
        exit 1 ;;
esac
