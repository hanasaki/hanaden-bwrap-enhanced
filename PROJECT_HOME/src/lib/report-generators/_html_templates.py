# (c) 2026-* Frederick Bloom -- _html_templates.py -- Hanaden AI
# ==============================================================================
# NAME:      _html_templates.py
# VERSION:   0.1.0
# PURPOSE:   Shared HTML/CSS design system for all report generators.
#            Implements Hanaden dark theme (dark mode, purple/indigo accents).
#            All CSS is inlined — no external stylesheets or CDN dependencies.
#
# USAGE:     from _html_templates import HtmlPage, StatusBadge, ProgressBar, ...
# ==============================================================================
"""Shared HTML design system for bwrap-enhanced test reports — Hanaden dark theme."""

from html import escape
from datetime import datetime, timezone

# ==============================================================================
# CSS DESIGN TOKENS — Hanaden Dark
# ==============================================================================
CSS_DESIGN_SYSTEM = """
/* ── Hanaden Dark Design System ─────────────────────────────────────── */
:root {
    /* Background */
    --bg-primary:        #0f0f1a;
    --bg-secondary:      #1a1a2e;
    --bg-tertiary:       #16213e;
    --bg-card:           #1a1a2e;
    --bg-hover:          #232342;

    /* Accent */
    --accent-primary:    #7c3aed;
    --accent-secondary:  #6366f1;
    --accent-glow:       rgba(124, 58, 237, 0.3);

    /* Text */
    --text-primary:      #e2e8f0;
    --text-secondary:    #94a3b8;
    --text-muted:        #64748b;
    --text-heading:      #f1f5f9;

    /* Status */
    --status-pass:       #22c55e;
    --status-pass-bg:    rgba(34, 197, 94, 0.15);
    --status-fail:       #ef4444;
    --status-fail-bg:    rgba(239, 68, 68, 0.15);
    --status-skip:       #f59e0b;
    --status-skip-bg:    rgba(245, 158, 11, 0.15);
    --status-error:      #f97316;
    --status-error-bg:   rgba(249, 115, 22, 0.15);

    /* Borders & Surfaces */
    --border-color:      #2d2d4a;
    --border-subtle:     #1e1e3a;
    --shadow-card:       0 4px 6px -1px rgba(0,0,0,0.3), 0 2px 4px -2px rgba(0,0,0,0.2);
    --shadow-glow:       0 0 20px var(--accent-glow);

    /* Coverage bars */
    --coverage-high:     #22c55e;
    --coverage-medium:   #f59e0b;
    --coverage-low:      #ef4444;

    /* Typography */
    --font-family:       'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-mono:         'JetBrains Mono', 'Fira Code', 'Cascadia Code', 'Consolas', monospace;
    --font-size-xs:      0.75rem;
    --font-size-sm:      0.875rem;
    --font-size-base:    1rem;
    --font-size-lg:      1.125rem;
    --font-size-xl:      1.25rem;
    --font-size-2xl:     1.5rem;
    --font-size-3xl:     1.875rem;

    /* Spacing */
    --space-1:           0.25rem;
    --space-2:           0.5rem;
    --space-3:           0.75rem;
    --space-4:           1rem;
    --space-6:           1.5rem;
    --space-8:           2rem;
    --space-12:          3rem;

    /* Radius */
    --radius-sm:         0.375rem;
    --radius-md:         0.5rem;
    --radius-lg:         0.75rem;
    --radius-xl:         1rem;
}

/* ── Global Reset ────────────────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { font-size: 16px; -webkit-font-smoothing: antialiased; }
body {
    font-family: var(--font-family);
    background: var(--bg-primary);
    color: var(--text-primary);
    line-height: 1.6;
    min-height: 100vh;
}

/* ── Layout ──────────────────────────────────────────────────────────── */
.container { max-width: 1200px; margin: 0 auto; padding: var(--space-6); }
.header {
    background: linear-gradient(135deg, var(--bg-secondary), var(--bg-tertiary));
    border-bottom: 1px solid var(--border-color);
    padding: var(--space-8) var(--space-6);
    margin-bottom: var(--space-8);
}
.header h1 {
    font-size: var(--font-size-3xl);
    color: var(--text-heading);
    font-weight: 700;
    margin-bottom: var(--space-2);
}
.header .subtitle {
    color: var(--text-secondary);
    font-size: var(--font-size-sm);
}
.breadcrumb {
    font-size: var(--font-size-sm);
    color: var(--text-muted);
    margin-bottom: var(--space-4);
}
.breadcrumb a { color: var(--accent-primary); text-decoration: none; }
.breadcrumb a:hover { text-decoration: underline; }
.breadcrumb .sep { margin: 0 var(--space-2); }

/* ── Cards ───────────────────────────────────────────────────────────── */
.card {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-lg);
    padding: var(--space-6);
    margin-bottom: var(--space-6);
    box-shadow: var(--shadow-card);
}
.card-title {
    font-size: var(--font-size-xl);
    color: var(--text-heading);
    font-weight: 600;
    margin-bottom: var(--space-4);
    padding-bottom: var(--space-3);
    border-bottom: 1px solid var(--border-subtle);
}

/* ── Stats Grid ──────────────────────────────────────────────────────── */
.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: var(--space-4);
    margin-bottom: var(--space-6);
}
.stat-card {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md);
    padding: var(--space-4);
    text-align: center;
    transition: transform 0.15s ease, box-shadow 0.15s ease;
}
.stat-card:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-glow);
}
.stat-value {
    font-size: var(--font-size-3xl);
    font-weight: 700;
    color: var(--text-heading);
    line-height: 1.2;
}
.stat-label {
    font-size: var(--font-size-xs);
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-top: var(--space-1);
}
.stat-card.pass .stat-value { color: var(--status-pass); }
.stat-card.fail .stat-value { color: var(--status-fail); }
.stat-card.skip .stat-value { color: var(--status-skip); }
.stat-card.error .stat-value { color: var(--status-error); }
.stat-card.total .stat-value { color: var(--accent-primary); }
.stat-card.time .stat-value { color: var(--accent-secondary); }

/* ── Tables ──────────────────────────────────────────────────────────── */
.table-wrap { overflow-x: auto; }
table {
    width: 100%;
    border-collapse: collapse;
    font-size: var(--font-size-sm);
}
thead th {
    background: var(--bg-tertiary);
    color: var(--text-secondary);
    font-weight: 600;
    text-transform: uppercase;
    font-size: var(--font-size-xs);
    letter-spacing: 0.05em;
    padding: var(--space-3) var(--space-4);
    text-align: left;
    border-bottom: 2px solid var(--border-color);
    cursor: pointer;
    user-select: none;
}
thead th:hover { color: var(--accent-primary); }
tbody tr {
    border-bottom: 1px solid var(--border-subtle);
    transition: background 0.1s ease;
}
tbody tr:hover { background: var(--bg-hover); }
td {
    padding: var(--space-3) var(--space-4);
    vertical-align: middle;
}
td a { color: var(--accent-primary); text-decoration: none; }
td a:hover { text-decoration: underline; }
.align-right { text-align: right; }
.mono { font-family: var(--font-mono); font-size: var(--font-size-xs); }

/* ── Status Badges ───────────────────────────────────────────────────── */
.badge {
    display: inline-block;
    padding: var(--space-1) var(--space-3);
    border-radius: var(--radius-sm);
    font-size: var(--font-size-xs);
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}
.badge-pass { background: var(--status-pass-bg); color: var(--status-pass); }
.badge-fail { background: var(--status-fail-bg); color: var(--status-fail); }
.badge-skip { background: var(--status-skip-bg); color: var(--status-skip); }
.badge-error { background: var(--status-error-bg); color: var(--status-error); }

/* ── Progress / Coverage Bars ────────────────────────────────────────── */
.progress-bar {
    height: 8px;
    background: var(--bg-primary);
    border-radius: 4px;
    overflow: hidden;
    min-width: 100px;
}
.progress-fill {
    height: 100%;
    border-radius: 4px;
    transition: width 0.3s ease;
}
.progress-fill.high { background: var(--coverage-high); }
.progress-fill.medium { background: var(--coverage-medium); }
.progress-fill.low { background: var(--coverage-low); }

.coverage-cell {
    display: flex;
    align-items: center;
    gap: var(--space-2);
}
.coverage-pct {
    font-family: var(--font-mono);
    font-size: var(--font-size-xs);
    min-width: 3.5em;
    text-align: right;
}

/* ── Timing Bars ─────────────────────────────────────────────────────── */
.timing-bar {
    height: 6px;
    background: var(--bg-primary);
    border-radius: 3px;
    overflow: hidden;
    min-width: 60px;
}
.timing-fill {
    height: 100%;
    background: var(--accent-primary);
    border-radius: 3px;
}

/* ── Details / Expandable ────────────────────────────────────────────── */
details {
    margin-bottom: var(--space-3);
}
summary {
    cursor: pointer;
    padding: var(--space-3) var(--space-4);
    background: var(--bg-tertiary);
    border-radius: var(--radius-sm);
    color: var(--text-secondary);
    font-size: var(--font-size-sm);
    font-weight: 500;
}
summary:hover { color: var(--accent-primary); }
.details-content {
    padding: var(--space-4);
    background: var(--bg-primary);
    border: 1px solid var(--border-subtle);
    border-radius: 0 0 var(--radius-sm) var(--radius-sm);
    margin-top: -1px;
}
.error-output {
    font-family: var(--font-mono);
    font-size: var(--font-size-xs);
    white-space: pre-wrap;
    word-break: break-all;
    color: var(--status-fail);
    line-height: 1.5;
}

/* ── Footer ──────────────────────────────────────────────────────────── */
.footer {
    margin-top: var(--space-12);
    padding: var(--space-6) 0;
    border-top: 1px solid var(--border-subtle);
    color: var(--text-muted);
    font-size: var(--font-size-xs);
    text-align: center;
}

/* ── Tabs (for unified report) ───────────────────────────────────────── */
.tabs {
    display: flex;
    gap: 0;
    border-bottom: 2px solid var(--border-color);
    margin-bottom: var(--space-6);
}
.tab {
    padding: var(--space-3) var(--space-6);
    cursor: pointer;
    color: var(--text-muted);
    font-weight: 500;
    font-size: var(--font-size-sm);
    border-bottom: 2px solid transparent;
    margin-bottom: -2px;
    transition: color 0.15s ease, border-color 0.15s ease;
    text-decoration: none;
}
.tab:hover { color: var(--text-primary); }
.tab.active {
    color: var(--accent-primary);
    border-bottom-color: var(--accent-primary);
}

/* ── Health Badge ────────────────────────────────────────────────────── */
.health-badge {
    display: inline-flex;
    align-items: center;
    gap: var(--space-2);
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-xl);
    font-weight: 600;
    font-size: var(--font-size-sm);
}
.health-badge.healthy {
    background: var(--status-pass-bg);
    color: var(--status-pass);
    border: 1px solid var(--status-pass);
}
.health-badge.warning {
    background: var(--status-skip-bg);
    color: var(--status-skip);
    border: 1px solid var(--status-skip);
}
.health-badge.critical {
    background: var(--status-fail-bg);
    color: var(--status-fail);
    border: 1px solid var(--status-fail);
}
.health-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: currentColor;
}

/* ── Responsive ──────────────────────────────────────────────────────── */
@media (max-width: 768px) {
    .container { padding: var(--space-4); }
    .stats-grid { grid-template-columns: repeat(2, 1fr); }
    .header { padding: var(--space-6) var(--space-4); }
    .header h1 { font-size: var(--font-size-2xl); }
}
"""

# ==============================================================================
# JAVASCRIPT — Table Sorting (inline, no dependencies)
# ==============================================================================
JS_TABLE_SORT = """
document.querySelectorAll('table[data-sortable] thead th').forEach(function(th, colIdx) {
    th.addEventListener('click', function() {
        var table = th.closest('table');
        var tbody = table.querySelector('tbody');
        var rows = Array.from(tbody.querySelectorAll('tr'));
        var asc = th.dataset.sortDir !== 'asc';
        th.dataset.sortDir = asc ? 'asc' : 'desc';
        // Reset other headers
        table.querySelectorAll('thead th').forEach(function(h) {
            if (h !== th) delete h.dataset.sortDir;
        });
        rows.sort(function(a, b) {
            var aVal = a.children[colIdx].dataset.sortValue || a.children[colIdx].textContent.trim();
            var bVal = b.children[colIdx].dataset.sortValue || b.children[colIdx].textContent.trim();
            var aNum = parseFloat(aVal), bNum = parseFloat(bVal);
            if (!isNaN(aNum) && !isNaN(bNum)) return asc ? aNum - bNum : bNum - aNum;
            return asc ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
        });
        rows.forEach(function(r) { tbody.appendChild(r); });
    });
});
"""

# ==============================================================================
# HTML BUILDER HELPERS
# ==============================================================================


def html_page(title, body_content, breadcrumbs=None):
    """Build a complete self-contained HTML page.

    Args:
        title: Page title (for <title> and <h1>)
        body_content: HTML string for the body
        breadcrumbs: Optional list of (label, href) tuples; last one is current page (no href)

    Returns:
        Complete HTML string.
    """
    bc_html = ""
    if breadcrumbs:
        parts = []
        for i, (label, href) in enumerate(breadcrumbs):
            if href:
                parts.append(f'<a href="{escape(href)}">{escape(label)}</a>')
            else:
                parts.append(escape(label))
        sep = ' <span class="sep">›</span> '
        bc_html = f'<div class="breadcrumb">{sep.join(parts)}</div>'

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{escape(title)} — bwrap-enhanced</title>
<meta name="description" content="{escape(title)} for bwrap-enhanced test suite">
<meta name="generator" content="bwrap-enhanced-test-harness-runner.sh v0.1.0">
<style>{CSS_DESIGN_SYSTEM}</style>
</head>
<body>
<div class="header">
  <div class="container">
    {bc_html}
    <h1>{escape(title)}</h1>
    <div class="subtitle">Generated {now} · bwrap-enhanced test harness</div>
  </div>
</div>
<div class="container">
{body_content}
</div>
<div class="footer">
  <div class="container">
    (c) 2026-* Frederick Bloom — Hanaden AI · bwrap-enhanced test harness v0.1.0
  </div>
</div>
<script>{JS_TABLE_SORT}</script>
</body>
</html>"""


def status_badge(status):
    """Return HTML for a status badge."""
    status_upper = status.upper()
    css_class = {
        "PASS": "badge-pass",
        "FAIL": "badge-fail",
        "SKIP": "badge-skip",
        "ERROR": "badge-error",
    }.get(status_upper, "badge-pass")
    return f'<span class="badge {css_class}">{escape(status_upper)}</span>'


def progress_bar(value, maximum, show_pct=True):
    """Return HTML for a coverage/progress bar.

    Args:
        value: Current value (numerator)
        maximum: Maximum value (denominator)
        show_pct: Whether to show percentage text
    """
    if maximum == 0:
        pct = 0.0
    else:
        pct = (value / maximum) * 100

    level = "high" if pct >= 80 else "medium" if pct >= 50 else "low"
    pct_text = f'<span class="coverage-pct">{pct:.1f}%</span>' if show_pct else ""

    return f"""<div class="coverage-cell">
{pct_text}
<div class="progress-bar"><div class="progress-fill {level}" style="width:{pct:.1f}%"></div></div>
</div>"""


def timing_bar(duration_ms, max_duration_ms):
    """Return HTML for a timing bar (relative to max)."""
    if max_duration_ms == 0:
        pct = 0
    else:
        pct = min((duration_ms / max_duration_ms) * 100, 100)
    return f'<div class="timing-bar"><div class="timing-fill" style="width:{pct:.1f}%"></div></div>'


def stat_card(value, label, css_class=""):
    """Return HTML for a single statistic card."""
    return f"""<div class="stat-card {css_class}">
<div class="stat-value">{escape(str(value))}</div>
<div class="stat-label">{escape(label)}</div>
</div>"""


def format_duration(ms):
    """Format milliseconds as human-readable string."""
    if ms < 1000:
        return f"{ms}ms"
    elif ms < 60000:
        return f"{ms / 1000:.2f}s"
    else:
        minutes = ms // 60000
        seconds = (ms % 60000) / 1000
        return f"{minutes}m {seconds:.1f}s"


def health_badge(tests_passed, tests_total, tests_failed):
    """Return HTML for an overall health badge."""
    if tests_total == 0:
        level = "warning"
        label = "No Tests"
    elif tests_failed == 0:
        level = "healthy"
        label = "All Passing"
    elif tests_failed / tests_total < 0.1:
        level = "warning"
        label = f"{tests_failed} Failing"
    else:
        level = "critical"
        label = f"{tests_failed} Failing"

    return f'<span class="health-badge {level}"><span class="health-dot"></span>{escape(label)}</span>'


def svg_timing_histogram(durations_ms, width=600, height=120, bar_count=20):
    """Generate an inline SVG timing distribution histogram.

    Args:
        durations_ms: List of test durations in ms
        width: SVG width
        height: SVG height
        bar_count: Number of histogram bins

    Returns:
        SVG string.
    """
    if not durations_ms:
        return '<p class="text-muted">No timing data available.</p>'

    min_d = min(durations_ms)
    max_d = max(durations_ms)

    if max_d == min_d:
        # All same duration — single bar
        bins = [len(durations_ms)]
        bin_width = width - 40
    else:
        bin_size = (max_d - min_d) / bar_count
        bins = [0] * bar_count
        for d in durations_ms:
            idx = min(int((d - min_d) / bin_size), bar_count - 1)
            bins[idx] += 1
        bin_width = (width - 40) / bar_count

    max_count = max(bins) if bins else 1
    bar_area_height = height - 30

    bars = []
    for i, count in enumerate(bins):
        bar_h = (count / max_count) * bar_area_height if max_count > 0 else 0
        x = 30 + i * bin_width
        y = bar_area_height - bar_h + 5
        bars.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{bin_width - 1:.1f}" '
            f'height="{bar_h:.1f}" fill="var(--accent-primary)" rx="2"/>'
        )

    # X-axis labels
    labels = f"""
    <text x="30" y="{height - 2}" font-size="10" fill="var(--text-muted)" font-family="var(--font-mono)">{format_duration(min_d)}</text>
    <text x="{width - 10}" y="{height - 2}" font-size="10" fill="var(--text-muted)" font-family="var(--font-mono)" text-anchor="end">{format_duration(max_d)}</text>
    """

    return f"""<svg width="{width}" height="{height}" viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg">
{''.join(bars)}
{labels}
</svg>"""
