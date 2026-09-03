#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- test-emit.sh -- Hanaden AI
# ==============================================================================
# NAME:      test-emit.sh
# VERSION:   0.1.0
# PURPOSE:   JSONL event emitter library for the bwrap-enhanced test harness.
#            Provides functions to emit streaming JSONL records conforming to
#            TestRunReportSchema.feat-0.0.1 (4 record types: suite_started,
#            test_case, coverage_record, suite_finished).
#
# USAGE:     Sourced by the harness runner -- not invoked directly.
#              source "${LIB_DIR}/test-emit.sh"
#              emit_init "run-all" "${PROJECT_HOME}"
#              emit_suite_started "BwrapPreflight/UserNamespaceEnabled" 3
#              emit_test_case "USRNS-001" "namespace enabled" \
#                  "BwrapPreflight" "UserNamespaceEnabled" "PASS" 112
#              emit_coverage_record "BwrapPreflight" "UserNamespaceEnabled" 3 3 24 24
#              emit_suite_finished "BwrapPreflight/UserNamespaceEnabled" 3 3 0 0 210
#
# DEPENDENCIES: jq (for JSON construction), /dev/urandom (for trace/span IDs)
#
# OUTPUTS:   All JSONL records are written to a file descriptor (_EMIT_FD),
#            NOT to stdout (avoids polluting bats output). The output file
#            is <RUN_DIR>/streaming.jsonl.
# ==============================================================================

# Guard: only source once
[[ -n "${_TEST_EMIT_SOURCED:-}" ]] && return 0
readonly _TEST_EMIT_SOURCED=1

# ==============================================================================
# TIMING HELPERS
# ==============================================================================

# _now_unix_ms -- current time in milliseconds since epoch
_now_unix_ms() {
    # date +%s%N gives nanoseconds; divide by 1000000 for ms
    local ns
    ns="$(date +%s%N)"
    printf '%s' "$(( ns / 1000000 ))"
}

# _duration_ms START_MS END_MS -- returns (end - start)
_duration_ms() {
    printf '%s' "$(( $2 - $1 ))"
}

# ==============================================================================
# ID GENERATORS
# ==============================================================================

# _generate_trace_id -- 32-char lowercase hex string from /dev/urandom
_generate_trace_id() {
    od -An -tx1 -N16 /dev/urandom | tr -d ' \n'
}

# _generate_span_id -- 16-char lowercase hex string from /dev/urandom
_generate_span_id() {
    od -An -tx1 -N8 /dev/urandom | tr -d ' \n'
}

# ==============================================================================
# OUTPUT PATH HELPERS
# ==============================================================================

# _report_base_dir PROJECT_HOME -- returns PROJECT_HOME/target/test.run.report
_report_base_dir() {
    printf '%s/target/test.run.report' "$1"
}

# _make_run_dir_name SCOPE -- returns timestamped Zulu directory name
#   e.g. "20260831-215200-123456.run-all.test.run"
_make_run_dir_name() {
    local scope="$1"
    local ts
    ts="$(date -u +%Y%m%d-%H%M%S-%6N)"
    printf '%s.%s.test.run' "$ts" "$scope"
}

# ==============================================================================
# INITIALIZATION
# ==============================================================================

# Global state set by emit_init
_EMIT_RUN_DIR=""
_EMIT_JSONL_PATH=""
_EMIT_FD=""
_EMIT_TRACE_ID=""

# emit_init SCOPE PROJECT_HOME
#   Creates the per-run directory, opens the JSONL output file on FD 7,
#   generates the trace_id for this run.
#
#   SCOPE: describes what was run, e.g. "run-all", "run--feat-CliContract"
#   PROJECT_HOME: absolute path to PROJECT_HOME
#
#   After calling: _EMIT_RUN_DIR, _EMIT_JSONL_PATH, _EMIT_TRACE_ID are set.
emit_init() {
    local scope="$1"
    local project_home="$2"

    local base_dir
    base_dir="$(_report_base_dir "$project_home")"

    local dir_name
    dir_name="$(_make_run_dir_name "$scope")"

    _EMIT_RUN_DIR="${base_dir}/${dir_name}"
    _EMIT_JSONL_PATH="${_EMIT_RUN_DIR}/streaming.jsonl"

    mkdir -p "${_EMIT_RUN_DIR}/_bats-junit-raw"

    # Open FD 7 for JSONL output
    exec 7>"${_EMIT_JSONL_PATH}"
    _EMIT_FD=7

    # Generate trace ID for this run
    _EMIT_TRACE_ID="$(_generate_trace_id)"
}

# emit_close -- close the JSONL file descriptor
emit_close() {
    if [[ -n "${_EMIT_FD}" ]]; then
        exec 7>&-
        _EMIT_FD=""
    fi
}

# ==============================================================================
# RECORD EMITTERS
# ==============================================================================
# Each function writes exactly one JSONL line to FD 7.
# Uses `jq -n -c` for correct JSON construction (no hand-assembled strings).

# emit_suite_started SUITE_NAME TEST_COUNT
emit_suite_started() {
    local suite_name="$1"
    local test_count="$2"
    local ts
    ts="$(_now_unix_ms)"

    jq -n -c \
        --arg type "suite_started" \
        --arg trace_id "$_EMIT_TRACE_ID" \
        --arg suite_name "$suite_name" \
        --argjson timestamp_unix_ms "$ts" \
        --argjson test_count "$test_count" \
        '{
            type: $type,
            trace_id: $trace_id,
            suite_name: $suite_name,
            timestamp_unix_ms: $timestamp_unix_ms,
            test_count: $test_count
        }' >&7
}

# emit_test_case VECTOR_ID DESCRIPTION FEAT SPEC STATUS DURATION_MS [ERROR_MSG] [OUTPUT]
#   STATUS: one of PASS, FAIL, SKIP, ERROR
emit_test_case() {
    local vector_id="$1"
    local description="$2"
    local feat="$3"
    local spec="$4"
    local status="$5"
    local duration_ms="$6"
    local error_msg="${7:-}"
    local output="${8:-}"
    local ts span_id
    ts="$(_now_unix_ms)"
    span_id="$(_generate_span_id)"

    local json_args=(
        --arg type "test_case"
        --arg trace_id "$_EMIT_TRACE_ID"
        --arg span_id "$span_id"
        --arg vector_id "$vector_id"
        --arg description "$description"
        --arg feat "$feat"
        --arg spec "$spec"
        --arg status "$status"
        --argjson duration_ms "$duration_ms"
        --argjson timestamp_unix_ms "$ts"
    )

    local jq_filter='{
        type: $type,
        trace_id: $trace_id,
        span_id: $span_id,
        vector_id: $vector_id,
        description: $description,
        feat: $feat,
        spec: $spec,
        status: $status,
        duration_ms: $duration_ms,
        timestamp_unix_ms: $timestamp_unix_ms
    }'

    # Add optional error field
    if [[ -n "$error_msg" ]]; then
        json_args+=( --arg error "$error_msg" )
        jq_filter='{
            type: $type,
            trace_id: $trace_id,
            span_id: $span_id,
            vector_id: $vector_id,
            description: $description,
            feat: $feat,
            spec: $spec,
            status: $status,
            duration_ms: $duration_ms,
            timestamp_unix_ms: $timestamp_unix_ms,
            error: $error
        }'
    fi

    # Add optional output field
    if [[ -n "$output" ]]; then
        json_args+=( --arg output "$output" )
        jq_filter='{
            type: $type,
            trace_id: $trace_id,
            span_id: $span_id,
            vector_id: $vector_id,
            description: $description,
            feat: $feat,
            spec: $spec,
            status: $status,
            duration_ms: $duration_ms,
            timestamp_unix_ms: $timestamp_unix_ms,
            error: $error,
            output: $output
        }'
        # If we have output but no error, need a different filter
        if [[ -z "$error_msg" ]]; then
            jq_filter='{
                type: $type,
                trace_id: $trace_id,
                span_id: $span_id,
                vector_id: $vector_id,
                description: $description,
                feat: $feat,
                spec: $spec,
                status: $status,
                duration_ms: $duration_ms,
                timestamp_unix_ms: $timestamp_unix_ms,
                output: $output
            }'
        fi
    fi

    jq -n -c "${json_args[@]}" "$jq_filter" >&7
}

# emit_coverage_record FEAT SPEC METHODS_COVERED METHODS_TOTAL LINES_COVERED LINES_TOTAL
emit_coverage_record() {
    local feat="$1"
    local spec="$2"
    local methods_covered="$3"
    local methods_total="$4"
    local lines_covered="$5"
    local lines_total="$6"

    jq -n -c \
        --arg type "coverage_record" \
        --arg trace_id "$_EMIT_TRACE_ID" \
        --arg feat "$feat" \
        --arg spec "$spec" \
        --argjson methods_covered "$methods_covered" \
        --argjson methods_total "$methods_total" \
        --argjson lines_covered "$lines_covered" \
        --argjson lines_total "$lines_total" \
        '{
            type: $type,
            trace_id: $trace_id,
            feat: $feat,
            spec: $spec,
            methods_covered: $methods_covered,
            methods_total: $methods_total,
            lines_covered: $lines_covered,
            lines_total: $lines_total
        }' >&7
}

# emit_suite_finished SUITE_NAME TESTS_RUN TESTS_PASSED TESTS_FAILED TESTS_SKIPPED TOTAL_DURATION_MS
emit_suite_finished() {
    local suite_name="$1"
    local tests_run="$2"
    local tests_passed="$3"
    local tests_failed="$4"
    local tests_skipped="$5"
    local total_duration_ms="$6"
    local ts
    ts="$(_now_unix_ms)"

    jq -n -c \
        --arg type "suite_finished" \
        --arg trace_id "$_EMIT_TRACE_ID" \
        --arg suite_name "$suite_name" \
        --argjson timestamp_unix_ms "$ts" \
        --argjson tests_run "$tests_run" \
        --argjson tests_passed "$tests_passed" \
        --argjson tests_failed "$tests_failed" \
        --argjson tests_skipped "$tests_skipped" \
        --argjson total_duration_ms "$total_duration_ms" \
        '{
            type: $type,
            trace_id: $trace_id,
            suite_name: $suite_name,
            timestamp_unix_ms: $timestamp_unix_ms,
            tests_run: $tests_run,
            tests_passed: $tests_passed,
            tests_failed: $tests_failed,
            tests_skipped: $tests_skipped,
            total_duration_ms: $total_duration_ms
        }' >&7
}

# ==============================================================================
# RUN METADATA
# ==============================================================================

# emit_run_metadata BATS_VERSION HARNESS_VERSION SCOPE FILTERS TEST_COUNT EXIT_CODE
#   Writes _run-metadata.json (not JSONL -- this is a standalone JSON file).
#   Aggregates test results and coverage from streaming.jsonl for trending.
emit_run_metadata() {
    local bats_version="$1"
    local harness_version="$2"
    local scope="$3"
    local filters="$4"
    local test_count="$5"
    local exit_code="$6"

    # Aggregate stats from streaming.jsonl if it exists
    local tests_total=0 tests_passed=0 tests_failed=0 tests_skipped=0
    local total_duration_ms=0 suites_count=0
    local methods_covered=0 methods_total=0 coverage_pct=0

    if [[ -f "${_EMIT_JSONL_PATH}" ]] && command -v jq &>/dev/null; then
        # Count tests by status from test_case records
        tests_total=$(jq -r 'select(.type=="test_case") | .status' "$_EMIT_JSONL_PATH" | wc -l)
        tests_passed=$(jq -r 'select(.type=="test_case") | select(.status=="PASS") | .status' "$_EMIT_JSONL_PATH" | wc -l)
        tests_failed=$(jq -r 'select(.type=="test_case") | select(.status=="FAIL" or .status=="ERROR") | .status' "$_EMIT_JSONL_PATH" | wc -l)
        tests_skipped=$(jq -r 'select(.type=="test_case") | select(.status=="SKIP") | .status' "$_EMIT_JSONL_PATH" | wc -l)

        # Sum duration from suite_finished records
        total_duration_ms=$(jq -s '[.[] | select(.type=="suite_finished") | .total_duration_ms] | add // 0' "$_EMIT_JSONL_PATH")

        # Count suites
        suites_count=$(jq -r 'select(.type=="suite_started") | .suite_name' "$_EMIT_JSONL_PATH" | wc -l)

        # Aggregate coverage from coverage_record records
        methods_covered=$(jq -s '[.[] | select(.type=="coverage_record") | .methods_covered] | add // 0' "$_EMIT_JSONL_PATH")
        methods_total=$(jq -s '[.[] | select(.type=="coverage_record") | .methods_total] | add // 0' "$_EMIT_JSONL_PATH")

        if [[ "$methods_total" -gt 0 ]]; then
            # Integer percentage * 10 for one decimal place
            coverage_pct=$(( (methods_covered * 1000) / methods_total ))
        fi
    fi

    # Format coverage as float string "89.8"
    local cov_int=$(( coverage_pct / 10 ))
    local cov_frac=$(( coverage_pct % 10 ))
    local coverage_pct_str="${cov_int}.${cov_frac}"

    jq -n \
        --arg bats_version "$bats_version" \
        --arg harness_version "$harness_version" \
        --arg scope "$scope" \
        --arg filters "$filters" \
        --argjson test_file_count "$test_count" \
        --argjson exit_code "$exit_code" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)" \
        --arg hostname "$(hostname -s 2>/dev/null || echo 'unknown')" \
        --arg trace_id "$_EMIT_TRACE_ID" \
        --arg run_dir "$_EMIT_RUN_DIR" \
        --argjson tests_total "$tests_total" \
        --argjson tests_passed "$tests_passed" \
        --argjson tests_failed "$tests_failed" \
        --argjson tests_skipped "$tests_skipped" \
        --argjson total_duration_ms "$total_duration_ms" \
        --argjson suites_count "$suites_count" \
        --argjson methods_covered "$methods_covered" \
        --argjson methods_total "$methods_total" \
        --arg coverage_pct "$coverage_pct_str" \
        '{
            timestamp: $timestamp,
            hostname: $hostname,
            trace_id: $trace_id,
            bats_version: $bats_version,
            harness_version: $harness_version,
            scope: $scope,
            filters: $filters,
            test_file_count: $test_file_count,
            exit_code: $exit_code,
            run_dir: $run_dir,
            tests_total: $tests_total,
            tests_passed: $tests_passed,
            tests_failed: $tests_failed,
            tests_skipped: $tests_skipped,
            total_duration_ms: $total_duration_ms,
            suites_count: $suites_count,
            methods_covered: $methods_covered,
            methods_total: $methods_total,
            coverage_pct: $coverage_pct
        }' > "${_EMIT_RUN_DIR}/_run-metadata.json"
}
