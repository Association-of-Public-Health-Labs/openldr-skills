# Report Guide — Add or Modify Dashboard Reports

This guide covers adding new reports and modifying existing reports within an OpenLDR dashboard application. Follow each step in order. Do not skip steps.

---

## Adding a New Report

### Step 1: Read Existing Patterns

Before generating any files, scan the target dashboard's existing reports to detect the established file structure and conventions.

```bash
# List all report directories in the target dashboard
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/*/reports/

# List report directories per section
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/lab/reports/
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/clinic/reports/
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/\(index\)/reports/
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/patients/reports/

# Inspect one existing report to understand the file structure
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/lab/reports/<existing-report>/
```

Read at least one complete report (all files) to understand:
- Import paths and aliases used
- Data type shapes and naming conventions
- Chart configuration patterns
- Portuguese text conventions for labels and documentation

If no reports exist in the target dashboard, use the TB 6-file pattern from `tb-reference-patterns.md` as the default structure.

### Step 2: Identify the API Endpoint

Load `api-endpoint-catalog.md` (symlinked in this references directory) and locate the endpoint that serves data for the report.

Key fields to extract from the catalog:

| Field | What to Look For |
|-------|------------------|
| Module path | The API module (e.g., `hivvl`, `eid`, `tb`) |
| View perspective | The analytical perspective (e.g., `lab`, `clinic`, `summary`) |
| Metric | What is being measured (e.g., `suppression`, `positivity`, `turnaround-time`) |
| Time variant | Time granularity (e.g., `monthly`, `quarterly`, `yearly`) |

From the matched endpoint, extract:
- **Full path** — e.g., `/api/v1/hivvl/lab/suppression/monthly`
- **Parameters** — query parameters the endpoint accepts (date range, province, district, facility)
- **Response fields** — the shape of the JSON response (field names, types, nesting)

### Step 3: Determine Placement

Use this table to decide where the report directory goes:

| Report Type | Section | Route Path |
|-------------|---------|------------|
| Laboratory performance, lab metrics | `lab` | `(dashboard)/lab/reports/` |
| Facility/clinic performance, clinical metrics | `clinic` | `(dashboard)/clinic/reports/` |
| Summary, overview, aggregate statistics | `(index)` | `(dashboard)/(index)/reports/` |
| Patient-level data, individual results | `patients` | `(dashboard)/patients/reports/` |

**Directory naming rules:**
- Use kebab-case
- Use a short prefix matching the domain (e.g., `vl-`, `eid-`, `tb-`)
- Keep names descriptive but concise

Examples:
- `vl-suppression-by-province`
- `eid-positivity-by-month`
- `tb-turnaround-time-by-facility`
- `vl-results-by-age-sex`

The final path for a new report will be:
```
$MONOREPO/apps/<app-name>/app/(dashboard)/<section>/reports/<report-name>/
```

### Step 4: Generate Report Files

Create 6 files in the report directory. Use the table below to know what to customize in each file.

| File | What to Customize |
|------|-------------------|
| `constants.ts` | `API_CONFIG.BASE_URL` — set to the endpoint path from Step 2. `DEFAULTS.REPORT_NAME` — Portuguese name for the report (e.g., `"Supressão Viral por Província"`). `CHART_CONFIG` — unique chart ID, series name, and color palette. `UI_CONFIG.TAB_OPTIONS` — tab labels and values if the report supports multiple result views. |
| `actions.ts` | Data type interface matching the API response fields from Step 2. `buildApiParams` function with domain-specific parameters (date range, province, district, facility type). `prepareChartData` function mapping API response fields to chart-ready format. |
| `index.tsx` | Component name matching the report (PascalCase, e.g., `VlSuppressionByProvince`). Chart component selection — pick from the design system (see Chart Types below). Tab labels if using tabs. |
| `excel-export-utils.ts` | Portuguese column headers matching the data fields (e.g., `"Província"`, `"Total de Testes"`, `"Taxa de Supressão"`). `prepareChartDataForExcel` function mapping data fields to spreadsheet columns. |
| `chart-export-utils.ts` | Usually identical to the TB pattern — captures the chart element via `html2canvas` and triggers download. Copy from an existing report unless the chart structure differs. |
| `docs.tsx` | Full Portuguese documentation explaining what the report shows, how to interpret the data, what filters are available, and what the chart represents. |

### Step 5: Wire the Report

Import the new report component into the parent section's `page.tsx` and add it to the responsive grid layout.

```tsx
// In: app/(dashboard)/<section>/page.tsx

import VlSuppressionByProvince from "./reports/vl-suppression-by-province";

// Inside the component's return JSX, add to the grid:
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
  {/* Existing reports */}
  <ExistingReport1 />
  <ExistingReport2 />

  {/* New report */}
  <VlSuppressionByProvince />
</div>
```

Match the grid column span to the report's visual weight:
- Standard chart: `col-span-1`
- Wide table or multi-series chart: `md:col-span-2`
- Full-width summary: `xl:col-span-3`

### Step 6: Verify

Start the dev server and confirm everything works:

```bash
pnpm dev --filter=<app-name>
```

Verification checklist:

- [ ] Report renders without errors in the browser
- [ ] Loading state displays while data is being fetched
- [ ] Data loads and populates the chart/table correctly
- [ ] Chart displays with correct colors, labels, and axes
- [ ] Drill-down navigation works (province -> district -> clinic -> patients)
- [ ] Excel export downloads a valid `.xlsx` file with correct Portuguese headers
- [ ] PNG export captures the chart and downloads a valid image
- [ ] Documentation popup opens and displays Portuguese content
- [ ] Tab switching works if the report has multiple views
- [ ] Error state displays when the API is unreachable
- [ ] Empty state displays when no data is returned
- [ ] Reset button returns all filters to defaults

---

## Modifying Existing Reports

### Read First (Always)

Before making any change, read the complete report directory — all 6 files. Understand the current data flow, chart configuration, and export mappings before editing.

```bash
ls -la $MONOREPO/apps/<app-name>/app/\(dashboard\)/<section>/reports/<report-name>/
```

Read every file in the report directory. Do not modify files you have not read.

### Change Size Decision Table

| Change Size | Examples | Action |
|-------------|----------|--------|
| **Small** — label, color, filter | Update a Portuguese label, change chart color palette, add a filter option, adjust column width, fix a typo | Apply the change directly. Verify dev server still renders correctly. |
| **Large** — chart type, data series, drill-down | Change from bar chart to line chart, add new data series, restructure drill-down hierarchy, change API endpoint, refactor data transformation | Propose the change first — describe what will change across which files and why. Wait for approval before implementing. |

---

## Chart Types Available

The design system provides these chart components. Prefer ApexCharts for consistency with existing dashboards.

### ApexCharts (Preferred)

| Chart Type | Component | Best For |
|------------|-----------|----------|
| Stacked Bar | `ApexStackedBarChart` | Comparing categories with sub-groups (e.g., suppression by province with age breakdown) |
| Bar | `ApexBarChart` | Simple category comparison (e.g., total tests by facility) |
| Line | `ApexLineChart` | Trends over time (e.g., monthly positivity rate) |
| Pie | `ApexPieChart` | Proportional distribution (e.g., result type breakdown) |
| Area | `ApexAreaChart` | Cumulative trends over time (e.g., cumulative tests processed) |

### Recharts (Alternative)

| Chart Type | Component | When to Use |
|------------|-----------|-------------|
| Bar | `BarChart` | When the dashboard already uses Recharts extensively |
| Line | `LineChart` | When the dashboard already uses Recharts extensively |
| Pie | `PieChart` | When the dashboard already uses Recharts extensively |
| Area | `AreaChart` | When the dashboard already uses Recharts extensively |
| Composed | `ComposedChart` | When mixing bar + line in a single chart |

**Rule:** Use whichever library the target dashboard already uses. If starting fresh or if the dashboard uses both, prefer ApexCharts.

---

## Report Capabilities Checklist

Every report should support all of the following capabilities. Use this checklist when creating or reviewing a report.

- [ ] **Date range filtering** — User can select start and end dates (default: last 12 months)
- [ ] **Drill-down navigation** — Province -> District -> Clinic -> Patients hierarchy
- [ ] **Tab switching** — Multiple result views when the data supports it (e.g., by age, by sex, by result type)
- [ ] **Excel export** — Downloads `.xlsx` with Portuguese column headers and formatted data
- [ ] **PNG export** — Captures the chart as a PNG image and downloads it
- [ ] **Documentation popup** — In-app Portuguese documentation explaining the report
- [ ] **Suggestion/feedback** — User can submit feedback or suggestions about the report
- [ ] **Reset to defaults** — Button to clear all filters and return to initial state
- [ ] **Loading state** — Skeleton or spinner while data is being fetched
- [ ] **Error state** — User-friendly message when the API call fails
- [ ] **Empty state** — Informative message when no data matches the current filters
