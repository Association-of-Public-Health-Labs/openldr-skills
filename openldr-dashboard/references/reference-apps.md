# Reference Apps: What to Learn From TB and VL

Paths are relative to `openldr-monorepo/`. Read the files; don't work from this summary alone.

## Which app to copy for what

| Concern | Copy from | Why |
|---|---|---|
| Card folder structure, data fetching, states, tests | **VL** | Pure, tested `actions.ts`; shared hooks; request gate; Portuguese errors |
| Shell, theme, layout, nav, sign-in pages | **Both** (same shared shell) | `DashboardShell`, `PlatformThemeProvider` from `@repo/design_system` |
| Card look, menu options, docs, suggestions | **Both** (`MainCard`, `CardDocs`) | TB defined it; VL wraps it in `ReportCard` |
| Product-type tabs (Ultra/XDR style) | **TB** | `Tabs` + `SegmentedTabsList`/`SegmentedTabsTrigger` from `@repo/design_system/components/ui/tabs` |
| Patients search page (tabs, server paging, name masking) | **TB** `app/(dashboard)/patients/` + VL `components/patients-dialog.tsx` | TB has the full page; VL has the admin-gated drill dialog |
| Facility drill-down (province → district → facility → patients) | **VL** `lib/vl/drill.ts`, `hooks/use-facility-report.ts`, `components/facility-report-card.tsx` | TB's `getNextFacilityType` is repeated in every card |
| Lab cards with a lab selector | **VL** `components/lab-report-card.tsx`, `lib/vl/labs.ts` | |
| Maps, TAT classes, weekly trend | **VL** `app/(dashboard)/transport/` | `InteractiveSvgMap`, `Provinces`, `DrillBreadcrumb`, `WeeklyTrend`, transparent map image |
| AI chat | **TB** (`AIChatProvider` from `@repo/ai`) | Only TB uses it; ask before adding it to a new app |
| Dockerfile, env vars, Coolify | **VL** (newest) | `deploy-guide.md` |

## VL app map (`apps/vl`)

- **Pages:** `app/(dashboard)/{(index),lab,clinic,patients,transport}/page.tsx` are client grids. Each wraps its cards in `w-full @container` and `grid grid-cols-1 @[840px]:grid-cols-2 gap-6`. The route group also has `loading.tsx` and `error.tsx`.
- **Card folder:** `reports/vl-<name>/` holds:
  - `constants.ts`: `CARD_ID`, `TITLE`, `ENDPOINT`
  - `actions.ts`: `fetchData`, `toChart → ChartModel{labels,series}`, `toExcel → ExcelSheet{header,rows}`
  - `actions.test.ts`
  - `docs.tsx`: `<CardDocs overview legend reading filters notes endpoint>`
  - `index.tsx`: about 15 lines that pass those functions to `ReportCard`, `LabReportCard` or `FacilityReportCard`
- **Hooks** (`hooks/use-report.ts`):
  - `useReport(load, deps)`, `useRangeReport`, `useLabReport`
  - The latest request wins, via `lib/vl/request-gate.ts`.
  - The token comes from Clerk `useAuth().getToken()` on each request.
  - They return `subtitle`, `exportSubtitle`, `onSubmit`, `onRestart`, `retry`.
- **Card wrapper** (`components/report-card.tsx`): wraps `MainCard`.
  - Menu options: "Exportar para Excel", "Exportar imagem", optional "Seleccionar laboratórios" and "Reiniciar o relatório".
  - First load (`loading && empty`) shows `MainCardSkeleton`.
  - `CardMessage` shows the error tone with "Tentar novamente", and the empty tone.
  - `imageTargetId` exports one element of the card on a transparent background.
- **API client:**
  - `config/api.ts`: axios with `baseURL: NEXT_PUBLIC_OPENLDR_API`, a Bearer token, and a 60 s timeout.
  - `lib/vl/api.ts`:
    - `vlGet`/`vlGetList` with `VL_BASE="/hiv/vl"`.
    - `cleanParams` drops empty parameters.
    - `paramsSerializer:{indexes:null}`.
    - `ApiError` plus `errorMessage(status)` give Portuguese messages; server text is never shown.
    - `vlGetList` throws if a 200 response is not an array.
- **Auth and roles:**
  - `middleware.ts`: `clerkMiddleware` + `auth.protect()`. `/sign-in` and `/sign-up` are public.
  - `lib/vl/admin-probe.ts` and `lib/vl/admin.tsx` get the admin role from the API: 200/400 means admin, 401/403 means user.
  - `lib/vl/nav.ts` `buildNavItems(path, isAdmin, isProd)` hides Pacientes from non-admins and hides the `UNRELEASED_PAGES` in production builds.
- **Pure lib** (`lib/vl/`): `dates.ts` (`lastYear`, `intervalParam` → `"YYYY-MM-DD,YYYY-MM-DD"`), `format.ts` (`pct` is 0 when the total is 0), `geo.ts` (accent-insensitive `provinceKey`), `series.ts`, `types.ts`, `labs.ts`, `patients.ts`, `drill.ts`, `export/{excel,image,image-colors,image-trim}.ts`.
- **Tests:**
  - `vitest.config.ts`: node environment, aliases for `@/` and `@repo/design_system/*`.
  - Rule: `lib/**`, `actions.ts` and `constants.ts` never import React, Next, MUI or `@repo/*`, so they stay testable in node.
  - Card tests mock `@/lib/vl/api`. They check the endpoint path, the transforms, null and zero handling, and the Excel headers.

## TB app map (`apps/tb`)

- **Pages:**
  - `(index)` = Sumário (status cards, map, pie, by age and specimen, rejections, key indicators)
  - `clinic/` = Província (10 cards)
  - `patients/` = 4 search tabs over `/tb/gx/patients/*`, server paging, `PatientsAdvancedDataTable`, `patient-format.ts` name masking
  - `lab/` still exists but was removed from the nav. Remove a page from the nav instead of leaving it half-wired.
- **Card folder:** `reports/mtb-<name>/` holds `index.tsx` (a monolith with one `useState<ReportState>`), `actions.ts` (`buildApiParams`, prepare functions), `constants.ts` (`API_CONFIG`), `docs.tsx`, `excel-export-utils.ts`, `chart-export-utils.ts` (`ApexCharts.getChartByID(id).dataURI({scale:3})`).
- **Filters come from `MainCard`:**
  - `reportType` `"national"`: date range only
  - `"facility"`: province, district or clinic
  - `"lab"`
  - All of them call `handleSubmit(dates, facilities, facilityType)`.
- **Suggestions:** `app/api/send-suggestion/route.ts` sends them with Resend. Create the client inside the handler.
- **TB quirks to copy carefully:**
  - `tsconfig` maps `@/*` to a non-existent `./src`, so TB uses deep relative imports. VL maps `@/*` to `./*`; use that.
  - Some cards hardcode patient-lookup fallbacks (`"Zambezia"`/`"Quelimane"`).
  - API field names differ between endpoints, including the typo `Resgistered_Samples`.

## Shared packages (`packages/`)

| Package | Use |
|---|---|
| `design_system` | Import as `@repo/design_system/<path under src>`. It contains: **Layout:** `layout/{DashboardShell,SplashScreen,DashboardSwitcher,SettingsDrawer,AccountDrawer}`, `theme/PlatformThemeProvider`, `styles/theme.css`, `dashboards.ts`. **Cards:** `app/organisms/cards/{MainCard,KpiCard,StatusCard,SummaryCard,KeyIndicatorsCard,MapCard,TableCard}`, `app/molecules/skeletons/*`, `app/molecules/docs/CardDocs`. **Charts:** `app/atoms/charts/apex/{Stacked,StackedWithLine,MixedLineBar,Line,SimpleLine,Donut,Pie,BarGroup,KpiBars,ChartScroller,TargetTrend,minimals}`, `app/molecules/charts/WeeklyTrend`. **Maps:** `app/atoms/maps/{InteractiveSvgMap,Provinces,MapLegend}`, `app/molecules/maps/{DrillBreadcrumb,MapHint,MapDrawer,ZoomControl}`. **Tables and metrics:** `app/molecules/metrics/SummaryStrip`, `app/molecules/tables/{SortableTable,IndicatorsTable}`. **UI:** `components/ui/*` (shadcn: the only copy; apps keep none). **Helpers:** `lib/{period,format-number,mask-name,weeks}` |
| `design_system_mui` | Legacy MUI layer. **Apps must not import it** (ESLint error). `@mui/*` imports only warn. |
| `utilities` | Shared non-visual logic and `components/patients-data-dialog` |
| `auth` | Clerk helpers |
| `ai` | `AIChatProvider` and agents (TB) |

## Generic code still inside `apps/vl` (promote before reuse)

`hooks/use-report.ts`, `hooks/use-facility-report.ts`, `components/{report-card,card-message,lab-report-card,facility-report-card,patients-dialog,age-range-dialog,charts/*}`, and `lib/vl/{request-gate,dates,format,geo,drill,export/*}`. The admin probe, nav gate and API client are patterns to copy with a different base path, not files to share as they are.

Move each piece to a shared package in its own task:
- **Visual code** goes to `design_system`.
- **Non-visual code** goes to `utilities`.

Use relative imports inside packages. Point VL at the moved code with VL's tests unchanged and still passing, then use it from the new app. The VL-specific parts stay in VL: `VL_BASE`, `types.ts`, `series.ts` colours, the 16 `LAB_GROUPS`, `patients.ts` filters, and the transport page.
