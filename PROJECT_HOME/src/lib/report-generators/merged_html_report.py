#!/usr/bin/env python3
# (c) 2026-* Frederick Bloom -- merged_html_report.py -- Hanaden AI
# ==============================================================================
# NAME:      merged_html_report.py
# VERSION:   0.1.0
# PURPOSE:   Generate a single self-contained HTML site that adapts to
#            available inputs: JUnit-only, JaCoCo-only, or both merged.
#
# USAGE:     python3 merged_html_report.py [--junit XML] [--jacoco XML] --output DIR
#            At least one of --junit or --jacoco is required.
#
# OUTPUT:    <dir>/
#              index.html              — Adaptive dashboard
#              suites/<Name>.html      — Per-suite test details (if junit)
#              packages/<Name>.html    — Per-package coverage (if jacoco)
#              classes/<Name>.html     — Per-class methods (if jacoco)
#
# DEPENDENCIES: Python 3.14+ stdlib only
# ==============================================================================
"""Single adaptive HTML site generator — always one output, merges what's available."""

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from html import escape
from datetime import datetime, timezone
import socket

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


# ==============================================================================
# JUnit XML Parser
# ==============================================================================

def parse_junit_xml(xml_path):
    """Parse JUnit XML file into structured data."""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    suites = []
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

            sysout = tc_el.find("system-out")
            if sysout is not None and sysout.text:
                tc["error_output"] = tc.get("error_output", "") + sysout.text

            suite["test_cases"].append(tc)

        suites.append(suite)

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


# ==============================================================================
# JaCoCo XML Parser
# ==============================================================================

def parse_jacoco_xml(xml_path):
    """Parse JaCoCo XML into structured data."""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    if root.tag != "report":
        print(f"[ERROR] Expected <report> root, got <{root.tag}>", file=sys.stderr)
        sys.exit(2)

    report_name = root.get("name", "Coverage Report")

    session_el = root.find("sessioninfo")
    session = {}
    if session_el is not None:
        session = {
            "id": session_el.get("id", ""),
            "start": int(session_el.get("start", "0")),
            "dump": int(session_el.get("dump", "0")),
        }

    report_counters = _parse_counters(root)

    packages = []
    for pkg_el in root.findall("package"):
        pkg = {
            "name": pkg_el.get("name", "unknown"),
            "counters": _parse_counters(pkg_el),
            "classes": [],
            "sourcefiles": [],
        }

        for cls_el in pkg_el.findall("class"):
            cls = {
                "name": cls_el.get("name", "unknown"),
                "sourcefilename": cls_el.get("sourcefilename", ""),
                "counters": _parse_counters(cls_el),
                "methods": [],
            }
            for method_el in cls_el.findall("method"):
                method = {
                    "name": method_el.get("name", "unknown"),
                    "desc": method_el.get("desc", ""),
                    "line": method_el.get("line", ""),
                    "counters": _parse_counters(method_el),
                }
                cls["methods"].append(method)
            pkg["classes"].append(cls)

        for sf_el in pkg_el.findall("sourcefile"):
            sf = {
                "name": sf_el.get("name", "unknown"),
                "counters": _parse_counters(sf_el),
            }
            pkg["sourcefiles"].append(sf)

        packages.append(pkg)

    return {
        "name": report_name,
        "session": session,
        "counters": report_counters,
        "packages": packages,
    }


def _parse_counters(element):
    """Parse <counter> child elements into a dict keyed by type."""
    counters = {}
    for c in element.findall("counter"):
        ctype = c.get("type", "")
        counters[ctype] = {
            "missed": int(c.get("missed", "0")),
            "covered": int(c.get("covered", "0")),
        }
    return counters


def _counter_total(counter):
    return counter.get("missed", 0) + counter.get("covered", 0)


def _counter_pct(counter):
    total = _counter_total(counter)
    if total == 0:
        return 0.0
    return (counter.get("covered", 0) / total) * 100


# ==============================================================================
# Filename Helpers
# ==============================================================================

def suite_filename(name):
    return name.replace("/", "-").replace(".", "-").replace(" ", "_") + ".html"

def pkg_filename(name):
    return name.replace("/", "-").replace(".", "-") + ".html"

def cls_filename(name):
    return name.replace("/", "-").replace(" ", "_") + ".html"


# ==============================================================================
# Dashboard — Adapts to Available Data
# ==============================================================================

def generate_dashboard(junit_data=None, jacoco_data=None):
    """Generate a merged dashboard that adapts to available inputs."""
    has_junit = junit_data is not None
    has_jacoco = jacoco_data is not None

    # Build navigation tabs
    tabs = []
    tabs.append(('Dashboard', 'index.html', True))
    if has_junit:
        tabs.append(('Test Results', '#test-results', False))
    if has_jacoco:
        tabs.append(('Coverage', '#coverage', False))
    tab_html = '<div class="tabs">'
    for label, href, active in tabs:
        cls = ' active' if active else ''
        tab_html += f'<a class="tab{cls}" href="{href}">{escape(label)}</a>'
    tab_html += '</div>'

    # Stats section — combine whatever is available
    stats_html = ""
    hb_html = ""

    if has_junit:
        j = junit_data["totals"]
        hb_html = health_badge(j["passed"], j["tests"], j["failures"])
        stats_html += stat_card(j["tests"], "Total Tests", "total")
        stats_html += stat_card(j["passed"], "Passed", "pass")
        stats_html += stat_card(j["failures"], "Failed", "fail")
        stats_html += stat_card(j["skipped"], "Skipped", "skip")
        stats_html += stat_card(format_duration(int(j["time"] * 1000)), "Duration", "time")

    if has_jacoco:
        c = jacoco_data["counters"]
        method_c = c.get("METHOD", {"missed": 0, "covered": 0})
        class_c = c.get("CLASS", {"missed": 0, "covered": 0})
        stats_html += stat_card(
            f"{_counter_pct(method_c):.1f}%",
            f"Method Coverage ({method_c['covered']}/{_counter_total(method_c)})",
            "pass" if _counter_pct(method_c) >= 80 else "fail",
        )
        stats_html += stat_card(
            f"{_counter_pct(class_c):.1f}%",
            f"Class Coverage ({class_c['covered']}/{_counter_total(class_c)})",
            "pass" if _counter_pct(class_c) >= 80 else "fail",
        )

    # Timing histogram (junit)
    histogram_html = ""
    if has_junit:
        all_durations = []
        for s in junit_data["suites"]:
            for tc in s["test_cases"]:
                all_durations.append(tc["time_ms"])
        histogram = svg_timing_histogram(all_durations)
        histogram_html = f"""<div class="card">
<div class="card-title">Timing Distribution</div>
{histogram}
</div>"""

    # Combined suite + coverage table (when both available)
    # or suite table (junit only) or package table (jacoco only)
    table_html = ""

    if has_junit and has_jacoco:
        # Merged view: each suite row shows test results + matching coverage
        pkg_by_name = {p["name"]: p for p in jacoco_data["packages"]}
        rows = ""
        for suite in junit_data["suites"]:
            sname = suite["name"]
            feat = sname.split("/")[0] if "/" in sname else sname
            pkg = pkg_by_name.get(feat, None)

            sfname = suite_filename(sname)
            test_pbar = progress_bar(suite["passed"], suite["tests"])

            cov_cell = '<span class="mono" style="color:var(--text-muted)">—</span>'
            if pkg:
                pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
                cov_cell = progress_bar(pm["covered"], _counter_total(pm))

            rows += f"""<tr>
<td><a href="suites/{sfname}">{escape(sname)}</a></td>
<td class="align-right" data-sort-value="{suite['tests']}">{suite['tests']}</td>
<td>{test_pbar}</td>
<td class="align-right mono" data-sort-value="{suite['time']}">{format_duration(int(suite['time'] * 1000))}</td>
<td>{cov_cell}</td>
</tr>"""

        table_html = f"""<div class="card">
<div class="card-title">Suites — Test Results + Coverage</div>
<div class="table-wrap">
<table data-sortable>
<thead><tr>
  <th>Suite</th><th>Tests</th><th>Pass Rate</th><th>Time</th><th>Coverage</th>
</tr></thead>
<tbody>{rows}</tbody>
</table>
</div>
</div>"""

    elif has_junit:
        # JUnit-only suite table
        rows = ""
        for s in junit_data["suites"]:
            sfname = suite_filename(s["name"])
            pbar = progress_bar(s["passed"], s["tests"])
            rows += f"""<tr>
<td><a href="suites/{sfname}">{escape(s['name'])}</a></td>
<td class="align-right" data-sort-value="{s['tests']}">{s['tests']}</td>
<td class="align-right" data-sort-value="{s['passed']}">{s['passed']}</td>
<td class="align-right" data-sort-value="{s['failures']}">{s['failures']}</td>
<td class="align-right" data-sort-value="{s['skipped']}">{s['skipped']}</td>
<td class="align-right mono" data-sort-value="{s['time']}">{format_duration(int(s['time'] * 1000))}</td>
<td>{pbar}</td>
</tr>"""

        table_html = f"""<div class="card" id="test-results">
<div class="card-title">Test Suites ({junit_data['totals']['suites']})</div>
<div class="table-wrap">
<table data-sortable>
<thead><tr>
  <th>Suite</th><th>Tests</th><th>Passed</th><th>Failed</th>
  <th>Skipped</th><th>Time</th><th>Pass Rate</th>
</tr></thead>
<tbody>{rows}</tbody>
</table>
</div>
</div>"""

    elif has_jacoco:
        # JaCoCo-only package table
        rows = ""
        for pkg in jacoco_data["packages"]:
            pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
            pc = pkg["counters"].get("CLASS", {"missed": 0, "covered": 0})
            pl = pkg["counters"].get("LINE", {"missed": 0, "covered": 0})
            fname = pkg_filename(pkg["name"])
            rows += f"""<tr>
<td><a href="packages/{fname}">{escape(pkg['name'])}</a></td>
<td class="align-right" data-sort-value="{_counter_pct(pm):.1f}">{progress_bar(pm['covered'], _counter_total(pm))}</td>
<td class="align-right mono">{pm['covered']}/{_counter_total(pm)}</td>
<td class="align-right mono">{pc['covered']}/{_counter_total(pc)}</td>
<td class="align-right mono">{pl['covered']}/{_counter_total(pl)}</td>
</tr>"""

        table_html = f"""<div class="card" id="coverage">
<div class="card-title">Packages ({len(jacoco_data['packages'])})</div>
<div class="table-wrap">
<table data-sortable>
<thead><tr>
  <th>Package</th><th>Method Coverage</th><th>Methods</th><th>Classes</th><th>Lines</th>
</tr></thead>
<tbody>{rows}</tbody>
</table>
</div>
</div>"""

    # Slowest tests (junit)
    slowest_html = ""
    if has_junit:
        all_tests = []
        for s in junit_data["suites"]:
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

        slowest_html = f"""<div class="card">
<div class="card-title">Slowest Tests (Top 10)</div>
<div class="table-wrap">
<table data-sortable>
<thead><tr>
  <th>Test</th><th>Suite</th><th>Status</th><th>Time</th><th></th>
</tr></thead>
<tbody>{slowest_rows}</tbody>
</table>
</div>
</div>"""

    # Failures section (junit)
    failures_html = ""
    if has_junit:
        all_tests = []
        for s in junit_data["suites"]:
            for tc in s["test_cases"]:
                all_tests.append({"suite": s["name"], **tc})
        failed_tests = [t for t in all_tests if t["status"] in ("FAIL", "ERROR")]
        if failed_tests:
            items = ""
            for tc in failed_tests[:20]:
                output = ""
                if tc.get("error_output"):
                    output = f'<div class="details-content"><pre class="error-output">{escape(tc["error_output"])}</pre></div>'
                items += f"""<details>
<summary>{status_badge(tc['status'])} {escape(tc['name'])} — {escape(tc.get('error_message', ''))}</summary>
{output}
</details>"""
            more = ""
            if len(failed_tests) > 20:
                more = f'<p style="color:var(--text-muted); margin-top:var(--space-3);">… and {len(failed_tests) - 20} more failures in suite detail pages.</p>'
            failures_html = f"""<div class="card">
<div class="card-title">⚠ Failures & Errors ({len(failed_tests)})</div>
{items}{more}
</div>"""

    # Coverage detail section (jacoco, when both are present)
    cov_detail_html = ""
    if has_jacoco and has_junit:
        rows = ""
        for pkg in jacoco_data["packages"]:
            pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
            fname = pkg_filename(pkg["name"])
            rows += f"""<tr>
<td><a href="packages/{fname}">{escape(pkg['name'])}</a></td>
<td class="align-right" data-sort-value="{_counter_pct(pm):.1f}">{progress_bar(pm['covered'], _counter_total(pm))}</td>
<td class="align-right mono">{pm['covered']}/{_counter_total(pm)}</td>
<td class="align-right mono">{len(pkg['classes'])}</td>
</tr>"""

        cov_detail_html = f"""<div class="card" id="coverage">
<div class="card-title">Coverage by Package ({len(jacoco_data['packages'])})</div>
<div class="table-wrap">
<table data-sortable>
<thead><tr>
  <th>Package</th><th>Method Coverage</th><th>Methods</th><th>Classes</th>
</tr></thead>
<tbody>{rows}</tbody>
</table>
</div>
</div>"""

    # Session info (jacoco)
    session_html = ""
    if has_jacoco and jacoco_data.get("session"):
        s = jacoco_data["session"]
        start_dt = datetime.fromtimestamp(s["start"] / 1000.0, tz=timezone.utc)
        duration = s["dump"] - s["start"]
        session_html = f"""<div class="card">
<div class="card-title">Session</div>
<table>
<tr><td class="mono">ID</td><td>{escape(s['id'])}</td></tr>
<tr><td class="mono">Start</td><td>{start_dt.strftime('%Y-%m-%d %H:%M:%S UTC')}</td></tr>
<tr><td class="mono">Duration</td><td>{format_duration(duration)}</td></tr>
</table>
</div>"""

    # Determine title
    if has_junit and has_jacoco:
        title = "Test Results & Coverage"
    elif has_junit:
        title = "Test Results"
    else:
        title = "Coverage Report"

    body = f"""
{hb_html}
{tab_html}
<div class="stats-grid">{stats_html}</div>

{histogram_html}
{session_html}
{table_html}
{slowest_html}
{cov_detail_html}
{failures_html}
"""

    return html_page(title, body, breadcrumbs=[(title, None)])


# ==============================================================================
# Suite Detail Page (JUnit)
# ==============================================================================

def generate_suite_page(suite):
    """Generate a per-suite detail page."""
    test_cases = suite["test_cases"]
    max_time = max((tc["time_ms"] for tc in test_cases), default=1)

    stats = "".join([
        stat_card(suite["tests"], "Tests", "total"),
        stat_card(suite["passed"], "Passed", "pass"),
        stat_card(suite["failures"], "Failed", "fail"),
        stat_card(suite["skipped"], "Skipped", "skip"),
        stat_card(format_duration(int(suite["time"] * 1000)), "Duration", "time"),
    ])

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

    errors_html = ""
    failed = [tc for tc in test_cases if tc["status"] in ("FAIL", "ERROR")]
    if failed:
        items = ""
        for tc in failed:
            output = ""
            if tc.get("error_output"):
                output = f'<div class="details-content"><pre class="error-output">{escape(tc["error_output"])}</pre></div>'
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
    breadcrumbs = [("Report", "../index.html"), (suite["name"], None)]
    return html_page(suite["name"], body, breadcrumbs=breadcrumbs)


# ==============================================================================
# Package Detail Page (JaCoCo)
# ==============================================================================

def generate_package_page(pkg):
    """Generate a per-package detail page."""
    pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})

    stats = "".join([
        stat_card(
            f"{_counter_pct(pm):.1f}%",
            f"Method Coverage ({pm['covered']}/{_counter_total(pm)})",
            "pass" if _counter_pct(pm) >= 80 else "fail",
        ),
        stat_card(len(pkg["classes"]), "Classes", "total"),
    ])

    cls_rows = ""
    for cls in pkg["classes"]:
        cm = cls["counters"].get("METHOD", {"missed": 0, "covered": 0})
        fname = cls_filename(cls["name"])
        cls_rows += f"""<tr>
<td><a href="../classes/{fname}">{escape(cls['name'])}</a></td>
<td>{escape(cls['sourcefilename'])}</td>
<td class="align-right" data-sort-value="{_counter_pct(cm):.1f}">{progress_bar(cm['covered'], _counter_total(cm))}</td>
<td class="align-right mono">{cm['covered']}/{_counter_total(cm)}</td>
<td class="align-right mono">{len(cls['methods'])}</td>
</tr>"""

    body = f"""
<div class="stats-grid">{stats}</div>
<div class="card">
  <div class="card-title">Classes</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Class</th><th>Source File</th><th>Coverage</th><th>Methods</th><th>Total Methods</th>
    </tr></thead>
    <tbody>{cls_rows}</tbody>
  </table>
  </div>
</div>
"""
    breadcrumbs = [("Report", "../index.html"), (pkg["name"], None)]
    return html_page(f"Package: {pkg['name']}", body, breadcrumbs=breadcrumbs)


# ==============================================================================
# Class Detail Page (JaCoCo)
# ==============================================================================

def generate_class_page(cls, pkg_name):
    """Generate a per-class detail page."""
    cm = cls["counters"].get("METHOD", {"missed": 0, "covered": 0})

    stats = "".join([
        stat_card(
            f"{_counter_pct(cm):.1f}%",
            "Method Coverage",
            "pass" if _counter_pct(cm) >= 80 else "fail",
        ),
        stat_card(_counter_total(cm), "Total Methods", "total"),
        stat_card(cm["covered"], "Covered", "pass"),
        stat_card(cm["missed"], "Missed", "fail"),
    ])

    method_rows = ""
    for m in cls["methods"]:
        mm = m["counters"].get("METHOD", {"missed": 0, "covered": 0})
        is_covered = mm.get("covered", 0) > 0
        badge = status_badge("PASS" if is_covered else "FAIL")
        method_rows += f"""<tr>
<td>{badge}</td>
<td class="mono">{escape(m['name'])}</td>
<td class="mono">{escape(m['desc'])}</td>
<td class="align-right mono">{escape(str(m['line']))}</td>
</tr>"""

    body = f"""
<div class="stats-grid">{stats}</div>
<div class="card">
  <div class="card-title">Methods ({_counter_total(cm)})</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Status</th><th>Method</th><th>Desc</th><th>Line</th>
    </tr></thead>
    <tbody>{method_rows}</tbody>
  </table>
  </div>
</div>
"""
    breadcrumbs = [
        ("Report", "../index.html"),
        (pkg_name, f"../packages/{pkg_filename(pkg_name)}"),
        (cls["name"], None),
    ]
    return html_page(f"Class: {cls['name']}", body, breadcrumbs=breadcrumbs)


# ==============================================================================
# Main — Single Entry Point
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Generate a single merged HTML report site"
    )
    parser.add_argument("--junit", default=None, help="Path to JUnit XML file")
    parser.add_argument("--jacoco", default=None, help="Path to JaCoCo XML file")
    parser.add_argument("--output", required=True, help="Output directory")
    args = parser.parse_args()

    if not args.junit and not args.jacoco:
        print("[ERROR] At least one of --junit or --jacoco is required", file=sys.stderr)
        sys.exit(1)

    for path, label in [(args.junit, "JUnit"), (args.jacoco, "JaCoCo")]:
        if path and not os.path.isfile(path):
            print(f"[ERROR] {label} XML not found: {path}", file=sys.stderr)
            sys.exit(2)

    output_dir = args.output
    suites_dir = os.path.join(output_dir, "suites")
    pkg_dir = os.path.join(output_dir, "packages")
    cls_dir = os.path.join(output_dir, "classes")

    # Parse available inputs
    junit_data = parse_junit_xml(args.junit) if args.junit else None
    jacoco_data = parse_jacoco_xml(args.jacoco) if args.jacoco else None

    # Create directories as needed
    os.makedirs(output_dir, exist_ok=True)
    if junit_data:
        os.makedirs(suites_dir, exist_ok=True)
    if jacoco_data:
        os.makedirs(pkg_dir, exist_ok=True)
        os.makedirs(cls_dir, exist_ok=True)

    # Dashboard
    with open(os.path.join(output_dir, "index.html"), "w") as f:
        f.write(generate_dashboard(junit_data, jacoco_data))

    # Suite pages (junit)
    if junit_data:
        for suite in junit_data["suites"]:
            fname = suite_filename(suite["name"])
            with open(os.path.join(suites_dir, fname), "w") as f:
                f.write(generate_suite_page(suite))

    # Package + class pages (jacoco)
    if jacoco_data:
        for pkg in jacoco_data["packages"]:
            fname = pkg_filename(pkg["name"])
            with open(os.path.join(pkg_dir, fname), "w") as f:
                f.write(generate_package_page(pkg))

            for cls in pkg["classes"]:
                cfname = cls_filename(cls["name"])
                with open(os.path.join(cls_dir, cfname), "w") as f:
                    f.write(generate_class_page(cls, pkg["name"]))

    # Summary
    parts = []
    if junit_data:
        parts.append(f"{junit_data['totals']['suites']} suites, {junit_data['totals']['tests']} tests")
    if jacoco_data:
        parts.append(f"{len(jacoco_data['packages'])} packages")
    print(
        f"[INFO] HTML report written: {output_dir}/ ({', '.join(parts)})",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
