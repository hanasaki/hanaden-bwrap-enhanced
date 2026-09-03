#!/usr/bin/env python3
# (c) 2026-* Frederick Bloom -- unified_html_report.py -- Hanaden AI
# ==============================================================================
# NAME:      unified_html_report.py
# VERSION:   0.1.0
# PURPOSE:   Generate a unified HTML site merging JUnit + JaCoCo data.
#
# USAGE:     python3 unified_html_report.py \
#                --junit <junit.xml> --jacoco <jacoco.xml> --output <dir>
#
# OUTPUT:    <dir>/
#              index.html              — Unified dashboard (side-by-side)
#              test-results/           — JUnit detail pages
#              coverage/               — JaCoCo detail pages
#
# DEPENDENCIES: Python 3.14+ stdlib only
# ==============================================================================
"""Unified (JUnit + JaCoCo) HTML site generator with Hanaden dark theme."""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _html_templates import (
    html_page,
    status_badge,
    progress_bar,
    stat_card,
    format_duration,
    health_badge,
    svg_timing_histogram,
)

# Re-use parsers from the individual generators
from junit_html_report import parse_junit_xml, suite_filename, generate_suite_page
from jacoco_html_report import (
    parse_jacoco_xml,
    pkg_filename,
    cls_filename,
    generate_package_page,
    generate_class_page,
    _counter_pct,
    _counter_total,
)
from html import escape


def generate_unified_dashboard(junit_data, jacoco_data):
    """Generate the unified dashboard with side-by-side test + coverage."""
    j_totals = junit_data["totals"]
    c_counters = jacoco_data["counters"]
    method_c = c_counters.get("METHOD", {"missed": 0, "covered": 0})
    class_c = c_counters.get("CLASS", {"missed": 0, "covered": 0})

    # Health badge
    hb = health_badge(j_totals["passed"], j_totals["tests"], j_totals["failures"])

    # Combined stats
    stats = "".join([
        stat_card(j_totals["tests"], "Total Tests", "total"),
        stat_card(j_totals["passed"], "Passed", "pass"),
        stat_card(j_totals["failures"], "Failed", "fail"),
        stat_card(format_duration(int(j_totals["time"] * 1000)), "Duration", "time"),
        stat_card(
            f"{_counter_pct(method_c):.1f}%",
            "Method Coverage",
            "pass" if _counter_pct(method_c) >= 80 else "fail",
        ),
        stat_card(
            f"{_counter_pct(class_c):.1f}%",
            "Class Coverage",
            "pass" if _counter_pct(class_c) >= 80 else "fail",
        ),
    ])

    # Timing histogram
    all_durations = []
    for s in junit_data["suites"]:
        for tc in s["test_cases"]:
            all_durations.append(tc["time_ms"])
    histogram = svg_timing_histogram(all_durations)

    # Navigation tabs
    tabs = """<div class="tabs">
<a class="tab active" href="index.html">Dashboard</a>
<a class="tab" href="test-results/index.html">Test Results</a>
<a class="tab" href="coverage/index.html">Coverage</a>
</div>"""

    # Combined suite + coverage table
    # Map packages to suites
    pkg_by_name = {p["name"]: p for p in jacoco_data["packages"]}
    combined_rows = ""
    for suite in junit_data["suites"]:
        sname = suite["name"]
        # Try to match package name
        # Suite names are "Feat/Spec", package names are "Feat"
        feat = sname.split("/")[0] if "/" in sname else sname
        pkg = pkg_by_name.get(feat, None)

        sfname = suite_filename(sname)
        test_pbar = progress_bar(suite["passed"], suite["tests"])

        cov_cell = '<span class="mono text-muted">—</span>'
        if pkg:
            pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
            cov_cell = progress_bar(pm["covered"], _counter_total(pm))

        combined_rows += f"""<tr>
<td><a href="test-results/suites/{sfname}">{escape(sname)}</a></td>
<td class="align-right" data-sort-value="{suite['tests']}">{suite['tests']}</td>
<td>{test_pbar}</td>
<td class="align-right mono" data-sort-value="{suite['time']}">{format_duration(int(suite['time'] * 1000))}</td>
<td>{cov_cell}</td>
</tr>"""

    # Failures summary
    all_tests = []
    for s in junit_data["suites"]:
        for tc in s["test_cases"]:
            all_tests.append({"suite": s["name"], **tc})
    failed_tests = [t for t in all_tests if t["status"] in ("FAIL", "ERROR")]
    failures_html = ""
    if failed_tests:
        items = ""
        for tc in failed_tests[:10]:  # Show first 10
            items += f"""<details>
<summary>{status_badge(tc['status'])} {escape(tc['name'])} — {escape(tc.get('error_message', ''))}</summary>
<div class="details-content"><pre class="error-output">{escape(tc.get('error_output', ''))}</pre></div>
</details>"""
        more_msg = ""
        if len(failed_tests) > 10:
            more_msg = f'<p style="color:var(--text-muted); margin-top:var(--space-3);">… and {len(failed_tests) - 10} more. <a href="test-results/index.html">View all →</a></p>'
        failures_html = f"""<div class="card">
<div class="card-title">⚠ Failures ({len(failed_tests)})</div>
{items}{more_msg}
</div>"""

    body = f"""
{hb}
{tabs}
<div class="stats-grid">{stats}</div>

<div class="card">
  <div class="card-title">Timing Distribution</div>
  {histogram}
</div>

<div class="card">
  <div class="card-title">Suites — Test Results + Coverage</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Suite</th><th>Tests</th><th>Pass Rate</th><th>Time</th><th>Coverage</th>
    </tr></thead>
    <tbody>{combined_rows}</tbody>
  </table>
  </div>
</div>

{failures_html}
"""
    return html_page(
        "Unified Report", body, breadcrumbs=[("Unified Report", None)]
    )


def generate_test_results_index(junit_data):
    """Generate the test-results sub-view index."""
    totals = junit_data["totals"]
    suites = junit_data["suites"]

    stats = "".join([
        stat_card(totals["tests"], "Total Tests", "total"),
        stat_card(totals["passed"], "Passed", "pass"),
        stat_card(totals["failures"], "Failed", "fail"),
        stat_card(totals["skipped"], "Skipped", "skip"),
    ])

    suite_rows = ""
    for s in suites:
        fname = suite_filename(s["name"])
        pbar = progress_bar(s["passed"], s["tests"])
        suite_rows += f"""<tr>
<td><a href="suites/{fname}">{escape(s['name'])}</a></td>
<td class="align-right">{s['tests']}</td>
<td class="align-right">{s['passed']}</td>
<td class="align-right">{s['failures']}</td>
<td class="align-right mono">{format_duration(int(s['time'] * 1000))}</td>
<td>{pbar}</td>
</tr>"""

    tabs = """<div class="tabs">
<a class="tab" href="../index.html">Dashboard</a>
<a class="tab active" href="index.html">Test Results</a>
<a class="tab" href="../coverage/index.html">Coverage</a>
</div>"""

    body = f"""
{tabs}
<div class="stats-grid">{stats}</div>

<div class="card">
  <div class="card-title">Test Suites ({totals['suites']})</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Suite</th><th>Tests</th><th>Passed</th><th>Failed</th><th>Time</th><th>Pass Rate</th>
    </tr></thead>
    <tbody>{suite_rows}</tbody>
  </table>
  </div>
</div>
"""
    breadcrumbs = [("Unified Report", "../index.html"), ("Test Results", None)]
    return html_page("Test Results", body, breadcrumbs=breadcrumbs)


def generate_coverage_index(jacoco_data):
    """Generate the coverage sub-view index."""
    counters = jacoco_data["counters"]
    packages = jacoco_data["packages"]
    method_c = counters.get("METHOD", {"missed": 0, "covered": 0})
    class_c = counters.get("CLASS", {"missed": 0, "covered": 0})

    stats = "".join([
        stat_card(
            f"{_counter_pct(method_c):.1f}%",
            "Method Coverage",
            "pass" if _counter_pct(method_c) >= 80 else "fail",
        ),
        stat_card(
            f"{_counter_pct(class_c):.1f}%",
            "Class Coverage",
            "pass" if _counter_pct(class_c) >= 80 else "fail",
        ),
        stat_card(len(packages), "Packages", "total"),
    ])

    pkg_rows = ""
    for pkg in packages:
        pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
        fname = pkg_filename(pkg["name"])
        pkg_rows += f"""<tr>
<td><a href="packages/{fname}">{escape(pkg['name'])}</a></td>
<td class="align-right" data-sort-value="{_counter_pct(pm):.1f}">{progress_bar(pm['covered'], _counter_total(pm))}</td>
<td class="align-right mono">{pm['covered']}/{_counter_total(pm)}</td>
<td class="align-right mono">{len(pkg['classes'])}</td>
</tr>"""

    tabs = """<div class="tabs">
<a class="tab" href="../index.html">Dashboard</a>
<a class="tab" href="../test-results/index.html">Test Results</a>
<a class="tab active" href="index.html">Coverage</a>
</div>"""

    body = f"""
{tabs}
<div class="stats-grid">{stats}</div>

<div class="card">
  <div class="card-title">Packages ({len(packages)})</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Package</th><th>Method Coverage</th><th>Methods</th><th>Classes</th>
    </tr></thead>
    <tbody>{pkg_rows}</tbody>
  </table>
  </div>
</div>
"""
    breadcrumbs = [("Unified Report", "../index.html"), ("Coverage", None)]
    return html_page("Coverage", body, breadcrumbs=breadcrumbs)


def main():
    parser = argparse.ArgumentParser(
        description="Generate unified HTML report from JUnit + JaCoCo XML"
    )
    parser.add_argument("--junit", required=True, help="Path to JUnit XML")
    parser.add_argument("--jacoco", required=True, help="Path to JaCoCo XML")
    parser.add_argument(
        "--output",
        default=None,
        help="Output directory (default: <junit-dir>/html-unified/)",
    )
    args = parser.parse_args()

    for path, label in [(args.junit, "JUnit"), (args.jacoco, "JaCoCo")]:
        if not os.path.isfile(path):
            print(f"[ERROR] {label} XML not found: {path}", file=sys.stderr)
            sys.exit(2)

    output_dir = args.output or os.path.join(
        os.path.dirname(args.junit), "html-unified"
    )
    tr_dir = os.path.join(output_dir, "test-results")
    tr_suites_dir = os.path.join(tr_dir, "suites")
    cov_dir = os.path.join(output_dir, "coverage")
    cov_pkg_dir = os.path.join(cov_dir, "packages")
    cov_cls_dir = os.path.join(cov_dir, "classes")
    for d in [tr_suites_dir, cov_pkg_dir, cov_cls_dir]:
        os.makedirs(d, exist_ok=True)

    junit_data = parse_junit_xml(args.junit)
    jacoco_data = parse_jacoco_xml(args.jacoco)

    # Unified dashboard
    with open(os.path.join(output_dir, "index.html"), "w") as f:
        f.write(generate_unified_dashboard(junit_data, jacoco_data))

    # Test results sub-view
    with open(os.path.join(tr_dir, "index.html"), "w") as f:
        f.write(generate_test_results_index(junit_data))

    # Per-suite pages
    for suite in junit_data["suites"]:
        fname = suite_filename(suite["name"])
        with open(os.path.join(tr_suites_dir, fname), "w") as f:
            f.write(generate_suite_page(suite))

    # Coverage sub-view
    with open(os.path.join(cov_dir, "index.html"), "w") as f:
        f.write(generate_coverage_index(jacoco_data))

    # Per-package pages
    for pkg in jacoco_data["packages"]:
        fname = pkg_filename(pkg["name"])
        with open(os.path.join(cov_pkg_dir, fname), "w") as f:
            f.write(generate_package_page(pkg))

        for cls in pkg["classes"]:
            cfname = cls_filename(cls["name"])
            with open(os.path.join(cov_cls_dir, cfname), "w") as f:
                f.write(generate_class_page(cls, pkg["name"]))

    print(
        f"[INFO] Unified HTML report written: {output_dir}/",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
