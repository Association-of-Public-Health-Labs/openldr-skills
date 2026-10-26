# Report Guide: Add or Change a Card or Page

A "report" is one card on a page. New cards use the **VL card folder**. When you change an existing TB card, follow the pattern already in that card; don't refactor it unless the user asks.

## Adding a card

### 1. Read before writing

- Read one complete VL card of the same kind:
  - range card: `app/(dashboard)/(index)/reports/vl-*`
  - lab card: `lab/reports/vl-*`
  - facility drill card: `clinic/reports/vl-*`
- Read the wrapper it uses (`components/report-card.tsx`, `lab-report-card.tsx` or `facility-report-card.tsx`).
- Read the legacy card it replaces: its title, chart, filters, options and legend, for parity.

### 2. Confirm the endpoint

Find the route in `api_openldr_python/hiv/<module>/` (or `tb/`). Write down:
- the path
- the parameters: `interval_dates` as a single `"YYYY-MM-DD,YYYY-MM-DD"` string (check the route; TB had to switch back to this format)
- `province[]`/`district[]`, `lab_code`, `disaggregation`
- the exact response keys, which may contain typos

Call it once on dev with a signed-in token from the browser session (`window.Clerk.session.getToken()` in page JS; never print the token). Look at the real rows, including nulls and zeros.

### 3. Create the folder `app/(dashboard)/<page>/reports/<id>-<name>/`

| File | Contains |
|---|---|
| `constants.ts` | `CARD_ID` (unique, same as the folder name), `TITLE` (Portuguese, as in legacy), `ENDPOINT` (path under the module base) |
| `actions.ts` | `fetchData(range, …, token)` through the app's `<id>Get`/`<id>GetList`, `toChart(rows) → ChartModel`, `toExcel(rows) → ExcelSheet`. Pure functions only: no React, Next, MUI or `@repo/*` |
| `actions.test.ts` | Mocks the API module. Asserts the endpoint and parameters, the chart transform, null and zero rows, and the Excel header row |
| `docs.tsx` | `<CardDocs>` with overview, legend, reading, filters, notes (including any ✱ parity deviation) and endpoint |
| `index.tsx` | `"use client"`. About 15 lines passing the above to the wrapper card |

Rules for the transforms:
- Drop rows with a null category; a null category crashes ApexCharts.
- Percentages are 0 when the total is 0.
- Month labels include the year (`Out/25`).
- Province and district names match the map keys (accent-insensitive).

### 4. Wire it

Import it in the page's `page.tsx` grid. A card that needs the full width uses `@[840px]:col-span-2`.

### 5. Verify

Run the commands in SKILL.md, then open the page in the app (the user signs in) and go through the data review below.

## Data review checklist (each card, before a page leaves `UNRELEASED_PAGES`)

- [ ] Numbers match the legacy dashboard on the same period and filters, or the difference is a documented ✱.
- [ ] Totals add up at every level: national = sum of provinces = sum of districts.
- [ ] Every province and district name in the data matches the map. List the units with no map shape as known limits.
- [ ] Rows with no name are grouped as "Sem província" / "Sem distrito" / "Sem unidade sanitária", shown last, and not dropped silently.
- [ ] The first load shows a skeleton. Empty data shows "Sem dados para o período e filtros seleccionados." An API error shows a Portuguese message with "Tentar novamente".
- [ ] The period filter and "Reiniciar o relatório" work. The subtitle shows the period.
- [ ] Drill-down works: province → district → facility, and patients open for admins only.
- [ ] "Exportar para Excel" has a title, the period and Portuguese headers. "Exportar imagem" works in light and dark mode.
- [ ] The docs dialog opens and is correct.
- [ ] Response time is noted (2–5 s is normal). Slow default requests are added to the report cache seeds.
- [ ] Check the layout at phone width if you can resize the window. If you can't, say so.

Report each finding to the user with evidence. Ask the user about anything that is a product decision, for example whether a status badge should use the target or the predominant class.

## Changing an existing card

Read every file in the card folder first.
- **Small changes** (label, colour, an extra filter option): apply them directly.
- **Large changes** (chart type, series, drill-down, endpoint): describe the change and the files it touches, and wait for approval.
- **Redesign work:** change visuals only. Props, cards, menus, exports, data flow and routes stay the same, and existing tests pass unchanged.
