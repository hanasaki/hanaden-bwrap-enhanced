#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- jsonl-to-junit-xml.sh -- Hanaden AI
# ==============================================================================
# NAME:      jsonl-to-junit-xml.sh
# VERSION:   0.1.0
# PURPOSE:   Convert JSONL streaming records to standard JUnit XML.
#
# USAGE:     jsonl-to-junit-xml.sh <input.jsonl> [output-junit.xml]
#            If output is omitted, writes to <input-dir>/junit.xml
#
# DEPENDENCIES: python3 (stdlib only), jq (validation)
# ==============================================================================
set -euo pipefail

readonly _SCRIPT_NAME="$(basename "$0")"

if [[ $# -lt 1 ]]; then
    printf 'Usage: %s <input.jsonl> [output-junit.xml]\n' "$_SCRIPT_NAME" >&2
    exit 1
fi

readonly INPUT_JSONL="$1"

if [[ ! -f "$INPUT_JSONL" ]]; then
    printf '[ERROR] %s: JSONL file not found: %s\n' "$_SCRIPT_NAME" "$INPUT_JSONL" >&2
    exit 2
fi

# Default output: same directory as input, named junit.xml
readonly INPUT_DIR="$(dirname "$INPUT_JSONL")"
readonly OUTPUT_XML="${2:-${INPUT_DIR}/junit.xml}"

# Validate JSONL (each line must be valid JSON)
if ! jq -e . "$INPUT_JSONL" > /dev/null 2>&1; then
    printf '[ERROR] %s: JSONL validation failed: %s\n' "$_SCRIPT_NAME" "$INPUT_JSONL" >&2
    exit 2
fi

python3 -c "
import json
import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom
from collections import OrderedDict

input_path = '$INPUT_JSONL'
output_path = '$OUTPUT_XML'

# Parse JSONL records
records = []
with open(input_path, 'r') as f:
    for line_num, line in enumerate(f, 1):
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as e:
            print(f'[ERROR] JSONL parse error at line {line_num}: {e}', file=sys.stderr)
            sys.exit(2)

# Group test_case records by suite (feat/spec)
suites = OrderedDict()  # key: suite_name, value: {test_cases: [], metadata: {}}
suite_metadata = {}  # from suite_started/suite_finished records

for rec in records:
    rtype = rec.get('type', '')

    if rtype == 'suite_started':
        name = rec.get('suite_name', 'unknown')
        suite_metadata.setdefault(name, {})['started'] = rec

    elif rtype == 'test_case':
        feat = rec.get('feat', 'unknown')
        spec = rec.get('spec', 'unknown')
        suite_key = f'{feat}/{spec}'
        suites.setdefault(suite_key, []).append(rec)

    elif rtype == 'suite_finished':
        name = rec.get('suite_name', 'unknown')
        suite_metadata.setdefault(name, {})['finished'] = rec

# Build JUnit XML
root = ET.Element('testsuites')
root.set('name', 'bwrap-enhanced')

total_tests = 0
total_failures = 0
total_errors = 0
total_skipped = 0
total_time = 0.0

for suite_key, test_cases in suites.items():
    suite_el = ET.SubElement(root, 'testsuite')
    suite_el.set('name', suite_key)

    s_tests = len(test_cases)
    s_failures = sum(1 for tc in test_cases if tc.get('status') == 'FAIL')
    s_errors = sum(1 for tc in test_cases if tc.get('status') == 'ERROR')
    s_skipped = sum(1 for tc in test_cases if tc.get('status') == 'SKIP')
    s_time = sum(tc.get('duration_ms', 0) for tc in test_cases) / 1000.0

    suite_el.set('tests', str(s_tests))
    suite_el.set('failures', str(s_failures))
    suite_el.set('errors', str(s_errors))
    suite_el.set('skipped', str(s_skipped))
    suite_el.set('time', f'{s_time:.3f}')

    # Timestamp from first test case
    if test_cases:
        first_ts = test_cases[0].get('timestamp_unix_ms', 0)
        from datetime import datetime, timezone
        dt = datetime.fromtimestamp(first_ts / 1000.0, tz=timezone.utc)
        suite_el.set('timestamp', dt.strftime('%Y-%m-%dT%H:%M:%S'))

    import socket
    suite_el.set('hostname', socket.gethostname())

    for tc in test_cases:
        tc_el = ET.SubElement(suite_el, 'testcase')
        tc_el.set('name', tc.get('description', tc.get('vector_id', '')))
        tc_el.set('classname', f\"{tc.get('feat', '')}.{tc.get('spec', '')}\")
        tc_el.set('time', f\"{tc.get('duration_ms', 0) / 1000.0:.3f}\")

        status = tc.get('status', 'PASS')
        if status == 'FAIL':
            fail_el = ET.SubElement(tc_el, 'failure')
            fail_el.set('message', tc.get('error', 'Test failed'))
            fail_el.set('type', 'AssertionError')
            if tc.get('output'):
                fail_el.text = tc['output']
        elif status == 'ERROR':
            err_el = ET.SubElement(tc_el, 'error')
            err_el.set('message', tc.get('error', 'Test error'))
            err_el.set('type', 'Error')
            if tc.get('output'):
                err_el.text = tc['output']
        elif status == 'SKIP':
            skip_el = ET.SubElement(tc_el, 'skipped')
            if tc.get('error'):
                skip_el.set('message', tc['error'])

        # system-out
        if tc.get('output') and status == 'PASS':
            sysout = ET.SubElement(tc_el, 'system-out')
            sysout.text = tc['output']

    total_tests += s_tests
    total_failures += s_failures
    total_errors += s_errors
    total_skipped += s_skipped
    total_time += s_time

root.set('tests', str(total_tests))
root.set('failures', str(total_failures))
root.set('errors', str(total_errors))
root.set('skipped', str(total_skipped))
root.set('time', f'{total_time:.3f}')

# Pretty-print the XML
xml_str = ET.tostring(root, encoding='unicode', xml_declaration=False)
dom = minidom.parseString(xml_str)
pretty_xml = dom.toprettyxml(indent='  ', encoding='UTF-8').decode('utf-8')

with open(output_path, 'w') as f:
    f.write(pretty_xml)

print(f'[INFO] JUnit XML written: {output_path}', file=sys.stderr)
"

exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    printf '[ERROR] %s: conversion failed with exit code %d\n' "$_SCRIPT_NAME" "$exit_code" >&2
    exit "$exit_code"
fi
