#!/usr/bin/env bash
# (c) 2026-* Frederick Bloom -- jsonl-to-jacoco-xml.sh -- Hanaden AI
# ==============================================================================
# NAME:      jsonl-to-jacoco-xml.sh
# VERSION:   0.1.0
# PURPOSE:   Convert JSONL streaming records to JaCoCo-compatible XML.
#            Uses timing-as-coverage mapping:
#              .feat -> <package>, .spec -> <class>, @test -> <method>
#
# USAGE:     jsonl-to-jacoco-xml.sh <input.jsonl> [output-jacoco.xml]
#            If output is omitted, writes to <input-dir>/jacoco.xml
#
# DEPENDENCIES: python3 (stdlib only), jq (validation)
# ==============================================================================
set -euo pipefail

readonly _SCRIPT_NAME="$(basename "$0")"

if [[ $# -lt 1 ]]; then
    printf 'Usage: %s <input.jsonl> [output-jacoco.xml]\n' "$_SCRIPT_NAME" >&2
    exit 1
fi

readonly INPUT_JSONL="$1"

if [[ ! -f "$INPUT_JSONL" ]]; then
    printf '[ERROR] %s: JSONL file not found: %s\n' "$_SCRIPT_NAME" "$INPUT_JSONL" >&2
    exit 2
fi

readonly INPUT_DIR="$(dirname "$INPUT_JSONL")"
readonly OUTPUT_XML="${2:-${INPUT_DIR}/jacoco.xml}"

# Validate JSONL
if ! jq -e . "$INPUT_JSONL" > /dev/null 2>&1; then
    printf '[ERROR] %s: JSONL validation failed: %s\n' "$_SCRIPT_NAME" "$INPUT_JSONL" >&2
    exit 2
fi

python3 -c "
import json
import sys
from collections import OrderedDict
from xml.dom import minidom
import xml.etree.ElementTree as ET

input_path = '$INPUT_JSONL'
output_path = '$OUTPUT_XML'

# Parse JSONL
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

# Extract session info from first/last records
session_start = 0
session_end = 0
for rec in records:
    ts = rec.get('timestamp_unix_ms', 0)
    if ts:
        if session_start == 0 or ts < session_start:
            session_start = ts
        if ts > session_end:
            session_end = ts

trace_id = ''
for rec in records:
    if rec.get('trace_id'):
        trace_id = rec['trace_id']
        break

# Group test_cases by feat (package) -> spec (class)
# Structure: packages[feat][spec] = [test_case_records...]
packages = OrderedDict()
coverage_records = {}  # key: (feat, spec)

for rec in records:
    rtype = rec.get('type', '')

    if rtype == 'test_case':
        feat = rec.get('feat', 'unknown')
        spec = rec.get('spec', 'unknown')
        packages.setdefault(feat, OrderedDict()).setdefault(spec, []).append(rec)

    elif rtype == 'coverage_record':
        feat = rec.get('feat', 'unknown')
        spec = rec.get('spec', 'unknown')
        coverage_records[(feat, spec)] = rec

# Build JaCoCo XML
report = ET.Element('report')
report.set('name', 'bwrap-enhanced Test Coverage')

# Session info
session = ET.SubElement(report, 'sessioninfo')
session.set('id', f'run-{trace_id[:16]}' if trace_id else 'run-unknown')
session.set('start', str(session_start))
session.set('dump', str(session_end))

# Aggregate counters for the whole report
total_methods_covered = 0
total_methods_missed = 0
total_classes_covered = 0
total_classes_missed = 0
total_lines_covered = 0
total_lines_missed = 0

for feat, specs in packages.items():
    pkg_el = ET.SubElement(report, 'package')
    pkg_el.set('name', feat)

    pkg_methods_covered = 0
    pkg_methods_missed = 0
    pkg_classes_covered = 0
    pkg_classes_missed = 0
    pkg_lines_covered = 0
    pkg_lines_missed = 0

    for spec, test_cases in specs.items():
        # <class>
        class_el = ET.SubElement(pkg_el, 'class')
        class_el.set('name', f'{feat}.{spec}')
        # Source file: derive from spec name
        source_filename = f'test_{spec.lower()}.bats'
        # Try to get a more accurate filename from test_case paths if available
        class_el.set('sourcefilename', source_filename)

        cls_methods_covered = 0
        cls_methods_missed = 0
        line_num = 10  # Starting line number (approximate)

        for tc in test_cases:
            # <method>
            method_el = ET.SubElement(class_el, 'method')
            method_el.set('name', tc.get('vector_id', 'unknown'))
            method_el.set('desc', '()')
            method_el.set('line', str(line_num))
            line_num += 8  # Approximate lines per test

            status = tc.get('status', 'PASS')
            if status == 'PASS':
                m_covered = 1
                m_missed = 0
                cls_methods_covered += 1
            else:
                m_covered = 0
                m_missed = 1
                cls_methods_missed += 1

            counter = ET.SubElement(method_el, 'counter')
            counter.set('type', 'METHOD')
            counter.set('missed', str(m_missed))
            counter.set('covered', str(m_covered))

        # Class-level counters
        c_method = ET.SubElement(class_el, 'counter')
        c_method.set('type', 'METHOD')
        c_method.set('missed', str(cls_methods_missed))
        c_method.set('covered', str(cls_methods_covered))

        # Class covered if any method covered
        cls_covered = 1 if cls_methods_covered > 0 else 0
        cls_missed = 1 if cls_covered == 0 else 0

        c_class = ET.SubElement(class_el, 'counter')
        c_class.set('type', 'CLASS')
        c_class.set('missed', str(cls_missed))
        c_class.set('covered', str(cls_covered))

        # <sourcefile>
        sf_el = ET.SubElement(pkg_el, 'sourcefile')
        sf_el.set('name', source_filename)

        # Line counters from coverage_record if available, else derive
        cov_rec = coverage_records.get((feat, spec), {})
        sf_lines_covered = cov_rec.get('lines_covered', cls_methods_covered * 8)
        sf_lines_total = cov_rec.get('lines_total', len(test_cases) * 8)
        sf_lines_missed = sf_lines_total - sf_lines_covered

        sf_line_counter = ET.SubElement(sf_el, 'counter')
        sf_line_counter.set('type', 'LINE')
        sf_line_counter.set('missed', str(sf_lines_missed))
        sf_line_counter.set('covered', str(sf_lines_covered))

        sf_method_counter = ET.SubElement(sf_el, 'counter')
        sf_method_counter.set('type', 'METHOD')
        sf_method_counter.set('missed', str(cls_methods_missed))
        sf_method_counter.set('covered', str(cls_methods_covered))

        # Accumulate package totals
        pkg_methods_covered += cls_methods_covered
        pkg_methods_missed += cls_methods_missed
        pkg_classes_covered += cls_covered
        pkg_classes_missed += cls_missed
        pkg_lines_covered += sf_lines_covered
        pkg_lines_missed += sf_lines_missed

    # Package-level counters
    p_line = ET.SubElement(pkg_el, 'counter')
    p_line.set('type', 'LINE')
    p_line.set('missed', str(pkg_lines_missed))
    p_line.set('covered', str(pkg_lines_covered))

    p_method = ET.SubElement(pkg_el, 'counter')
    p_method.set('type', 'METHOD')
    p_method.set('missed', str(pkg_methods_missed))
    p_method.set('covered', str(pkg_methods_covered))

    p_class = ET.SubElement(pkg_el, 'counter')
    p_class.set('type', 'CLASS')
    p_class.set('missed', str(pkg_classes_missed))
    p_class.set('covered', str(pkg_classes_covered))

    # Accumulate report totals
    total_methods_covered += pkg_methods_covered
    total_methods_missed += pkg_methods_missed
    total_classes_covered += pkg_classes_covered
    total_classes_missed += pkg_classes_missed
    total_lines_covered += pkg_lines_covered
    total_lines_missed += pkg_lines_missed

# Report-level counters
r_line = ET.SubElement(report, 'counter')
r_line.set('type', 'LINE')
r_line.set('missed', str(total_lines_missed))
r_line.set('covered', str(total_lines_covered))

r_method = ET.SubElement(report, 'counter')
r_method.set('type', 'METHOD')
r_method.set('missed', str(total_methods_missed))
r_method.set('covered', str(total_methods_covered))

r_class = ET.SubElement(report, 'counter')
r_class.set('type', 'CLASS')
r_class.set('missed', str(total_classes_missed))
r_class.set('covered', str(total_classes_covered))

# Pretty-print with DOCTYPE
xml_str = ET.tostring(report, encoding='unicode', xml_declaration=False)
dom = minidom.parseString(xml_str)

# Build output with JaCoCo DOCTYPE
output_lines = []
output_lines.append('<?xml version=\"1.0\" encoding=\"UTF-8\"?>')
output_lines.append('<!DOCTYPE report PUBLIC \"-//JACOCO//DTD Report 1.1//EN\" \"report.dtd\">')
# Get the pretty-printed body (skip the xml declaration minidom adds)
body = dom.toprettyxml(indent='  ')
for line in body.split('\n'):
    if line.strip().startswith('<?xml'):
        continue
    output_lines.append(line)

with open(output_path, 'w') as f:
    f.write('\n'.join(output_lines))

print(f'[INFO] JaCoCo XML written: {output_path}', file=sys.stderr)
"

exit_code=$?
if [[ $exit_code -ne 0 ]]; then
    printf '[ERROR] %s: conversion failed with exit code %d\n' "$_SCRIPT_NAME" "$exit_code" >&2
    exit "$exit_code"
fi
