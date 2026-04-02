# Report Generation Reference Guide

## Purpose

This guide is the authoritative knowledge base for the `openldr-report` skill. It contains the complete HTML template, data-to-visualization mapping rules, Chart.js configuration patterns, KPI card extraction rules, color palette, number formatting, file naming, and the step-by-step generation process.

When generating a report, read this guide fully before writing any HTML. Every structural decision — from chart type selection to CSS class names — is defined here.

---

## 1. Full HTML Template

The template below is the base for every generated report. Replace all `{PLACEHOLDER}` tokens with actual values. Do not alter the structure, CSS classes, or CDN URLs.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{REPORT_TITLE}</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    /* ── Reset & Base ── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #0f172a;
      color: #e2e8f0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      font-size: 14px;
      line-height: 1.5;
      min-height: 100vh;
    }

    /* ── Layout ── */
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 24px 20px;
    }

    /* ── Header ── */
    .header {
      display: flex;
      flex-direction: column;
      gap: 6px;
      margin-bottom: 32px;
      padding-bottom: 20px;
      border-bottom: 1px solid #334155;
    }
    .header-label {
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: #38bdf8;
    }
    .header-title {
      font-size: 24px;
      font-weight: 700;
      color: #f8fafc;
    }
    .header-meta {
      font-size: 13px;
      color: #64748b;
    }

    /* ── KPI Cards ── */
    .kpi-row {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }
    .kpi-card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 10px;
      padding: 20px;
    }
    .kpi-value {
      font-size: 32px;
      font-weight: 700;
      line-height: 1.1;
      font-variant-numeric: tabular-nums;
      margin-bottom: 6px;
    }
    .kpi-label {
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      color: #64748b;
    }
    .kpi-subtext {
      font-size: 12px;
      color: #475569;
      margin-top: 4px;
    }

    /* KPI color variants */
    .kpi-blue  .kpi-value { color: #38bdf8; }
    .kpi-green .kpi-value { color: #4ade80; }
    .kpi-amber .kpi-value { color: #fbbf24; }
    .kpi-red   .kpi-value { color: #f87171; }
    .kpi-purple .kpi-value { color: #a78bfa; }

    /* ── Chart Area ── */
    .chart-section {
      margin-bottom: 32px;
    }
    .section-title {
      font-size: 14px;
      font-weight: 600;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 12px;
    }
    .chart-container {
      background: #1e293b;
      border-radius: 10px;
      padding: 24px;
      position: relative;
    }
    .chart-container canvas {
      display: block;
    }

    /* ── Data Table ── */
    .table-section {
      margin-bottom: 32px;
    }
    .table-wrapper {
      background: #1e293b;
      border-radius: 10px;
      overflow: hidden;
      border: 1px solid #334155;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }
    thead th {
      background: #334155;
      color: #cbd5e1;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      padding: 12px 16px;
      text-align: left;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    thead th:hover {
      background: #475569;
    }
    thead th.sort-asc::after  { content: ' ▲'; font-size: 10px; }
    thead th.sort-desc::after { content: ' ▼'; font-size: 10px; }
    tbody tr:nth-child(odd)  { background: #0f172a; }
    tbody tr:nth-child(even) { background: #1e293b; }
    tbody tr:hover { background: #334155; }
    td {
      padding: 10px 16px;
      color: #cbd5e1;
      border-top: 1px solid #1e293b;
    }
    td.number {
      text-align: right;
      font-variant-numeric: tabular-nums;
      font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', Consolas, monospace;
    }

    /* ── Footer ── */
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #334155;
      text-align: center;
      color: #475569;
      font-size: 12px;
    }
    .footer a {
      color: #38bdf8;
      text-decoration: none;
    }
    .footer a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="container">

    <!-- ── Header ── -->
    <div class="header">
      <div class="header-label">{HEADER_LABEL}</div>
      <div class="header-title">{REPORT_TITLE}</div>
      <div class="header-meta">{HEADER_META}</div>
    </div>

    <!-- ── KPI Cards ── -->
    <!-- Include this section only when KPI fields are present (see Section 4) -->
    <div class="kpi-row">
      {KPI_CARDS}
    </div>

    <!-- ── Chart Area ── -->
    <!-- Include this section only when a chart applies (see Section 2) -->
    <div class="chart-section">
      <div class="section-title">{CHART_SECTION_TITLE}</div>
      <div class="chart-container">
        <canvas id="mainChart" height="80"></canvas>
      </div>
    </div>

    <!-- ── Data Table ── -->
    <div class="table-section">
      <div class="section-title">{TABLE_SECTION_TITLE}</div>
      <div class="table-wrapper">
        <table id="dataTable">
          <thead>
            <tr>
              {TABLE_HEADERS}
            </tr>
          </thead>
          <tbody>
            {TABLE_ROWS}
          </tbody>
        </table>
      </div>
    </div>

    <!-- ── Footer ── -->
    <div class="footer">
      {FOOTER_TEXT}
    </div>

  </div><!-- /.container -->

  <script>
    /* ── Sortable Table ── */
    (function () {
      const table = document.getElementById('dataTable');
      if (!table) return;
      const headers = table.querySelectorAll('thead th');
      let sortCol = -1, sortDir = 1;

      headers.forEach(function (th, colIndex) {
        th.addEventListener('click', function () {
          if (sortCol === colIndex) {
            sortDir *= -1;
          } else {
            sortCol = colIndex;
            sortDir = 1;
          }
          headers.forEach(function (h) {
            h.classList.remove('sort-asc', 'sort-desc');
          });
          th.classList.add(sortDir === 1 ? 'sort-asc' : 'sort-desc');

          const tbody = table.querySelector('tbody');
          const rows  = Array.from(tbody.querySelectorAll('tr'));
          rows.sort(function (a, b) {
            const aText = a.cells[colIndex] ? a.cells[colIndex].innerText.trim() : '';
            const bText = b.cells[colIndex] ? b.cells[colIndex].innerText.trim() : '';
            const aNum  = parseFloat(aText.replace(/,/g, ''));
            const bNum  = parseFloat(bText.replace(/,/g, ''));
            if (!isNaN(aNum) && !isNaN(bNum)) {
              return (aNum - bNum) * sortDir;
            }
            return aText.localeCompare(bText) * sortDir;
          });
          rows.forEach(function (row) { tbody.appendChild(row); });
        });
      });
    })();

    /* ── Chart Initialization ── */
    {CHART_SCRIPT}
  </script>
</body>
</html>
```

### Placeholder Reference

| Placeholder | Description | Example |
|---|---|---|
| `{REPORT_TITLE}` | Human-readable report title | `HIV Viral Load — Monthly Summary` |
| `{HEADER_LABEL}` | Short category label above title | `OpenLDR · HIV Viral Load` |
| `{HEADER_META}` | Date range or query context | `Period: Jan 2024 – Dec 2024 · Generated 2024-01-15` |
| `{KPI_CARDS}` | Rendered KPI card HTML (see Section 4) | One or more `.kpi-card` divs |
| `{CHART_SECTION_TITLE}` | Section heading above chart | `Monthly Trend` |
| `{TABLE_SECTION_TITLE}` | Section heading above table | `Result Breakdown by Facility` |
| `{TABLE_HEADERS}` | `<th>` elements for each column | `<th>Facility</th><th>Count</th>` |
| `{TABLE_ROWS}` | `<tr><td>` rows for data | One `<tr>` per data record |
| `{FOOTER_TEXT}` | Footer content | `Generated by OpenLDR · openldr-report` |
| `{CHART_SCRIPT}` | Chart.js initialization block (see Section 3) | Full `new Chart(...)` call |

---

## 2. Data-to-Visualization Mapping Rules

Evaluate the query result columns in order. Apply the **first rule that matches**. Rules are mutually exclusive — stop at the first match.

| # | Data Pattern | Chart Type | Notes |
|---|---|---|---|
| 1 | Any column is a date, month, year, or contains a date-like pattern (e.g., `2024-01`, `Jan 2024`) **and** at least one numeric column is present | **Line chart** | Use date column as X-axis labels; each numeric column becomes a dataset |
| 2 | One categorical (text) column + one numeric column, and the categorical column has **≤ 15 distinct values** | **Vertical bar chart** | Category on X-axis, numeric on Y-axis |
| 3 | One categorical column + one numeric column, and the categorical column has **> 15 distinct values** | **Horizontal bar chart** | Category on Y-axis; easier to read with many labels |
| 4 | One categorical column + **two or more** numeric columns | **Grouped or stacked bar chart** | Use grouped by default; use stacked only when values are additive parts of a whole |
| 5 | **2 to 5 categories only**, their numeric values sum to approximately 100 (percent) or represent complete partition of a total | **Doughnut chart** | Ideal for suppression rates, positivity breakdowns, etc. |
| 6 | **1 or 2 rows** of aggregate/summary values (e.g., totals, averages, rates) | **KPI cards only** — no chart | Render each aggregate as a KPI card; omit the chart section entirely |
| 7 | All other tabular data (many rows, mixed types, no clear chart mapping) | **Table only** — no chart | Render the full data table; omit the chart section entirely |

### Decision Notes

- A column is considered "date-like" if its name contains `date`, `month`, `year`, `period`, `quarter`, or if values match patterns like `YYYY-MM`, `YYYY-QN`, `Mon YYYY`.
- A column is considered "categorical" if it contains string/text values and has fewer than 50 distinct values.
- A column is considered "numeric" if it contains integers or decimals (counts, rates, percentages, durations).
- When rule 4 applies and there are more than 5 numeric series, prefer stacked bar to avoid overcrowding.
- When rule 5 applies, verify the sum is within ±5% of 100 before using a doughnut. If not, fall back to rule 2 or 3.

---

## 3. Chart.js Configuration Patterns

All charts use the dark theme. Common properties shared across all chart types:

```javascript
Chart.defaults.color = '#64748b';
Chart.defaults.borderColor = '#334155';
```

Set these defaults **before** calling `new Chart(...)`.

### 3.1 Line Chart

Use for time-series data (Rule 1).

```javascript
Chart.defaults.color = '#64748b';
Chart.defaults.borderColor = '#334155';

new Chart(document.getElementById('mainChart'), {
  type: 'line',
  data: {
    labels: {LABELS_ARRAY},        // e.g., ['Jan 2024', 'Feb 2024', ...]
    datasets: [
      {
        label: '{SERIES_LABEL}',
        data: {DATA_ARRAY},         // e.g., [120, 145, 98, ...]
        borderColor: '#38bdf8',
        backgroundColor: 'rgba(56, 189, 248, 0.1)',
        borderWidth: 2,
        pointBackgroundColor: '#38bdf8',
        pointRadius: 4,
        pointHoverRadius: 6,
        tension: 0.3,
        fill: true
      }
      // Add more datasets here for multiple series
    ]
  },
  options: {
    responsive: true,
    plugins: {
      legend: {
        labels: { color: '#f1f5f9', font: { size: 13 } }
      },
      tooltip: {
        backgroundColor: '#1e293b',
        titleColor: '#f1f5f9',
        bodyColor: '#cbd5e1',
        borderColor: '#334155',
        borderWidth: 1
      }
    },
    scales: {
      x: {
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' }
      },
      y: {
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' },
        beginAtZero: true
      }
    }
  }
});
```

### 3.2 Vertical Bar Chart

Use for categorical + single numeric, ≤ 15 categories (Rule 2).

```javascript
Chart.defaults.color = '#64748b';
Chart.defaults.borderColor = '#334155';

new Chart(document.getElementById('mainChart'), {
  type: 'bar',
  data: {
    labels: {LABELS_ARRAY},
    datasets: [
      {
        label: '{SERIES_LABEL}',
        data: {DATA_ARRAY},
        backgroundColor: [
          '#38bdf8', '#4ade80', '#fbbf24', '#f87171', '#a78bfa',
          '#34d399', '#fb923c', '#e879f9', '#22d3ee', '#86efac',
          '#fcd34d', '#fca5a5', '#c4b5fd', '#6ee7b7', '#fdba74'
        ],
        borderColor: '#0f172a',
        borderWidth: 1,
        borderRadius: 4
      }
    ]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1e293b',
        titleColor: '#f1f5f9',
        bodyColor: '#cbd5e1',
        borderColor: '#334155',
        borderWidth: 1
      }
    },
    scales: {
      x: {
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' }
      },
      y: {
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' },
        beginAtZero: true
      }
    }
  }
});
```

### 3.3 Horizontal Bar Chart

Use for categorical + single numeric, > 15 categories (Rule 3).

```javascript
Chart.defaults.color = '#64748b';
Chart.defaults.borderColor = '#334155';

new Chart(document.getElementById('mainChart'), {
  type: 'bar',
  data: {
    labels: {LABELS_ARRAY},
    datasets: [
      {
        label: '{SERIES_LABEL}',
        data: {DATA_ARRAY},
        backgroundColor: 'rgba(56, 189, 248, 0.7)',
        borderColor: '#38bdf8',
        borderWidth: 1,
        borderRadius: 3
      }
    ]
  },
  options: {
    indexAxis: 'y',               // <-- makes bar chart horizontal
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1e293b',
        titleColor: '#f1f5f9',
        bodyColor: '#cbd5e1',
        borderColor: '#334155',
        borderWidth: 1
      }
    },
    scales: {
      x: {
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' },
        beginAtZero: true
      },
      y: {
        grid:  { color: '#1e293b' },
        ticks: { color: '#64748b', font: { size: 11 } }
      }
    }
  }
});
```

### 3.4 Grouped / Stacked Bar Chart

Use for categorical + multiple numeric columns (Rule 4). Set `stacked: true` on both axes to switch to stacked mode.

```javascript
Chart.defaults.color = '#64748b';
Chart.defaults.borderColor = '#334155';

new Chart(document.getElementById('mainChart'), {
  type: 'bar',
  data: {
    labels: {LABELS_ARRAY},
    datasets: [
      {
        label: '{SERIES_LABEL_1}',
        data: {DATA_ARRAY_1},
        backgroundColor: 'rgba(56, 189, 248, 0.75)',
        borderColor: '#38bdf8',
        borderWidth: 1,
        borderRadius: 3
      },
      {
        label: '{SERIES_LABEL_2}',
        data: {DATA_ARRAY_2},
        backgroundColor: 'rgba(74, 222, 128, 0.75)',
        borderColor: '#4ade80',
        borderWidth: 1,
        borderRadius: 3
      }
      // Add more datasets for additional numeric columns
    ]
  },
  options: {
    responsive: true,
    plugins: {
      legend: {
        labels: { color: '#f1f5f9', font: { size: 12 } }
      },
      tooltip: {
        backgroundColor: '#1e293b',
        titleColor: '#f1f5f9',
        bodyColor: '#cbd5e1',
        borderColor: '#334155',
        borderWidth: 1
      }
    },
    scales: {
      x: {
        // stacked: true,           // Uncomment to switch to stacked mode
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' }
      },
      y: {
        // stacked: true,           // Uncomment to switch to stacked mode
        grid:  { color: '#334155' },
        ticks: { color: '#64748b' },
        beginAtZero: true
      }
    }
  }
});
```

### 3.5 Doughnut Chart

Use for 2–5 categories that partition a whole (Rule 5).

```javascript
Chart.defaults.color = '#64748b';
Chart.defaults.borderColor = '#334155';

new Chart(document.getElementById('mainChart'), {
  type: 'doughnut',
  data: {
    labels: {LABELS_ARRAY},
    datasets: [
      {
        data: {DATA_ARRAY},
        backgroundColor: [
          '#38bdf8', '#4ade80', '#fbbf24', '#f87171', '#a78bfa'
        ],
        borderColor: '#0f172a',
        borderWidth: 2,
        hoverOffset: 8
      }
    ]
  },
  options: {
    responsive: true,
    cutout: '65%',
    plugins: {
      legend: {
        position: 'right',
        labels: {
          color: '#f1f5f9',
          font: { size: 13 },
          padding: 16,
          usePointStyle: true
        }
      },
      tooltip: {
        backgroundColor: '#1e293b',
        titleColor: '#f1f5f9',
        bodyColor: '#cbd5e1',
        borderColor: '#334155',
        borderWidth: 1,
        callbacks: {
          label: function (ctx) {
            const total = ctx.dataset.data.reduce(function (a, b) { return a + b; }, 0);
            const pct   = total > 0 ? ((ctx.parsed / total) * 100).toFixed(1) : '0.0';
            return ' ' + ctx.label + ': ' + formatNumber(ctx.parsed) + ' (' + pct + '%)';
          }
        }
      }
    }
  }
});
```

---

## 4. KPI Card Extraction Rules

When column names match these patterns, render each matching value as a KPI card. Pattern matching is case-insensitive. Apply the **first matching rule** for each column.

| Priority | Column Name Pattern | CSS Class | Typical Meaning |
|---|---|---|---|
| 1 | starts with `total_` or ends with `_count` | `kpi-blue` | Counts and totals |
| 2 | ends with `_rate`, `_suppression`, or `_percentage` | `kpi-green` | Rates and percentages |
| 3 | ends with `_tat`, `_turnaround`, or `_days` | `kpi-amber` | Turnaround time metrics |
| 4 | ends with `_rejected` or `_error` | `kpi-red` | Rejection/error indicators |
| 5 | any other aggregate numeric column | `kpi-purple` | Miscellaneous metrics |

### KPI Card HTML Snippet

```html
<div class="kpi-card kpi-blue">
  <div class="kpi-value">{KPI_VALUE}</div>
  <div class="kpi-label">{KPI_LABEL}</div>
  <div class="kpi-subtext">{KPI_SUBTEXT}</div>
</div>
```

- `{KPI_VALUE}` — formatted number (see Section 6), e.g., `12,450` or `87.3%`
- `{KPI_LABEL}` — human-readable column name (snake_case → Title Case, underscores → spaces)
- `{KPI_SUBTEXT}` — optional context, e.g., `of 14,200 total` or `median 2.1 days`. Omit the element if no subtext is needed.

### KPI Card Examples

| Column Name | Formatted Value | CSS Class | Label |
|---|---|---|---|
| `total_tests` | `14,200` | `kpi-blue` | Total Tests |
| `suppression_rate` | `87.3%` | `kpi-green` | Suppression Rate |
| `median_tat_days` | `4.2` | `kpi-amber` | Median Tat Days |
| `total_rejected` | `312` | `kpi-red` | Total Rejected |
| `facilities_reporting` | `48` | `kpi-purple` | Facilities Reporting |

---

## 5. Color Palette

### Theme Colors

| Usage | Hex | Description |
|---|---|---|
| Page background | `#0f172a` | Slate-950 |
| Card / panel background | `#1e293b` | Slate-800 |
| Border / grid lines | `#334155` | Slate-700 |
| Muted text / tick labels | `#64748b` | Slate-500 |
| Secondary text | `#94a3b8` | Slate-400 |
| Body text | `#cbd5e1` | Slate-300 |
| Heading text | `#f1f5f9` | Slate-100 |
| Primary accent (blue) | `#38bdf8` | Sky-400 |
| Success / rate (green) | `#4ade80` | Green-400 |
| Warning / TAT (amber) | `#fbbf24` | Amber-400 |
| Danger / error (red) | `#f87171` | Red-400 |
| Purple / misc | `#a78bfa` | Violet-400 |

### Data Series Colors (15 slots)

Use these in order for multi-series charts. Cycle back to the beginning if more than 15 series are needed.

```javascript
const SERIES_COLORS = [
  '#38bdf8', // 1  sky blue
  '#4ade80', // 2  green
  '#fbbf24', // 3  amber
  '#f87171', // 4  red
  '#a78bfa', // 5  violet
  '#34d399', // 6  emerald
  '#fb923c', // 7  orange
  '#e879f9', // 8  fuchsia
  '#22d3ee', // 9  cyan
  '#86efac', // 10 light green
  '#fcd34d', // 11 yellow
  '#fca5a5', // 12 light red
  '#c4b5fd', // 13 light violet
  '#6ee7b7', // 14 teal
  '#fdba74'  // 15 peach
];
```

---

## 6. Number Formatting

### Formatting Rules

| Value Type | Format | Example |
|---|---|---|
| Integer ≥ 1,000 | Thousands separator | `12,450` |
| Integer < 1,000 | Plain integer | `847` |
| Decimal (rate/percentage) | 1 decimal place + `%` suffix if column is a rate/percentage | `87.3%` or `4.2` |
| Days / turnaround | 1 decimal place | `3.7` |
| Very large numbers (≥ 1,000,000) | Abbreviate to 1 decimal + `M` | `1.2M` |
| Very large numbers (≥ 1,000) | Abbreviate to 1 decimal + `K` when in chart labels only | `14.2K` |
| Zero or null | Display `—` (em dash) | `—` |

### JavaScript Helper Function

Include this function in the `<script>` block of every generated report, before the chart initialization code.

```javascript
function formatNumber(value, opts) {
  opts = opts || {};
  if (value === null || value === undefined || value === '') return '—';
  var n = parseFloat(value);
  if (isNaN(n)) return String(value);
  if (n === 0) return opts.showZero ? '0' : '—';
  if (opts.abbreviate) {
    if (Math.abs(n) >= 1e6) return (n / 1e6).toFixed(1) + 'M';
    if (Math.abs(n) >= 1e3) return (n / 1e3).toFixed(1) + 'K';
  }
  var decimals = opts.decimals !== undefined ? opts.decimals : (Number.isInteger(n) ? 0 : 1);
  var formatted = n.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals
  });
  return opts.pct ? formatted + '%' : formatted;
}
```

**Usage examples:**

```javascript
formatNumber(12450)                    // "12,450"
formatNumber(0.873, { pct: true })     // "0.9%"  (avoid — pass pre-multiplied value)
formatNumber(87.3,  { pct: true })     // "87.3%"
formatNumber(3.7,   { decimals: 1 })   // "3.7"
formatNumber(0)                        // "—"
formatNumber(0, { showZero: true })    // "0"
formatNumber(1450000, { abbreviate: true }) // "1.5M"
```

Apply `formatNumber` when building `{TABLE_ROWS}` HTML: wrap every numeric `<td>` with class `number` and pass the value through `formatNumber`.

---

## 7. File Naming

Default output filename pattern:

```
openldr-report-YYYYMMDD-HHMMSS.html
```

Where `YYYYMMDD` is the current date and `HHMMSS` is the current time (24-hour), both in UTC unless the user specifies a timezone.

**Examples:**

- `openldr-report-20240115-143022.html`
- `openldr-report-20241231-090000.html`

If the user specifies a descriptive name (e.g., "VL suppression report"), use it as a prefix:

```
vl-suppression-report-20240115-143022.html
```

Rules:
- All lowercase
- Words separated by hyphens
- No spaces or special characters
- Always ends with `.html`

---

## 8. Step-by-Step Generation Process

Follow these steps in order every time a report is requested.

### Step 1 — Understand the Data

- Examine the query result: column names, data types, number of rows, distinct values in categorical columns.
- Identify which columns are categorical, which are numeric, and which are date-like.
- Note any aggregate/summary rows (single-row results, totals, rates).

### Step 2 — Select Visualization

- Apply the Data-to-Visualization Mapping Rules (Section 2) in order.
- Record which rule matched and which chart type will be used (or "no chart").

### Step 3 — Extract KPI Cards

- Scan all column names against the KPI extraction patterns (Section 4).
- For each matching column, prepare the card: formatted value, label, color class.
- If rule 6 matched in Step 2, all aggregate values become KPI cards (no chart).

### Step 4 — Build the Chart Configuration

- Using the matched chart type, select the Chart.js config pattern from Section 3.
- Populate `{LABELS_ARRAY}` and `{DATA_ARRAY}` with actual data values.
- For multi-series charts, assign colors from the palette in Section 5 (one per series).
- Include the `formatNumber` helper function (Section 6) before the chart init code.

### Step 5 — Build the Table

- Render all data rows as an HTML table.
- For numeric columns, add class `number` to `<td>` elements and format values with `formatNumber`.
- Column headers should be human-readable (snake_case → Title Case).
- If the data has more than 50 rows, include the full table — the sortable table JS handles it.

### Step 6 — Assemble the HTML

- Start from the Full HTML Template (Section 1).
- Replace every `{PLACEHOLDER}` with the computed values.
- If no chart applies, remove the entire `<!-- Chart Area -->` section.
- If no KPI cards apply, remove the entire `<!-- KPI Cards -->` section.
- Set `{HEADER_LABEL}` to reflect the data domain (e.g., `OpenLDR · HIV Viral Load`).
- Set `{HEADER_META}` to include the date range and generation timestamp.
- Set `{FOOTER_TEXT}` to: `Generated by <a href="#">OpenLDR</a> · openldr-report · {TIMESTAMP}`

### Step 7 — Write the File

- Determine the output filename using the pattern in Section 7.
- Write the complete HTML to disk.
- Confirm the file path to the user.

### Step 8 — Summarize

After writing the file, report:
- File path and name
- Visualization type used and the rule that triggered it
- Number of KPI cards generated
- Number of data rows in the table
- Any data quality observations (missing values, truncated categories, etc.)
