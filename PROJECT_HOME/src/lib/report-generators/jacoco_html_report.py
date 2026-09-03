#!/usr/bin/env python3
# (c) 2026-* Frederick Bloom -- jacoco_html_report.py -- Hanaden AI
# ==============================================================================
# NAME:      jacoco_html_report.py
# VERSION:   0.1.0
# PURPOSE:   Generate a self-contained HTML site from JaCoCo XML.
#
# USAGE:     python3 jacoco_html_report.py --input <jacoco.xml> --output <dir>
#
# OUTPUT:    <dir>/
#              index.html                — Coverage dashboard with counters
#              packages/<Feat>.html      — Per-package class breakdown
#              classes/<Feat>.<Spec>.html — Per-class method detail
#
# DEPENDENCIES: Python 3.14+ stdlib only
# ==============================================================================
"""JaCoCo XML → HTML site generator with Hanaden dark theme."""

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from html import escape

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _html_templates import (
    html_page,
    progress_bar,
    stat_card,
    format_duration,
    status_badge,
)


def parse_jacoco_xml(xml_path):
    """Parse JaCoCo XML into structured data."""
    tree = ET.parse(xml_path)
    root = tree.getroot()

    if root.tag != "report":
        print(f"[ERROR] Expected <report> root, got <{root.tag}>", file=sys.stderr)
        sys.exit(2)

    report_name = root.get("name", "Coverage Report")

    # Session info
    session_el = root.find("sessioninfo")
    session = {}
    if session_el is not None:
        session = {
            "id": session_el.get("id", ""),
            "start": int(session_el.get("start", "0")),
            "dump": int(session_el.get("dump", "0")),
        }

    # Report-level counters
    report_counters = _parse_counters(root)

    # Packages
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
    """Return missed + covered."""
    return counter.get("missed", 0) + counter.get("covered", 0)


def _counter_pct(counter):
    """Return coverage percentage."""
    total = _counter_total(counter)
    if total == 0:
        return 0.0
    return (counter.get("covered", 0) / total) * 100


def pkg_filename(name):
    """Package name to filename."""
    return name.replace("/", "-").replace(".", "-") + ".html"


def cls_filename(name):
    """Class name to filename."""
    return name.replace("/", "-").replace(" ", "_") + ".html"


def generate_dashboard(data):
    """Generate coverage dashboard index.html."""
    counters = data["counters"]
    packages = data["packages"]

    # Stats cards
    method_c = counters.get("METHOD", {"missed": 0, "covered": 0})
    class_c = counters.get("CLASS", {"missed": 0, "covered": 0})
    line_c = counters.get("LINE", {"missed": 0, "covered": 0})

    stats = "".join([
        stat_card(
            f"{_counter_pct(method_c):.1f}%",
            f"Method Coverage ({method_c['covered']}/{_counter_total(method_c)})",
            "pass" if _counter_pct(method_c) >= 80 else "fail",
        ),
        stat_card(
            f"{_counter_pct(class_c):.1f}%",
            f"Class Coverage ({class_c['covered']}/{_counter_total(class_c)})",
            "pass" if _counter_pct(class_c) >= 80 else "fail",
        ),
        stat_card(
            f"{_counter_pct(line_c):.1f}%",
            f"Line Coverage ({line_c['covered']}/{_counter_total(line_c)})",
            "pass" if _counter_pct(line_c) >= 80 else "fail",
        ),
        stat_card(len(packages), "Packages", "total"),
    ])

    # Session info
    session_html = ""
    if data["session"]:
        s = data["session"]
        from datetime import datetime, timezone
        start_dt = datetime.fromtimestamp(s["start"] / 1000.0, tz=timezone.utc)
        dump_dt = datetime.fromtimestamp(s["dump"] / 1000.0, tz=timezone.utc)
        duration = s["dump"] - s["start"]
        session_html = f"""<div class="card">
<div class="card-title">Session Info</div>
<table>
<tr><td class="mono">Session ID</td><td>{escape(s['id'])}</td></tr>
<tr><td class="mono">Start</td><td>{start_dt.strftime('%Y-%m-%d %H:%M:%S UTC')}</td></tr>
<tr><td class="mono">Duration</td><td>{format_duration(duration)}</td></tr>
</table>
</div>"""

    # Overall coverage bar
    overall_pct = _counter_pct(method_c)
    overall_bar = progress_bar(method_c["covered"], _counter_total(method_c))

    # Package table
    pkg_rows = ""
    for pkg in packages:
        pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
        pc = pkg["counters"].get("CLASS", {"missed": 0, "covered": 0})
        pl = pkg["counters"].get("LINE", {"missed": 0, "covered": 0})
        fname = pkg_filename(pkg["name"])

        pkg_rows += f"""<tr>
<td><a href="packages/{fname}">{escape(pkg['name'])}</a></td>
<td class="align-right" data-sort-value="{_counter_pct(pm):.1f}">{progress_bar(pm['covered'], _counter_total(pm))}</td>
<td class="align-right mono">{pm['covered']}/{_counter_total(pm)}</td>
<td class="align-right mono">{pc['covered']}/{_counter_total(pc)}</td>
<td class="align-right mono">{pl['covered']}/{_counter_total(pl)}</td>
</tr>"""

    body = f"""
<div class="stats-grid">{stats}</div>

{session_html}

<div class="card">
  <div class="card-title">Overall Coverage</div>
  {overall_bar}
</div>

<div class="card">
  <div class="card-title">Packages ({len(packages)})</div>
  <div class="table-wrap">
  <table data-sortable>
    <thead><tr>
      <th>Package</th><th>Method Coverage</th><th>Methods</th><th>Classes</th><th>Lines</th>
    </tr></thead>
    <tbody>{pkg_rows}</tbody>
  </table>
  </div>
</div>
"""
    return html_page("Coverage Report", body, breadcrumbs=[("Coverage Report", None)])


def generate_package_page(pkg):
    """Generate per-package detail page."""
    pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})

    stats = "".join([
        stat_card(
            f"{_counter_pct(pm):.1f}%",
            f"Method Coverage ({pm['covered']}/{_counter_total(pm)})",
            "pass" if _counter_pct(pm) >= 80 else "fail",
        ),
        stat_card(len(pkg["classes"]), "Classes", "total"),
    ])

    # Classes table
    cls_rows = ""
    for cls in pkg["classes"]:
        cm = cls["counters"].get("METHOD", {"missed": 0, "covered": 0})
        cc = cls["counters"].get("CLASS", {"missed": 0, "covered": 0})
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
    breadcrumbs = [
        ("Coverage Report", "../index.html"),
        (pkg["name"], None),
    ]
    return html_page(f"Package: {pkg['name']}", body, breadcrumbs=breadcrumbs)


def generate_class_page(cls, pkg_name):
    """Generate per-class detail page."""
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

    # Methods table
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
        ("Coverage Report", "../index.html"),
        (pkg_name, f"../packages/{pkg_filename(pkg_name)}"),
        (cls["name"], None),
    ]
    return html_page(f"Class: {cls['name']}", body, breadcrumbs=breadcrumbs)


def main():
    parser = argparse.ArgumentParser(
        description="Generate HTML report site from JaCoCo XML"
    )
    parser.add_argument("--input", required=True, help="Path to JaCoCo XML file")
    parser.add_argument(
        "--output",
        default=None,
        help="Output directory (default: <input-dir>/html-jacoco/)",
    )
    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"[ERROR] JaCoCo XML not found: {args.input}", file=sys.stderr)
        sys.exit(2)

    output_dir = args.output or os.path.join(
        os.path.dirname(args.input), "html-jacoco"
    )
    pkg_dir = os.path.join(output_dir, "packages")
    cls_dir = os.path.join(output_dir, "classes")
    os.makedirs(pkg_dir, exist_ok=True)
    os.makedirs(cls_dir, exist_ok=True)

    data = parse_jacoco_xml(args.input)

    # Dashboard
    with open(os.path.join(output_dir, "index.html"), "w") as f:
        f.write(generate_dashboard(data))

    # Package pages
    for pkg in data["packages"]:
        fname = pkg_filename(pkg["name"])
        with open(os.path.join(pkg_dir, fname), "w") as f:
            f.write(generate_package_page(pkg))

        # Class pages
        for cls in pkg["classes"]:
            cfname = cls_filename(cls["name"])
            with open(os.path.join(cls_dir, cfname), "w") as f:
                f.write(generate_class_page(cls, pkg["name"]))

    total_pkgs = len(data["packages"])
    total_cls = sum(len(p["classes"]) for p in data["packages"])
    print(
        f"[INFO] JaCoCo HTML report written: {output_dir}/ "
        f"({total_pkgs} packages, {total_cls} classes)",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
