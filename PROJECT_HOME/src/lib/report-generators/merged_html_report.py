#!/usr/bin/env python3
# (c) 2026-* Frederick Bloom -- merged_html_report.py -- Hanaden AI
# ==============================================================================
# NAME:      merged_html_report.py
# VERSION:   0.4.0
# PURPOSE:   Generate a self-contained HTML report site from test run directories.
#            - Scans for *.test.run/ directories under --dir-scan
#            - Fixed sidebar with collapsible feat→spec tree + text filter
#            - 5 tabs: Dashboard (2×2 charts), Tests, Coverage, Failures, Trends
#            - Sidebar click filters all tabs to that feat/spec scope
#            - SVG charts: donut, bar, line (all inline, no external deps)
#            - Trend data from all discovered runs
#
# USAGE:     python3 merged_html_report.py --dir-scan DIR [-o DIR] [--maxdepth N] [--primary NAME]
#
# OUTPUT:    <output>/site/index.html  — Self-contained HTML SPA
#            <output>/site/report.tar.gz — Compressed archive
#
# DEPENDENCIES: Python 3.10+ stdlib only
# ==============================================================================
"""Single-page HTML report generator v0.4.0 — dir-scan, sidebar, tabs, charts, trends."""

import argparse
import json
import os
import sys
import xml.etree.ElementTree as ET
from html import escape
from datetime import datetime, timezone

# ==============================================================================
# Path Helpers
# ==============================================================================

import re

def _extract_feat_spec(suite_name):
    """Extract feat and spec from a suite name/path.

    Handles paths like:
      .../suites/BwrapPreflight.feat/BwrapBinaryPresent.spec/test_bwrap.bats
      .../suites/BwrapPreflight/feat/BwrapBinaryPresent.spec/test_bwrap.bats
      test_at_spi_bus_bind/bats
    """
    # Pattern 1: explicit .feat/ and .spec/ in path
    # e.g. /suites/BwrapPreflight.feat/UserNamespaceEnabled.spec/test_*.bats
    m = re.search(r'/([^/]+)\.feat/([^/]+)\.spec/', suite_name)
    if m:
        return m.group(1), m.group(2)

    # Pattern 2: feat/ directory marker (folder named "feat")
    # e.g. /suites/BwrapPreflight/feat/BwrapBinaryPresent.spec/test_*.bats
    m = re.search(r'/suites/([^/]+)/feat/([^/]+)\.spec/', suite_name)
    if m:
        return m.group(1), m.group(2)

    # Pattern 3: /suites/Foo.feat/Bar.spec/ without .spec extension
    m = re.search(r'/suites/([^/]+)\.feat/([^/]+)/', suite_name)
    if m:
        return m.group(1), m.group(2)

    # Pattern 4: classname-based (from tc classname like "BwrapPreflight.BwrapBinaryPresent")
    if "." in suite_name and "/" not in suite_name:
        parts = suite_name.rsplit(".", 1)
        return parts[0], parts[-1]

    # Pattern 5: short name with / (e.g. test_foo/bats)
    if "/" in suite_name:
        parts = suite_name.split("/")
        base = parts[-1] if parts[-1] != "bats" else parts[-2] if len(parts) >= 2 else parts[0]
        return base, base

    return suite_name, suite_name


def _extract_pkg_name(raw_name):
    """Extract clean feature name from a JaCoCo package name/path.

    Input:  /homes/.../suites/BwrapPreflight  →  BwrapPreflight
    Input:  test_at_spi_bus_bind              →  test_at_spi_bus_bind
    """
    # Try to extract from /suites/FeatureName path
    m = re.search(r'/suites/([^/]+?)(?:\.feat)?$', raw_name)
    if m:
        return m.group(1)
    # Try .feat suffix
    m = re.search(r'([^/]+)\.feat$', raw_name)
    if m:
        return m.group(1)
    # Just the basename
    if '/' in raw_name:
        return raw_name.rstrip('/').rsplit('/', 1)[-1]
    return raw_name


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
            "test_cases": [],
        }
        suite["passed"] = (
            suite["tests"] - suite["failures"] - suite["errors"] - suite["skipped"]
        )

        for tc_el in suite_el.findall("testcase"):
            tc = {
                "name": tc_el.get("name", ""),
                "classname": tc_el.get("classname", ""),
                "time_ms": int(float(tc_el.get("time", "0")) * 1000),
                "status": "PASS",
                "error_message": "",
                "error_output": "",
            }

            failure = tc_el.find("failure")
            error = tc_el.find("error")
            skipped_el = tc_el.find("skipped")

            if failure is not None:
                tc["status"] = "FAIL"
                tc["error_message"] = failure.get("message", "")
                tc["error_output"] = failure.text or ""
            elif error is not None:
                tc["status"] = "ERROR"
                tc["error_message"] = error.get("message", "")
                tc["error_output"] = error.text or ""
            elif skipped_el is not None:
                tc["status"] = "SKIP"
                tc["error_message"] = skipped_el.get("message", "")

            # Derive feat/spec from suite name path
            # Suite names look like: .../suites/BwrapPreflight/feat/BwrapBinaryPresent.spec/test_*.bats
            # or short form: test_foo/bats
            tc["feat"], tc["spec"] = _extract_feat_spec(suite["name"])

            suite["test_cases"].append(tc)

        # Derive feat/spec for suite
        suite["feat"], suite["spec"] = _extract_feat_spec(suite["name"])

        suites.append(suite)

    totals = {
        "tests": sum(s["tests"] for s in suites),
        "passed": sum(s["passed"] for s in suites),
        "failures": sum(s["failures"] for s in suites),
        "errors": sum(s["errors"] for s in suites),
        "skipped": sum(s["skipped"] for s in suites),
        "time_ms": int(sum(s["time"] for s in suites) * 1000),
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

    packages = []
    for pkg_el in root.findall("package"):
        raw_name = pkg_el.get("name", "unknown")
        # Clean package name: extract feat from full path
        clean_name = _extract_pkg_name(raw_name)
        pkg = {
            "name": clean_name,
            "raw_name": raw_name,
            "counters": _parse_counters(pkg_el),
            "classes": [],
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

        packages.append(pkg)

    report_counters = _parse_counters(root)

    return {
        "name": root.get("name", "Coverage Report"),
        "counters": report_counters,
        "packages": packages,
    }


def _parse_counters(element):
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
    return (counter.get("covered", 0) / total) * 100 if total else 0.0


# ==============================================================================
# Directory Scanner — Discover Test Run Directories
# ==============================================================================

def discover_runs(base_dir, maxdepth=1):
    """Find all *.test.run directories under base_dir, respecting maxdepth."""
    runs = []
    base_dir = os.path.abspath(base_dir)
    for root, dirs, files in os.walk(base_dir):
        depth = root.replace(base_dir, '').count(os.sep)
        if depth >= maxdepth:
            dirs.clear()  # don't descend further
            continue
        for d in list(dirs):
            if d.endswith('.test.run'):
                run_path = os.path.join(root, d)
                meta_path = os.path.join(run_path, '_run-metadata.json')
                metadata = {}
                if os.path.isfile(meta_path):
                    try:
                        with open(meta_path, 'r') as f:
                            metadata = json.load(f)
                    except (json.JSONDecodeError, OSError):
                        pass
                runs.append({
                    'dir_name': d,
                    'path': run_path,
                    'metadata': metadata,
                })
    return sorted(runs, key=lambda r: r['dir_name'])


# ==============================================================================
# Trend Data — Scan Historical Runs (legacy — used by discover_runs path)
# ==============================================================================



# ==============================================================================
# Format Helpers
# ==============================================================================

def fmt_dur(ms):
    """Format ms as human-readable."""
    if ms < 1000:
        return f"{ms}ms"
    elif ms < 60000:
        return f"{ms / 1000:.1f}s"
    else:
        m = ms // 60000
        s = (ms % 60000) / 1000
        return f"{m}m {s:.0f}s"


def fmt_ts_short(ts_str):
    """Format ISO timestamp as short date string."""
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt.strftime("%b %d %H:%M")
    except Exception:
        return ts_str[:10] if len(ts_str) >= 10 else ts_str


# ==============================================================================
# Build JSON Data Blob for Embedding
# ==============================================================================

def build_data_blob(junit_data, jacoco_data, trend_data, mode="overview", primary_run_name=None, runs_meta=None):
    """Build the JSON data blob embedded in the HTML."""
    blob = {
        "has_junit": junit_data is not None,
        "has_jacoco": jacoco_data is not None,
        "mode": mode,
        "primary_run": primary_run_name,
        "runs_meta": runs_meta or [],
    }

    if junit_data:
        blob["totals"] = junit_data["totals"]

        # Build feat->spec tree
        tree = {}
        all_tests = []
        for s in junit_data["suites"]:
            feat = s["feat"]
            spec = s["spec"]
            if feat not in tree:
                tree[feat] = {"specs": {}, "tests": 0, "passed": 0, "failed": 0}
            if spec not in tree[feat]["specs"]:
                tree[feat]["specs"][spec] = {"tests": 0, "passed": 0, "failed": 0}
            tree[feat]["tests"] += s["tests"]
            tree[feat]["passed"] += s["passed"]
            tree[feat]["failed"] += s["failures"]
            tree[feat]["specs"][spec]["tests"] += s["tests"]
            tree[feat]["specs"][spec]["passed"] += s["passed"]
            tree[feat]["specs"][spec]["failed"] += s["failures"]

            for tc in s["test_cases"]:
                all_tests.append({
                    "name": tc["name"],
                    "classname": tc["classname"],
                    "feat": tc["feat"],
                    "spec": tc["spec"],
                    "status": tc["status"],
                    "time_ms": tc["time_ms"],
                    "error_message": tc["error_message"],
                    "error_output": tc["error_output"][:500],  # Trim for embedding
                })

        blob["tree"] = tree
        blob["tests"] = all_tests

    if jacoco_data:
        # Coverage by package
        cov_packages = []
        for pkg in jacoco_data["packages"]:
            pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
            pl = pkg["counters"].get("LINE", {"missed": 0, "covered": 0})
            cov_packages.append({
                "name": pkg["name"],
                "methods_covered": pm["covered"],
                "methods_total": _counter_total(pm),
                "lines_covered": pl["covered"],
                "lines_total": _counter_total(pl),
                "classes": [{
                    "name": c["name"],
                    "methods_covered": c["counters"].get("METHOD", {"covered": 0})["covered"],
                    "methods_total": _counter_total(c["counters"].get("METHOD", {"missed": 0, "covered": 0})),
                    "methods": [{
                        "name": m["name"],
                        "covered": m["counters"].get("METHOD", {"covered": 0})["covered"] > 0,
                    } for m in c["methods"]]
                } for c in pkg["classes"]]
            })
        blob["coverage"] = {
            "counters": jacoco_data["counters"],
            "packages": cov_packages,
        }

    blob["history"] = trend_data

    return blob


# ==============================================================================
# CSS for v2 Layout
# ==============================================================================

CSS_V2 = """
/* ── Hanaden Dark v2 ── */
:root {
  --bg-0: #0a0a14; --bg-1: #0f0f1a; --bg-2: #1a1a2e; --bg-3: #16213e;
  --bg-hover: #232342; --border: #3a3a5a; --border-s: #2a2a44;
  --accent: #b4a0ff; --accent2: #93a0ff;
  --txt: #f8fafc; --txt2: #e2e8f0; --txt3: #b0bec5; --txt-h: #ffffff;
  --pass: #6ee7a0; --fail: #ff6b6b; --skip: #fcd34d; --err: #fdba74;
  --pass-bg: rgba(110,231,160,.18); --fail-bg: rgba(255,107,107,.25);
  --skip-bg: rgba(252,211,77,.18);
  --cov-hi: #6ee7a0; --cov-md: #fcd34d; --cov-lo: #ff6b6b;
  --font: 'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
  --mono: 'JetBrains Mono','Fira Code','Cascadia Code',monospace;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{font-size:14px;-webkit-font-smoothing:antialiased}
body{font-family:var(--font);background:var(--bg-0);color:var(--txt);
  display:flex;flex-direction:column;height:100vh;overflow:hidden}

/* ── Summary Bar ── */
.summary-bar{display:flex;align-items:center;gap:1rem;padding:.5rem 1rem;
  background:var(--bg-2);border-bottom:1px solid var(--border);font-size:.8rem;
  font-family:var(--mono);flex-shrink:0;min-height:36px}
.summary-bar .project{color:var(--txt-h);font-weight:700}
.summary-bar .sep{color:var(--txt3)}
.summary-bar .pass-n{color:var(--pass)}
.summary-bar .fail-n{color:var(--fail)}
.summary-bar .skip-n{color:var(--skip)}
.summary-bar .cov-n{color:var(--accent)}

/* ── Main Layout ── */
.main-layout{display:flex;flex:1;overflow:hidden}

/* ── Sidebar ── */
.sidebar{width:220px;min-width:220px;background:var(--bg-1);border-right:1px solid var(--border);
  display:flex;flex-direction:column;overflow:hidden;flex-shrink:0}
.sidebar-filter{padding:.5rem;border-bottom:1px solid var(--border)}
.sidebar-filter input{width:100%;padding:.35rem .5rem;background:var(--bg-2);
  border:1px solid var(--border);border-radius:4px;color:var(--txt);
  font-family:var(--mono);font-size:.75rem;outline:none}
.sidebar-filter input:focus{border-color:var(--accent)}
.sidebar-filter input::placeholder{color:var(--txt3)}
.sidebar-tree{flex:1;overflow-y:auto;padding:.25rem 0;font-size:.75rem}
.sidebar-tree::-webkit-scrollbar{width:6px}
.sidebar-tree::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
.tree-feat{cursor:pointer;padding:.25rem .5rem;color:var(--txt2);display:flex;
  align-items:center;gap:.25rem;user-select:none}
.tree-feat:hover{background:var(--bg-hover);color:var(--txt)}
.tree-feat.active{color:var(--accent);background:var(--bg-hover)}
.tree-feat .arrow{font-size:.6rem;width:.75rem;text-align:center;transition:transform .15s}
.tree-feat.open .arrow{transform:rotate(90deg)}
.tree-specs{display:none;padding-left:1.25rem}
.tree-feat.open+.tree-specs{display:block}
.tree-spec{cursor:pointer;padding:.2rem .5rem;color:var(--txt3);white-space:nowrap;
  overflow:hidden;text-overflow:ellipsis}
.tree-spec:hover{background:var(--bg-hover);color:var(--txt)}
.tree-spec.active{color:var(--accent);background:var(--bg-hover)}
.tree-all{cursor:pointer;padding:.35rem .5rem;color:var(--txt-h);font-weight:600;
  border-bottom:1px solid var(--border-s);margin-bottom:.25rem}
.tree-all:hover{background:var(--bg-hover)}
.tree-all.active{color:var(--accent)}
.tree-count{font-size:.65rem;color:var(--txt3);margin-left:auto;font-family:var(--mono)}
.tree-fail-count{color:var(--fail)}

/* ── Content Area ── */
.content{flex:1;display:flex;flex-direction:column;overflow:hidden}

/* ── Tabs ── */
.tabs{display:flex;gap:0;border-bottom:1px solid var(--border);flex-shrink:0;
  background:var(--bg-1);padding:0 1rem}
.tab{padding:.5rem 1rem;cursor:pointer;color:var(--txt3);font-weight:500;
  font-size:.8rem;border-bottom:2px solid transparent;margin-bottom:-1px;
  transition:color .1s,border-color .1s;user-select:none}
.tab:hover{color:var(--txt)}
.tab.active{color:var(--accent);border-bottom-color:var(--accent)}
.tab .badge{font-size:.65rem;background:var(--fail-bg);color:var(--fail);
  padding:1px 6px;border-radius:8px;margin-left:4px;font-family:var(--mono)}

/* ── Tab Panes ── */
.tab-pane{display:none;flex:1;overflow-y:auto;padding:1rem}
.tab-pane.active{display:block}
.tab-pane::-webkit-scrollbar{width:8px}
.tab-pane::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px}

/* ── Dashboard Charts ── */
.chart-grid{display:grid;grid-template-columns:1fr 1fr;gap:.75rem;margin-bottom:1rem}
.chart-box{background:var(--bg-2);border:1px solid var(--border);border-radius:6px;
  padding:.75rem;min-height:180px}
.chart-box h3{font-size:.75rem;color:var(--txt2);text-transform:uppercase;
  letter-spacing:.03em;margin-bottom:.5rem;font-weight:600}
@media(max-width:900px){.chart-grid{grid-template-columns:1fr}}

/* ── Tables ── */
.tbl-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-size:.8rem}
thead th{background:var(--bg-3);color:var(--txt2);font-weight:600;text-transform:uppercase;
  font-size:.7rem;letter-spacing:.04em;padding:.4rem .6rem;text-align:left;
  border-bottom:2px solid var(--border);cursor:pointer;user-select:none;
  white-space:nowrap}
thead th:hover{color:var(--accent)}
tbody tr{border-bottom:1px solid var(--border-s);transition:background .1s}
tbody tr:hover{background:var(--bg-hover)}
td{padding:.35rem .6rem;vertical-align:middle}
.ar{text-align:right}
.mn{font-family:var(--mono);font-size:.75rem}
a{color:var(--accent);text-decoration:none}
a:hover{text-decoration:underline}

/* ── Status ── */
.s-pass{color:var(--pass)} .s-fail{color:var(--fail)} .s-skip{color:var(--skip)}
.s-err{color:var(--err)}
.status-icon{font-size:.9rem}

/* ── Progress Bar ── */
.pbar{display:flex;align-items:center;gap:.4rem}
.pbar-track{height:6px;background:var(--bg-0);border-radius:3px;flex:1;min-width:60px;overflow:hidden}
.pbar-fill{height:100%;border-radius:3px}
.pbar-fill.hi{background:var(--cov-hi)} .pbar-fill.md{background:var(--cov-md)} .pbar-fill.lo{background:var(--cov-lo)}
.pbar-pct{font-family:var(--mono);font-size:.7rem;min-width:3em;text-align:right;color:var(--txt2)}

/* ── Failures ── */
.fail-item{margin-bottom:.5rem}
.fail-summary{cursor:pointer;padding:.4rem .6rem;background:var(--bg-3);border-radius:4px;
  color:var(--txt2);font-size:.8rem;display:flex;align-items:center;gap:.4rem}
.fail-summary:hover{color:var(--txt)}
.fail-output{padding:.5rem;background:var(--bg-0);border:1px solid var(--border-s);
  border-radius:0 0 4px 4px;margin-top:-2px;font-family:var(--mono);font-size:.7rem;
  white-space:pre-wrap;word-break:break-all;color:var(--fail);max-height:200px;overflow-y:auto}

/* ── Trend Charts ── */
.trend-chart{margin-bottom:1rem}
.trend-chart h3{font-size:.75rem;color:var(--txt2);text-transform:uppercase;
  letter-spacing:.03em;margin-bottom:.5rem;font-weight:600}

/* ── SVG common ── */
svg text{fill:var(--txt3);font-family:var(--mono)}

/* -- Footer -- */
.footer-bar{padding:.3rem 1rem;background:var(--bg-2);border-top:1px solid var(--border);
  font-size:.65rem;color:var(--txt3);text-align:center;flex-shrink:0}

/* -- Mode Label -- */
.mode-label{color:var(--accent);font-weight:600;font-size:.75rem}

/* -- Run List in Sidebar -- */
.run-list-section{border-top:1px solid var(--border);max-height:180px;overflow-y:auto;flex-shrink:0}
.run-list-section::-webkit-scrollbar{width:6px}
.run-list-section::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
.run-list-title{padding:.35rem .5rem;color:var(--txt2);font-weight:600;font-size:.7rem;
  text-transform:uppercase;letter-spacing:.03em;border-bottom:1px solid var(--border-s)}
.run-item{cursor:pointer;padding:.2rem .5rem;font-size:.7rem;display:flex;
  justify-content:space-between;align-items:center;color:var(--txt3);
  border-bottom:1px solid var(--border-s);transition:background .1s}
.run-item:hover{background:var(--bg-hover);color:var(--txt)}
.run-item.active{color:var(--accent);background:var(--bg-hover)}
.run-ts{font-family:var(--mono);font-size:.65rem}
.run-stats{font-family:var(--mono);font-size:.65rem;color:var(--txt3)}

/* -- Overview Dashboard -- */
.overview-header{margin-bottom:.75rem}
.overview-header h2{font-size:1rem;color:var(--txt-h);font-weight:600}
.run-history-table{margin-top:1rem}
.run-history-table h3{font-size:.75rem;color:var(--txt2);text-transform:uppercase;
  letter-spacing:.03em;margin-bottom:.5rem;font-weight:600}
.run-history-row{cursor:pointer}
.run-history-row:hover{background:var(--bg-3) !important}
"""

# ==============================================================================
# JavaScript — Tab switching, tree toggle, filter, table sort
# ==============================================================================

JS_V2 = """
(function(){
  // ── Tab Switching ──
  var tabs = document.querySelectorAll('.tab');
  var panes = document.querySelectorAll('.tab-pane');
  tabs.forEach(function(t){
    t.addEventListener('click', function(){
      tabs.forEach(function(x){x.classList.remove('active')});
      panes.forEach(function(x){x.classList.remove('active')});
      t.classList.add('active');
      document.getElementById('pane-'+t.dataset.tab).classList.add('active');
    });
  });

  // ── Tree Toggle ──
  document.querySelectorAll('.tree-feat').forEach(function(f){
    f.addEventListener('click', function(e){
      f.classList.toggle('open');
    });
  });

  // ── Sidebar Filter (text) ──
  var filterInput = document.getElementById('sidebar-filter');
  if(filterInput){
    filterInput.addEventListener('input', function(){
      var q = this.value.toLowerCase();
      document.querySelectorAll('.tree-feat').forEach(function(f){
        var label = f.textContent.toLowerCase();
        var specs = f.nextElementSibling;
        var anyMatch = label.indexOf(q) >= 0;
        if(specs && specs.classList.contains('tree-specs')){
          specs.querySelectorAll('.tree-spec').forEach(function(s){
            var sm = s.textContent.toLowerCase().indexOf(q) >= 0;
            s.style.display = sm || !q ? '' : 'none';
            if(sm) anyMatch = true;
          });
        }
        f.style.display = anyMatch || !q ? '' : 'none';
        if(specs) specs.style.display = anyMatch && f.classList.contains('open') ? 'block' : 'none';
      });
    });
  }

  // ── Sidebar Click → Filter Content ──
  var D = window.__DATA || {};
  document.querySelectorAll('.tree-feat, .tree-spec, .tree-all').forEach(function(el){
    el.addEventListener('click', function(e){
      // Clear other active states
      document.querySelectorAll('.tree-feat, .tree-spec, .tree-all').forEach(function(x){
        x.classList.remove('active');
      });
      el.classList.add('active');

      var feat = el.dataset.feat || '';
      var spec = el.dataset.spec || '';
      filterContent(feat, spec);
    });
  });

  function filterContent(feat, spec){
    // Filter test rows
    document.querySelectorAll('#tests-tbody tr').forEach(function(r){
      var rf = r.dataset.feat || '';
      var rs = r.dataset.spec || '';
      var show = (!feat || rf === feat) && (!spec || rs === spec);
      r.style.display = show ? '' : 'none';
    });
    // Filter coverage rows
    document.querySelectorAll('#cov-tbody tr').forEach(function(r){
      var rf = r.dataset.pkg || '';
      var show = !feat || rf === feat;
      r.style.display = show ? '' : 'none';
    });
    // Filter failure items
    document.querySelectorAll('.fail-item').forEach(function(r){
      var rf = r.dataset.feat || '';
      var rs = r.dataset.spec || '';
      var show = (!feat || rf === feat) && (!spec || rs === spec);
      r.style.display = show ? '' : 'none';
    });
    // Update filter indicator
    var ind = document.getElementById('filter-indicator');
    if(ind){
      if(feat){
        ind.textContent = spec ? feat + ' › ' + spec : feat;
        ind.style.display = 'inline';
      } else {
        ind.style.display = 'none';
      }
    }
  }

  // ── Table Sort ──
  document.querySelectorAll('table[data-sortable] thead th').forEach(function(th){
    th.addEventListener('click', function(){
      var table = th.closest('table');
      var tbody = table.querySelector('tbody');
      if(!tbody) return;
      var rows = Array.from(tbody.querySelectorAll('tr'));
      var ci = Array.from(th.parentNode.children).indexOf(th);
      var asc = th.dataset.sd !== 'a';
      th.dataset.sd = asc ? 'a' : 'd';
      table.querySelectorAll('thead th').forEach(function(h){if(h!==th)delete h.dataset.sd});
      rows.sort(function(a,b){
        var av = a.children[ci].dataset.sv || a.children[ci].textContent.trim();
        var bv = b.children[ci].dataset.sv || b.children[ci].textContent.trim();
        var an = parseFloat(av), bn = parseFloat(bv);
        if(!isNaN(an)&&!isNaN(bn)) return asc?an-bn:bn-an;
        return asc?av.localeCompare(bv):bv.localeCompare(av);
      });
      rows.forEach(function(r){tbody.appendChild(r)});
    });
  });

  // -- Overview / Detail Mode Switching --
  var overviewPanel = document.getElementById('overview-panel');
  var detailPanel = document.getElementById('detail-panel');
  var modeLabel = document.getElementById('mode-label');

  function showOverview() {
    if (overviewPanel) overviewPanel.style.display = 'block';
    if (detailPanel) detailPanel.style.display = 'none';
    if (modeLabel) modeLabel.textContent = 'Overview';
    // Clear run-item active states
    document.querySelectorAll('.run-item').forEach(function(r){ r.classList.remove('active'); });
    document.querySelectorAll('.run-history-row').forEach(function(r){ r.classList.remove('active'); });
  }

  function showDetail(runName) {
    if (overviewPanel) overviewPanel.style.display = 'none';
    if (detailPanel) detailPanel.style.display = 'block';
    if (modeLabel) modeLabel.textContent = runName ? runName.substring(0, 25) : 'Detail';
    // Highlight the matching run-item
    document.querySelectorAll('.run-item').forEach(function(r){
      r.classList.toggle('active', r.dataset.run === runName);
    });
    document.querySelectorAll('.run-history-row').forEach(function(r){
      r.classList.toggle('active', r.dataset.run === runName);
    });
  }

  // Run history table row clicks -> show detail
  document.querySelectorAll('.run-history-row').forEach(function(row){
    row.addEventListener('click', function(){
      showDetail(row.dataset.run);
    });
  });

  // Sidebar run-item clicks -> show detail
  document.querySelectorAll('.run-item').forEach(function(item){
    item.addEventListener('click', function(){
      showDetail(item.dataset.run);
    });
  });

  // "All" tree node -> return to overview
  var allNode = document.querySelector('.tree-all');
  if (allNode) {
    allNode.addEventListener('click', function(){
      showOverview();
    });
  }
})();
"""


# ==============================================================================
# SVG Chart Generators
# ==============================================================================

def svg_donut(passed, failed, skipped, size=160):
    """Donut chart: pass (green), fail (red), skip (yellow)."""
    total = passed + failed + skipped
    if total == 0:
        return '<p style="color:var(--txt3)">No data</p>'

    r = size // 2 - 10
    cx = cy = size // 2
    circumference = 2 * 3.14159 * r
    pct_pass = passed / total
    pct_fail = failed / total

    # Arcs via stroke-dasharray
    pass_len = circumference * pct_pass
    fail_len = circumference * pct_fail
    skip_len = circumference - pass_len - fail_len

    pass_pct_str = f"{pct_pass * 100:.1f}%"

    return f'''<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}">
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="var(--bg-0)" stroke-width="16"/>
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="var(--pass)" stroke-width="16"
    stroke-dasharray="{pass_len:.1f} {circumference:.1f}"
    stroke-dashoffset="0" transform="rotate(-90 {cx} {cy})"/>
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="var(--fail)" stroke-width="16"
    stroke-dasharray="{fail_len:.1f} {circumference:.1f}"
    stroke-dashoffset="{-pass_len:.1f}" transform="rotate(-90 {cx} {cy})"/>
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="var(--skip)" stroke-width="16"
    stroke-dasharray="{skip_len:.1f} {circumference:.1f}"
    stroke-dashoffset="{-(pass_len + fail_len):.1f}" transform="rotate(-90 {cx} {cy})"/>
  <text x="{cx}" y="{cy - 5}" text-anchor="middle" font-size="18" font-weight="700" fill="var(--txt-h)">{pass_pct_str}</text>
  <text x="{cx}" y="{cy + 12}" text-anchor="middle" font-size="10" fill="var(--txt3)">pass rate</text>
  <text x="{cx - 30}" y="{size - 4}" font-size="9" fill="var(--pass)">{passed} ✓</text>
  <text x="{cx + 10}" y="{size - 4}" font-size="9" fill="var(--fail)">{failed} ✗</text>
</svg>'''




def svg_coverage_bars(packages, width=360, bar_height=18):
    """Coverage bar chart by package."""
    items = []
    for p in packages:
        mt = p["methods_total"]
        pct = (p["methods_covered"] / mt * 100) if mt else 0
        color = "var(--cov-hi)" if pct >= 80 else "var(--cov-md)" if pct >= 50 else "var(--cov-lo)"
        items.append((p["name"], pct, color))
    items.sort(key=lambda x: -x[1])

    if not items:
        return '<p style="color:var(--txt3)">No coverage data</p>'
    h = len(items) * (bar_height + 4) + 8
    bars = []
    for i, (label, pct, color) in enumerate(items):
        y = i * (bar_height + 4) + 4
        bw = (pct / 100) * (width - 170)
        lbl = label[:18]
        bars.append(
            f'<text x="0" y="{y + bar_height - 4}" font-size="10" fill="var(--txt2)">{escape(lbl)}</text>'
            f'<rect x="120" y="{y}" width="{max(bw, 1):.0f}" height="{bar_height - 2}" fill="{color}" rx="3"/>'
            f'<text x="{125 + bw:.0f}" y="{y + bar_height - 5}" font-size="9" fill="var(--txt3)">{pct:.0f}%</text>'
        )
    return f'<svg width="{width}" height="{h}" viewBox="0 0 {width} {h}">{"".join(bars)}</svg>'


def svg_trend_line(history, width=500, height=120):
    """Pass rate trend line chart."""
    if len(history) < 2:
        return '<p style="color:var(--txt3)">Need ≥2 runs for trends</p>'

    points = []
    for h in history:
        t = h["tests_total"]
        p = h["tests_passed"]
        pct = (p / t * 100) if t else 0
        points.append(pct)

    n = len(points)
    min_v = max(min(points) - 5, 0)
    max_v = min(max(points) + 5, 100)
    if max_v == min_v:
        max_v = min_v + 10

    pad_l, pad_r, pad_t, pad_b = 40, 20, 15, 25
    chart_w = width - pad_l - pad_r
    chart_h = height - pad_t - pad_b

    # Grid lines
    grid = []
    for yval in range(int(min_v), int(max_v) + 1, max(1, (int(max_v) - int(min_v)) // 4)):
        y = pad_t + chart_h - (yval - min_v) / (max_v - min_v) * chart_h
        grid.append(f'<line x1="{pad_l}" y1="{y:.0f}" x2="{width - pad_r}" y2="{y:.0f}" stroke="var(--border-s)" stroke-width="1"/>')
        grid.append(f'<text x="{pad_l - 4}" y="{y + 3:.0f}" text-anchor="end" font-size="9">{yval:.0f}%</text>')

    # Data line + dots
    coords = []
    for i, v in enumerate(points):
        x = pad_l + (i / max(n - 1, 1)) * chart_w
        y = pad_t + chart_h - (v - min_v) / (max_v - min_v) * chart_h
        coords.append((x, y, v))

    polyline = " ".join(f"{x:.1f},{y:.1f}" for x, y, _ in coords)
    dots = "".join(
        f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3" fill="var(--pass)"/>'
        f'<text x="{x:.1f}" y="{y - 6:.1f}" text-anchor="middle" font-size="8" fill="var(--pass)">{v:.1f}%</text>'
        for x, y, v in coords
    )

    # X-axis labels
    xlabels = []
    step = max(1, n // 5)
    for i in range(0, n, step):
        x = pad_l + (i / max(n - 1, 1)) * chart_w
        label = fmt_ts_short(history[i].get("timestamp", ""))
        xlabels.append(f'<text x="{x:.0f}" y="{height - 2}" text-anchor="middle" font-size="8">{escape(label)}</text>')

    return f'''<svg width="{width}" height="{height}" viewBox="0 0 {width} {height}">
{"".join(grid)}
<polyline points="{polyline}" fill="none" stroke="var(--pass)" stroke-width="2"/>
{dots}
{"".join(xlabels)}
</svg>'''


def svg_duration_trend(history, width=500, height=120):
    """Duration trend: bars for test count, line for duration."""
    if len(history) < 2:
        return '<p style="color:var(--txt3)">Need ≥2 runs</p>'

    n = len(history)
    pad_l, pad_r, pad_t, pad_b = 40, 50, 15, 25
    chart_w = width - pad_l - pad_r
    chart_h = height - pad_t - pad_b
    bar_w = max(chart_w / n * 0.6, 4)

    counts = [h["tests_total"] for h in history]
    durs = [h["total_duration_ms"] for h in history]
    max_c = max(counts) if counts else 1
    max_d = max(durs) if durs else 1
    if max_c == 0: max_c = 1
    if max_d == 0: max_d = 1

    bars = []
    line_pts = []
    for i in range(n):
        x = pad_l + (i / max(n - 1, 1)) * chart_w
        bh = (counts[i] / max_c) * chart_h
        by = pad_t + chart_h - bh
        bars.append(f'<rect x="{x - bar_w/2:.1f}" y="{by:.1f}" width="{bar_w:.1f}" height="{bh:.1f}" fill="var(--accent)" rx="2" opacity="0.6"/>')

        dy = pad_t + chart_h - (durs[i] / max_d) * chart_h
        line_pts.append(f"{x:.1f},{dy:.1f}")
        bars.append(f'<circle cx="{x:.1f}" cy="{dy:.1f}" r="3" fill="var(--txt-h)"/>')

    polyline = " ".join(line_pts)

    # Y-axis labels
    lbl_l = f'<text x="{pad_l - 4}" y="{pad_t + 4}" text-anchor="end" font-size="8">{max_c}</text>'
    lbl_r = f'<text x="{width - pad_r + 4}" y="{pad_t + 4}" font-size="8">{fmt_dur(max_d)}</text>'
    lbl_lb = f'<text x="{pad_l - 4}" y="{pad_t + chart_h}" text-anchor="end" font-size="8">0</text>'

    return f'''<svg width="{width}" height="{height}" viewBox="0 0 {width} {height}">
{"".join(bars)}
<polyline points="{polyline}" fill="none" stroke="var(--txt-h)" stroke-width="2"/>
{lbl_l}{lbl_r}{lbl_lb}
<text x="{pad_l}" y="{height - 2}" font-size="8" fill="var(--accent)">■ tests</text>
<text x="{pad_l + 60}" y="{height - 2}" font-size="8" fill="var(--txt-h)">— duration</text>
</svg>'''


def svg_failures_trend(history, width=500, height=100):
    """Failures over time — area chart."""
    if len(history) < 2:
        return '<p style="color:var(--txt3)">Need ≥2 runs</p>'

    n = len(history)
    pad_l, pad_r, pad_t, pad_b = 40, 20, 10, 25
    chart_w = width - pad_l - pad_r
    chart_h = height - pad_t - pad_b

    fails = [h["tests_failed"] for h in history]
    max_f = max(fails) if fails else 1
    if max_f == 0: max_f = 1

    pts_top = []
    pts_bottom = []
    for i in range(n):
        x = pad_l + (i / max(n - 1, 1)) * chart_w
        y = pad_t + chart_h - (fails[i] / max_f) * chart_h
        pts_top.append(f"{x:.1f},{y:.1f}")
        pts_bottom.append(f"{x:.1f},{pad_t + chart_h}")

    polygon = " ".join(pts_top + list(reversed(pts_bottom)))
    line = " ".join(pts_top)

    lbl = f'<text x="{pad_l - 4}" y="{pad_t + 4}" text-anchor="end" font-size="8">{max_f}</text>'

    return f'''<svg width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<polygon points="{polygon}" fill="var(--fail-bg)"/>
<polyline points="{line}" fill="none" stroke="var(--fail)" stroke-width="2"/>
{lbl}
<text x="{pad_l}" y="{height - 2}" font-size="8" fill="var(--fail)">failures</text>
</svg>'''


# ==============================================================================
# HTML Page Builder
# ==============================================================================

def pbar_html(covered, total):
    """Inline progress bar HTML."""
    pct = (covered / total * 100) if total else 0
    level = "hi" if pct >= 80 else "md" if pct >= 50 else "lo"
    return (
        f'<div class="pbar">'
        f'<span class="pbar-pct">{pct:.0f}%</span>'
        f'<div class="pbar-track"><div class="pbar-fill {level}" style="width:{pct:.1f}%"></div></div>'
        f'</div>'
    )


def status_icon(status):
    s = status.upper()
    if s == "PASS":
        return '<span class="status-icon s-pass">PASS</span>'
    elif s in ("FAIL", "ERROR"):
        return '<span class="status-icon s-fail">FAIL</span>'
    elif s == "SKIP":
        return '<span class="status-icon s-skip">SKIP</span>'
    return s


def generate_html(junit_data, jacoco_data, trend_data, mode="overview", primary_run_name=None, runs_meta=None):
    """Generate the complete single-page HTML report."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    has_junit = junit_data is not None
    has_jacoco = jacoco_data is not None

    # ── Summary bar values (from detail/latest run) ──
    tests_total = junit_data["totals"]["tests"] if has_junit else 0
    tests_passed = junit_data["totals"]["passed"] if has_junit else 0
    tests_failed = (junit_data["totals"]["failures"] + junit_data["totals"].get("errors", 0)) if has_junit else 0
    tests_skipped = junit_data["totals"]["skipped"] if has_junit else 0
    time_ms = junit_data["totals"]["time_ms"] if has_junit else 0

    cov_pct_str = "--"
    if has_jacoco:
        mc = jacoco_data["counters"].get("METHOD", {"missed": 0, "covered": 0})
        mt = _counter_total(mc)
        cov_pct_str = f"{_counter_pct(mc):.1f}%" if mt else "--"

    # ── Sidebar tree ──
    tree_html = '<div class="tree-all active" data-feat="" data-spec="">All</div>'
    if has_junit:
        feats = {}
        for s in junit_data["suites"]:
            f, sp = s["feat"], s["spec"]
            if f not in feats:
                feats[f] = {}
            if sp not in feats[f]:
                feats[f][sp] = {"tests": 0, "failed": 0}
            feats[f][sp]["tests"] += s["tests"]
            feats[f][sp]["failed"] += s["failures"]

        for feat_name in sorted(feats.keys()):
            feat_tests = sum(v["tests"] for v in feats[feat_name].values())
            feat_fails = sum(v["failed"] for v in feats[feat_name].values())
            fail_badge = f' <span class="tree-fail-count">{feat_fails}x</span>' if feat_fails else ''
            tree_html += f'''<div class="tree-feat" data-feat="{escape(feat_name)}">
  <span class="arrow">&#9656;</span> {escape(feat_name)}
  <span class="tree-count">{feat_tests}{fail_badge}</span>
</div>
<div class="tree-specs">'''
            for spec_name in sorted(feats[feat_name].keys()):
                sd = feats[feat_name][spec_name]
                sf = f' <span class="tree-fail-count">{sd["failed"]}x</span>' if sd["failed"] else ''
                tree_html += f'<div class="tree-spec" data-feat="{escape(feat_name)}" data-spec="{escape(spec_name)}">{escape(spec_name)} <span class="tree-count">{sd["tests"]}{sf}</span></div>'
            tree_html += '</div>'

    # ── Run list for sidebar ──
    run_list_html = ''
    if runs_meta:
        run_list_html = '<div class="run-list-section"><div class="run-list-title">Run History</div>'
        for rm in reversed(runs_meta or []):
            active_cls = ' active' if rm['dir_name'] == primary_run_name and mode == 'detail' else ''
            ts_short = rm.get('timestamp', rm['dir_name'])[:19]
            fail_n = rm.get('tests_failed', 0)
            fail_badge = f'<span class="tree-fail-count">{fail_n}</span>' if fail_n else ''
            run_list_html += f'<div class="run-item{active_cls}" data-run="{escape(rm["dir_name"])}" title="{escape(rm["dir_name"])}">'
            run_list_html += f'<span class="run-ts">{escape(ts_short)}</span>'
            run_list_html += f'<span class="run-stats">{rm.get("tests_total",0)}t {fail_badge}</span>'
            run_list_html += '</div>'
        run_list_html += '</div>'

    # ── Overview Dashboard (aggregate trends) ──
    overview_html = ''
    if len(trend_data) >= 2:
        overview_html = f'''
<div class="overview-header"><h2>Aggregate Overview &mdash; {len(trend_data)} runs</h2></div>
<div class="chart-grid">
  <div class="chart-box"><h3>Pass Rate Trend</h3>{svg_trend_line(trend_data, width=420, height=160)}</div>
  <div class="chart-box"><h3>Test Count &amp; Duration</h3>{svg_duration_trend(trend_data, width=420, height=160)}</div>
  <div class="chart-box"><h3>Failures Over Time</h3>{svg_failures_trend(trend_data, width=420, height=140)}</div>
  <div class="chart-box"><h3>Latest Run Summary</h3>{svg_donut(tests_passed, tests_failed, tests_skipped) if has_junit else '<p style="color:var(--txt3)">No test data</p>'}</div>
</div>
<div class="run-history-table">
  <h3>Run History</h3>
  <div class="tbl-wrap">
  <table data-sortable>
  <thead><tr><th>Run</th><th class="ar">Tests</th><th class="ar">Pass</th><th class="ar">Fail</th><th class="ar">Duration</th></tr></thead>
  <tbody>'''
        for rm in reversed(runs_meta or []):
            ts_short = rm.get('timestamp', rm['dir_name'])[:19]
            fail_cls = ' class="s-fail"' if rm.get('tests_failed', 0) > 0 else ''
            overview_html += f'''<tr class="run-history-row" data-run="{escape(rm['dir_name'])}">
<td class="mn">{escape(ts_short)}</td>
<td class="ar mn" data-sv="{rm.get('tests_total',0)}">{rm.get('tests_total',0)}</td>
<td class="ar mn s-pass" data-sv="{rm.get('tests_passed',0)}">{rm.get('tests_passed',0)}</td>
<td class="ar mn{' s-fail' if rm.get('tests_failed',0) else ''}" data-sv="{rm.get('tests_failed',0)}">{rm.get('tests_failed',0)}</td>
<td class="ar mn" data-sv="{rm.get('total_duration_ms',0)}">{fmt_dur(rm.get('total_duration_ms',0))}</td>
</tr>'''
        overview_html += '</tbody></table></div></div>'
    elif len(trend_data) == 1:
        overview_html = f'''
<div class="overview-header"><h2>Single Run Overview</h2>
<p style="color:var(--txt3)">Run additional test executions with <code>run-all --timed</code> to see trends.</p></div>
<div class="chart-grid">
  <div class="chart-box"><h3>Test Results</h3>{svg_donut(tests_passed, tests_failed, tests_skipped) if has_junit else '<p style="color:var(--txt3)">No test data</p>'}</div>
  <div class="chart-box"><h3>Run Info</h3><p class="mn" style="color:var(--txt2)">{tests_total} tests, {fmt_dur(time_ms)}</p></div>
</div>'''
    else:
        overview_html = '<p style="color:var(--txt3);padding:1rem">No run data available. Run tests with <code>run-all --timed</code>.</p>'

    # ── Detail Dashboard (single-run) ──
    donut_svg = svg_donut(tests_passed, tests_failed, tests_skipped) if has_junit else '<p style="color:var(--txt3)">No test data</p>'

    timing_items = []
    if has_junit:
        feat_times = {}
        for s in junit_data["suites"]:
            feat_times[s["feat"]] = feat_times.get(s["feat"], 0) + int(s["time"] * 1000)
        timing_items = [(f, ms, "var(--accent)") for f, ms in sorted(feat_times.items(), key=lambda x: -x[1])[:8]]

    timing_svg = '<p style="color:var(--txt3)">No timing data</p>'
    if timing_items:
        max_v = max(v for _, v, _ in timing_items) or 1
        h = len(timing_items) * 22 + 8
        bars = []
        for i, (label, val, color) in enumerate(timing_items):
            y = i * 22 + 4
            bw = (val / max_v) * 210
            bars.append(
                f'<text x="0" y="{y + 14}" font-size="10" fill="var(--txt2)">{escape(label[:18])}</text>'
                f'<rect x="120" y="{y}" width="{bw:.0f}" height="16" fill="{color}" rx="3"/>'
                f'<text x="{125 + bw:.0f}" y="{y + 13}" font-size="9" fill="var(--txt3)">{fmt_dur(val)}</text>'
            )
        timing_svg = f'<svg width="340" height="{h}" viewBox="0 0 340 {h}">{"".join(bars)}</svg>'

    cov_svg = '<p style="color:var(--txt3)">No coverage data</p>'
    if has_jacoco:
        cov_svg = svg_coverage_bars(
            [{"name": p["name"], "methods_covered": p["counters"].get("METHOD", {"covered": 0})["covered"],
              "methods_total": _counter_total(p["counters"].get("METHOD", {"missed": 0, "covered": 0}))}
             for p in jacoco_data["packages"]],
            width=340
        )
    elif has_junit:
        # Use test pass-rate per feature as coverage proxy
        feat_cov = {}
        for s in junit_data["suites"]:
            f = s["feat"]
            if f not in feat_cov:
                feat_cov[f] = {"passed": 0, "total": 0}
            feat_cov[f]["passed"] += s["passed"]
            feat_cov[f]["total"] += s["tests"]
        cov_items = [{"name": f, "methods_covered": d["passed"], "methods_total": d["total"]}
                     for f, d in sorted(feat_cov.items())]
        cov_svg = svg_coverage_bars(cov_items, width=340)

    trend_spark = '<p style="color:var(--txt3)">Need 2+ runs for trends</p>'
    if len(trend_data) >= 2:
        trend_spark = svg_trend_line(trend_data, width=340, height=100)

    detail_dashboard_html = f'''
<div class="chart-grid">
  <div class="chart-box"><h3>Test Results</h3>{donut_svg}</div>
  <div class="chart-box"><h3>Timing by Feature</h3>{timing_svg}</div>
  <div class="chart-box"><h3>Coverage by Feature</h3>{cov_svg}</div>
  <div class="chart-box"><h3>Trend: Pass Rate</h3>{trend_spark}</div>
</div>'''

    # ── Tests tab ──
    tests_rows = ""
    if has_junit:
        for s in junit_data["suites"]:
            for tc in s["test_cases"]:
                tests_rows += f'''<tr data-feat="{escape(tc['feat'])}" data-spec="{escape(tc['spec'])}">
<td>{status_icon(tc['status'])}</td>
<td class="mn" data-sv="{escape(tc['name'][:20])}">{escape(tc['name'][:60])}</td>
<td>{escape(tc['feat'])}</td>
<td>{escape(tc['spec'])}</td>
<td class="ar mn" data-sv="{tc['time_ms']}">{fmt_dur(tc['time_ms'])}</td>
</tr>'''

    tests_html = f'''
<div class="tbl-wrap">
<table data-sortable>
<thead><tr><th style="width:30px">St</th><th>Test</th><th>Feature</th><th>Spec</th><th class="ar">Time</th></tr></thead>
<tbody id="tests-tbody">{tests_rows}</tbody>
</table>
</div>'''

    # ── Coverage tab ──
    cov_rows = ""
    if has_jacoco:
        for pkg in jacoco_data["packages"]:
            pm = pkg["counters"].get("METHOD", {"missed": 0, "covered": 0})
            pl = pkg["counters"].get("LINE", {"missed": 0, "covered": 0})
            mt = _counter_total(pm)
            lt = _counter_total(pl)
            pbar = pbar_html(pm["covered"], mt)
            cov_rows += f'''<tr data-pkg="{escape(pkg['name'])}">
<td>{escape(pkg['name'])}</td>
<td class="mn">{pm['covered']}/{mt}</td>
<td data-sv="{_counter_pct(pm):.1f}">{pbar}</td>
<td class="mn">{pl['covered']}/{lt}</td>
<td class="mn">{len(pkg['classes'])}</td>
</tr>'''

    if not cov_rows and has_junit:
        # Show pass-rate per feature as coverage proxy when no JaCoCo
        for s_feat in sorted(set(s["feat"] for s in junit_data["suites"])):
            f_tests = sum(s["tests"] for s in junit_data["suites"] if s["feat"] == s_feat)
            f_pass = sum(s["passed"] for s in junit_data["suites"] if s["feat"] == s_feat)
            f_fail = f_tests - f_pass
            pbar = pbar_html(f_pass, f_tests)
            specs_n = len(set(s["spec"] for s in junit_data["suites"] if s["feat"] == s_feat))
            cov_rows += f'''<tr>
<td>{escape(s_feat)}</td>
<td class="mn">{f_pass}/{f_tests}</td>
<td data-sv="{(f_pass/f_tests*100) if f_tests else 0:.1f}">{pbar}</td>
<td class="mn">{f_fail} fail</td>
<td class="mn">{specs_n} specs</td>
</tr>'''

    cov_label = "Package" if has_jacoco else "Feature"
    cov_c3 = "Lines" if has_jacoco else "Failures"
    cov_c4 = "Classes" if has_jacoco else "Specs"
    cov_html = f'''
<div class="tbl-wrap">
<table data-sortable>
<thead><tr><th>{cov_label}</th><th>Pass/Total</th><th>Coverage</th><th>{cov_c3}</th><th>{cov_c4}</th></tr></thead>
<tbody id="cov-tbody">{cov_rows}</tbody>
</table>
</div>'''

    # ── Failures tab ──
    fail_items = ""
    fail_count = 0
    if has_junit:
        for s in junit_data["suites"]:
            for tc in s["test_cases"]:
                if tc["status"] in ("FAIL", "ERROR"):
                    fail_count += 1
                    output = ""
                    if tc.get("error_output"):
                        output = f'<div class="fail-output">{escape(tc["error_output"][:500])}</div>'
                    fail_items += f'''<details class="fail-item" data-feat="{escape(tc['feat'])}" data-spec="{escape(tc['spec'])}">
<summary class="fail-summary">{status_icon(tc['status'])} <span class="mn">{escape(tc['name'][:70])}</span></summary>
{output}
</details>'''

    if not fail_items:
        fail_items = '<p style="color:var(--pass);padding:1rem">No failures</p>'

    # ── Trends tab ──
    trends_html = ""
    if len(trend_data) >= 2:
        trends_html = f'''
<div class="trend-chart"><h3>Pass Rate Trend (last {len(trend_data)} runs)</h3>{svg_trend_line(trend_data, width=700, height=160)}</div>
<div class="trend-chart"><h3>Test Count &amp; Duration</h3>{svg_duration_trend(trend_data, width=700, height=140)}</div>
<div class="trend-chart"><h3>Failures Over Time</h3>{svg_failures_trend(trend_data, width=700, height=120)}</div>'''
    else:
        trends_html = '<p style="color:var(--txt3);padding:1rem">Need 2+ run-all executions to show trends. Run the full suite with <code>run-all --timed</code> multiple times.</p>'

    # ── Assemble ──
    fail_badge = f'<span class="badge">{fail_count}</span>' if fail_count else ''
    mode_indicator = "Overview" if mode == "overview" else escape(primary_run_name or "")
    initial_dash = overview_html if mode == "overview" else detail_dashboard_html

    # Build data blob
    data_blob = build_data_blob(junit_data, jacoco_data, trend_data, mode, primary_run_name, runs_meta)
    data_json = json.dumps(data_blob, separators=(',', ':'))

    return f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Test Report -- bwrap-enhanced</title>
<meta name="description" content="Test results and coverage report for bwrap-enhanced">
<meta name="generator" content="merged_html_report.py v0.4.0 -- hanaden-bwrap-enhanced test harness tooling">
<style>{CSS_V2}</style>
</head>
<body>

<!-- Summary Bar -->
<div class="summary-bar">
  <span class="project">bwrap-enhanced</span>
  <span class="sep">|</span>
  <span id="mode-label" class="mode-label">{mode_indicator}</span>
  <span class="sep">|</span>
  <span>{tests_total} tests</span>
  <span class="sep">|</span>
  <span class="pass-n">{tests_passed} pass</span>
  <span class="sep">|</span>
  <span class="fail-n">{tests_failed} fail</span>
  <span class="sep">|</span>
  <span class="skip-n">{tests_skipped} skip</span>
  <span class="sep">|</span>
  <span class="cov-n">{cov_pct_str} cov</span>
  <span class="sep">|</span>
  <span>{fmt_dur(time_ms)}</span>
  <span id="filter-indicator" style="display:none;margin-left:auto;color:var(--accent);font-size:.7rem">filter</span>
</div>

<!-- Main Layout -->
<div class="main-layout">

  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sidebar-filter">
      <input type="text" id="sidebar-filter" placeholder="Filter features..." autocomplete="off"/>
    </div>
    <div class="sidebar-tree">
      {tree_html}
    </div>
    {run_list_html}
  </div>

  <!-- Content -->
  <div class="content">
    <div class="tabs">
      <div class="tab active" data-tab="dashboard">Dashboard</div>
      <div class="tab" data-tab="tests">Tests</div>
      <div class="tab" data-tab="coverage">Coverage</div>
      <div class="tab" data-tab="failures">Failures {fail_badge}</div>
      <div class="tab" data-tab="trends">Trends</div>
    </div>

    <div id="pane-dashboard" class="tab-pane active">
      <div id="overview-panel" style="display:{'block' if mode == 'overview' else 'none'}">{overview_html}</div>
      <div id="detail-panel" style="display:{'block' if mode == 'detail' else 'none'}">{detail_dashboard_html}</div>
    </div>
    <div id="pane-tests" class="tab-pane">{tests_html}</div>
    <div id="pane-coverage" class="tab-pane">{cov_html}</div>
    <div id="pane-failures" class="tab-pane">{fail_items}</div>
    <div id="pane-trends" class="tab-pane">{trends_html}</div>
  </div>

</div>

<!-- Footer -->
<div class="footer-bar">
  merged_html_report.py v0.4.0 -- hanaden-bwrap-enhanced test harness tooling &middot; Generated {now}
  <br>
  (c) 2026 Hanaden - Frederick Bloom. All rights reserved.
</div>

<script>window.__DATA = {data_json};</script>
<script>{JS_V2}</script>
</body>
</html>'''


# ==============================================================================
# Main
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Generate a self-contained HTML report site from test run directories"
    )
    parser.add_argument("--dir-scan", required=True, help="Base directory to scan for *.test.run/ directories")
    parser.add_argument("--maxdepth", type=int, default=1, help="Max directory depth for discovery (default: 1)")
    parser.add_argument("--primary", default=None, help="Which run to display initially (default: overview)")
    parser.add_argument("-o", "--output", default="./", help="Base output directory; site written to [DIR]/site/ (default: ./)")
    args = parser.parse_args()

    if not os.path.isdir(args.dir_scan):
        print(f"[ERROR] --dir-scan directory not found: {args.dir_scan}", file=sys.stderr)
        sys.exit(2)

    # Discover run directories
    runs = discover_runs(args.dir_scan, args.maxdepth)
    if not runs:
        print(f"[WARN] No *.test.run/ directories found under {args.dir_scan}", file=sys.stderr)
        sys.exit(0)

    # Determine mode and primary run
    mode = "overview"  # default: aggregate overview
    primary_run = None
    if args.primary:
        mode = "detail"
        for r in runs:
            if r['dir_name'] == args.primary:
                primary_run = r
                break
        if not primary_run:
            print(f"[WARN] --primary '{args.primary}' not found; falling back to overview", file=sys.stderr)
            mode = "overview"

    # For detail view and tests/coverage/failures tabs, use the primary or latest run
    detail_run = primary_run
    if not detail_run:
        run_all_runs = [r for r in runs if 'run-all' in r['dir_name']]
        detail_run = run_all_runs[-1] if run_all_runs else runs[-1]

    # Parse the detail run's data files
    junit_data = None
    jacoco_data = None
    detail_path = detail_run['path']

    junit_xml = os.path.join(detail_path, 'junit.xml')
    junit_xml_alt = os.path.join(detail_path, '_bats-junit-raw', 'report.xml')
    jacoco_xml = os.path.join(detail_path, 'jacoco.xml')

    if os.path.isfile(junit_xml):
        junit_data = parse_junit_xml(junit_xml)
    elif os.path.isfile(junit_xml_alt):
        junit_data = parse_junit_xml(junit_xml_alt)
    if os.path.isfile(jacoco_xml):
        jacoco_data = parse_jacoco_xml(jacoco_xml)

    # Build trend data from all discovered runs
    trend_data = []
    for r in runs:
        meta = r.get('metadata', {})
        if meta.get('tests_total') is not None and meta.get('tests_total', 0) > 0:
            trend_data.append({
                'timestamp': meta.get('timestamp', meta.get('timestamp_start', '')),
                'tests_total': meta.get('tests_total', 0),
                'tests_passed': meta.get('tests_passed', 0),
                'tests_failed': meta.get('tests_failed', 0),
                'tests_skipped': meta.get('tests_skipped', 0),
                'total_duration_ms': meta.get('total_duration_ms', 0),
                'coverage_pct': meta.get('coverage_pct', '0.0'),
                'dir_name': r['dir_name'],
            })

    # Build runs metadata list for sidebar
    runs_meta = []
    for r in runs:
        meta = r.get('metadata', {})
        runs_meta.append({
            'dir_name': r['dir_name'],
            'timestamp': meta.get('timestamp', meta.get('timestamp_start', r['dir_name'][:15])),
            'tests_total': meta.get('tests_total', 0),
            'tests_passed': meta.get('tests_passed', 0),
            'tests_failed': meta.get('tests_failed', 0),
            'total_duration_ms': meta.get('total_duration_ms', 0),
        })

    # Generate HTML
    html = generate_html(junit_data, jacoco_data, trend_data, mode, detail_run['dir_name'], runs_meta)

    # Write to [output]/site/
    site_dir = os.path.join(args.output, 'site')
    os.makedirs(site_dir, exist_ok=True)
    output_path = os.path.join(site_dir, 'index.html')
    with open(output_path, 'w') as f:
        f.write(html)

    # Summary
    parts = [f"{len(runs)} run(s) discovered", f"mode={mode}"]
    if junit_data:
        parts.append(f"{junit_data['totals']['tests']} tests")
    if jacoco_data:
        parts.append(f"{len(jacoco_data['packages'])} packages")
    parts.append(f"{len(trend_data)} trend points")

    print(
        f"[INFO] HTML report written: {output_path} ({', '.join(parts)})",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()

