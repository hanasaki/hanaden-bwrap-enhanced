#!/usr/bin/env python3
# (c) 2026-* Frederick Bloom -- junit_html_report.py -- Hanaden AI
# ==============================================================================
# NAME:      junit_html_report.py
# VERSION:   0.1.0
# PURPOSE:   Generate a self-contained HTML site from JUnit XML.
#
# USAGE:     python3 junit_html_report.py --input <junit.xml> --output <dir>
#
# OUTPUT:    <dir>/
#              index.html              — Dashboard: pass/fail/skip, timing, suite table
#              suites/<Feat>-<Spec>.html — Per-suite test case details
#
# DEPENDENCIES: Python 3.14+ stdlib only (xml.etree, html, argparse, os)
# ==============================================================================
"""JUnit XML → HTML site generator with Hanaden dark theme."""

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from html import escape

# Import shared design system
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _html_templates import (
    html_page,
    status_badge,
    progress_bar,
    timing_bar,
    stat_card,
    format_duration,
    health_badge,
    svg_timing_histogram,
)


def parse_junit_xml(xml_path):
    """Parse JUnit XML file into structured data.

    Returns:
        dict with keys: suites (list), totals (dict)
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    suites = []

    # Handle <testsuites> or standalone <testsuite>
    if root.tag == "testsuites":
        suite_elements = root.findall("testsuite")
    elif root.tag == "testsuite":
        suite_elements = [root]
    else:
        print(f"[ERROR] Unexpected root element: {root.tag}", file=sys.stderr)
        sys.exit(2)

    for suite_el in suite_elements:
        suite = {
            "name": suite_el.get("name", "unknown"),
            "tests": int(suite_el.get("tests", "0")),
            "failures": int(suite_el.get("failures", "0")),
            "errors": int(suite_el.get("errors", "0")),
            "skipped": int(suite_el.get("skipped", "0")),
            "time": float(suite_el.get("time", "0")),
            "timestamp": suite_el.get("timestamp", ""),
            "test_cases": [],
        }
        suite["passed"] = (
            suite["tests"] - suite["failures"] - suite["errors"] - suite["skipped"]
        )

        for tc_el in suite_el.findall("testcase"):
            tc = {
                "name": tc_el.get("name", ""),
                "classname": tc_el.get("classname", ""),
                "time": float(tc_el.get("time", "0")),
                "time_ms": int(float(tc_el.get("time", "0")) * 1000),
                "status": "PASS",
                "error_message": "",
                "error_output": "",
            }

            failure = tc_el.find("failure")
            error = tc_el.find("error")
            skipped = tc_el.find("skipped")

            if failure is not None:
                tc["status"] = "FAIL"
                tc["error_message"] = failure.get("message", "")
                tc["error_output"] = failure.text or ""
            elif error is not None:
                tc["status"] = "ERROR"
                tc["error_message"] = error.get("message", "")
                tc["error_output"] = error.text or ""
            elif skipped is not None:
                tc["status"] = "SKIP"
                tc["error_message"] = skipped.get("message", "")

            # system-out
            sysout = tc_el.find("system-out")
            if sysout is not None and sysout.text:
                tc["error_output"] = tc.get("error_output", "") + sysout.text

            suite["test_cases"].append(tc)

        suites.append(suite)

    # Compute totals
    totals = {
        "tests": sum(s["tests"] for s in suites),
        "passed": sum(s["passed"] for s in suites),
        "failures": sum(s["failures"] for s in suites),
        "errors": sum(s["errors"] for s in suites),
        "skipped": sum(s["skipped"] for s in suites),
        "time": sum(s["time"] for s in suites),
        "suites": len(suites),
    }

    return {"suites": suites, "totals": totals}


def suite_filename(suite_name):
    """Convert suite name to a safe filename."""
    return suite_name.replace("/", "-").replace(".", "-").replace(" ", "_") + ".html"


def generate_dashboard(data, suites_dir_name="suites"):
    """Generate the dashboard index.html content."""
    totals = data["totals"]
    suites = data["suites"]

    # Stats grid
    stats = "".join(
        [
            stat_card(totals["tests"], "Total Tests", "total"),
            stat_card(totals["passed"], "Passed", "pass"),
            stat_card(totals["failures"], "Failed", "fail"),
            stat_card(totals["skipped"], "Skipped", "skip"),
            stat_card(totals["errors"], "Errors", "error"),
            stat_card(format_duration(int(totals["time"] * 1000)), "Duration", "time"),
        ]
    )

    # Health badge
    hb = health_badge(totals["passed"], totals["tests"], totals["failures"])

    # Timing histogram
    all_durations = []
    for s in suites:
        for tc in s["test_cases"]:
            all_durations.append(tc["time_ms"])
    histogram = svg_timing_histogram(all_durations)

    # Suite table
    suite_rows = ""
    for s in suites:
        fname = suite_filename(s["name"])
        status_class = "pass" if s["failures"] == 0 and s["errors"] == 0 else "fail"
        pbar = progress_bar(s["passed"], s["tests"])
        suite_rows += f"""<tr>
<td><a href="{suites_dir_name}/{fname}">{escape(s['name'])}</a></td>
<td class="align-right" data-sort-value="{s['tests']}">{s['tests']}</td>
<td class="align-right" data-sort-value="{s['passed']}">{s['passed']}</td>
<td class="align-right" data-sort-value="{s['failures']}">{s['failures']}</td>
<td class="align-right" data-sort-value="{s['skipped']}">{s['skipped']}</td>
<td class="align-right mono" data-sort-value="{s['time']}">{format_duration(int(s['time'] * 1000))}</td>
<td>{pbar}</td>
</tr>"""

    # Slowest 10 tests
    all_tests = []
    for s in suites:
        for tc in s["test_cases"]:
            all_tests.append({"suite": s["name"], **tc})
    all_tests.sort(key=lambda t: t["time_ms"], reverse=True)
    slowest = all_tests[:10]

    max_time = slowest[0]["time_ms"] if slowest else 1
    slowest_rows = ""
    for tc in slowest:
        tb = timing_bar(tc["time_ms"], max_time)
        slowest_rows += f"""<tr>
<td class="mono">{escape(tc['name'][:60])}</td>
<td>{escape(tc['suite'])}</td>
<td>{status_badge(tc['status'])}</td>
<td class="align-right mono" data-sort-value="{tc['time_ms']}">{format_duration(tc['time_ms'])}</td>
<td>{tb}</td>
</tr>"""

    # Failures section
    failures_html = ""
    failed_tests = [t for t in all_tests if t["status"] in ("FAIL", "ERROR")]
    if failed_tests:
        failure_items = ""
        for tc in failed_tests:
            badge = status_badge(tc["status"])
            output = (
                f'<div class="details-content"><pre class="error-output">{escape(tc["error_output"])}</pre></div>'
                if tc["error_output"]
                else ""
            )
            failure_items += f"""<details>
<summary>{badge} {escape(tc['name'])} — {escape(tc.get('error_message', ''))}</summary>
{output}
</details>"""
        failures_html = f"""<div class="card">
<div class="card-title">⚠ Failures & Errors ({len(failed_tests)})</div>
{failure_items}
</div>"""

    body = f"""
{hb}
<div class="stats-grid">{stats}</div>

<div class="card">
  <div class="card-title">Timing Distribution</div>
  {histogram}
</div>

<div class="card">
  <div class="card-title">Test Suites ({totals['suites']})</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Suite</th><th>Tests</th><th>Passed</th><th>Failed</th>
      <th>Skipped</th><th>Time</th><th>Pass Rate</th>
    </tr></thead>
    <tbody>{suite_rows}</tbody>
  </table>
  </div>
</div>

<div class="card">
  <div class="card-title">Slowest Tests (Top 10)</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Test</th><th>Suite</th><th>Status</th><th>Time</th><th></th>
    </tr></thead>
    <tbody>{slowest_rows}</tbody>
  </table>
  </div>
</div>

{failures_html}
"""
    return html_page("Test Results", body, breadcrumbs=[("Test Results", None)])


def generate_suite_page(suite, suites_dir_name="suites"):
    """Generate a per-suite detail page."""
    test_cases = suite["test_cases"]
    max_time = max((tc["time_ms"] for tc in test_cases), default=1)

    stats = "".join(
        [
            stat_card(suite["tests"], "Tests", "total"),
            stat_card(suite["passed"], "Passed", "pass"),
            stat_card(suite["failures"], "Failed", "fail"),
            stat_card(suite["skipped"], "Skipped", "skip"),
            stat_card(
                format_duration(int(suite["time"] * 1000)), "Duration", "time"
            ),
        ]
    )

    rows = ""
    for tc in test_cases:
        tb = timing_bar(tc["time_ms"], max_time)
        rows += f"""<tr>
<td>{status_badge(tc['status'])}</td>
<td>{escape(tc['name'])}</td>
<td class="mono">{escape(tc['classname'])}</td>
<td class="align-right mono" data-sort-value="{tc['time_ms']}">{format_duration(tc['time_ms'])}</td>
<td>{tb}</td>
</tr>"""

    # Error details
    errors_html = ""
    failed = [tc for tc in test_cases if tc["status"] in ("FAIL", "ERROR")]
    if failed:
        items = ""
        for tc in failed:
            output = (
                f'<div class="details-content"><pre class="error-output">{escape(tc["error_output"])}</pre></div>'
                if tc["error_output"]
                else ""
            )
            items += f"""<details>
<summary>{status_badge(tc['status'])} {escape(tc['name'])} — {escape(tc['error_message'])}</summary>
{output}
</details>"""
        errors_html = f"""<div class="card">
<div class="card-title">Failures ({len(failed)})</div>
{items}
</div>"""

    body = f"""
<div class="stats-grid">{stats}</div>

<div class="card">
  <div class="card-title">Test Cases ({suite['tests']})</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Status</th><th>Test</th><th>Class</th><th>Time</th><th></th>
    </tr></thead>
    <tbody>{rows}</tbody>
  </table>
  </div>
</div>

{errors_html}
"""
    breadcrumbs = [("Test Results", "../index.html"), (suite["name"], None)]
    return html_page(suite["name"], body, breadcrumbs=breadcrumbs)


def main():
    parser = argparse.ArgumentParser(
        description="Generate HTML report site from JUnit XML"
    )
    parser.add_argument(
        "--input", required=True, help="Path to JUnit XML file"
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output directory (default: <input-dir>/html-junit/)",
    )
    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"[ERROR] JUnit XML not found: {args.input}", file=sys.stderr)
        sys.exit(2)

    # Default output: sibling html-junit/ directory
    output_dir = args.output or os.path.join(
        os.path.dirname(args.input), "html-junit"
    )
    suites_dir = os.path.join(output_dir, "suites")
    os.makedirs(suites_dir, exist_ok=True)

    # Parse
    data = parse_junit_xml(args.input)

    # Generate dashboard
    dashboard_html = generate_dashboard(data)
    with open(os.path.join(output_dir, "index.html"), "w") as f:
        f.write(dashboard_html)

    # Generate per-suite pages
    for suite in data["suites"]:
        fname = suite_filename(suite["name"])
        page_html = generate_suite_page(suite)
        with open(os.path.join(suites_dir, fname), "w") as f:
            f.write(page_html)

    print(
        f"[INFO] JUnit HTML report written: {output_dir}/ "
        f"({len(data['suites'])} suites, {data['totals']['tests']} tests)",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
