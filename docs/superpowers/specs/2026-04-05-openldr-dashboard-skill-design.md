# OpenLDR Dashboard Skill — Design Spec

## Overview

A new `openldr-dashboard` subskill that handles the full lifecycle of dashboards in the OpenLDR turborepo monorepo (`openldr-monorepo`): scaffolding new dashboard apps, adding reports/visualizations, and maintaining/improving existing dashboards. The skill operates across `apps/` and all shared `packages/` (design_system, auth, ai, utilities).

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Scope | Full lifecycle — scaffold, reports, maintenance | Single entry point for all dashboard work |
| Domain specificity | Generic/domain-agnostic | Works with any API module path, automatically supports future panels |
| Package scope | Dashboard + all packages | Can modify design_system, ai, auth, utilities when dashboard work requires it |
| API integration | Independent | Reads endpoint catalog directly, doesn't invoke openldr-query-api. Matches how TB dashboard works (Axios in actions.ts) |
| Report structure | Context-driven | Reads existing patterns in target dashboard, defaults to TB 6-file pattern for new dashboards |
| Language | i18n-ready, Portuguese primary | Uses next-intl. Portuguese as default locale, other languages supported via translation files |
| Change approach | Contextual | Small/clear changes applied directly. Large/structural changes proposed before acting |
| Architecture | Sub-routed skill with reference guides | SKILL.md acts as router, heavy lifting in focused reference guides loaded on-demand |

## Trigger & Invocation

### Detection keywords

- **Scaffold:** "create dashboard", "new dashboard", "build dashboard for", "scaffold"
- **Report:** "add report", "new report", "new chart", "add page", "new visualization", "add section"
- **Maintain:** "fix", "improve", "update", "refactor", "optimize", "change", "modify", "bug"

### Integration with openldr router

New entry in `openldr/SKILL.md`:

| User Intent | Skill to Invoke |
|---|---|
| Build, create, modify, or improve dashboards in the turborepo monorepo | `openldr:dashboard` |

Invocation: `Skill: openldr:dashboard`

## Skill Structure

```
openldr-dashboard/
├── SKILL.md                              # Intent detection + routing to guides
├── references/
│   ├── scaffold-guide.md                 # Full scaffold workflow for new dashboard apps
│   ├── report-guide.md                   # Create/modify reports within a dashboard
│   ├── maintenance-guide.md              # Improve, fix, refactor existing dashboards
│   ├── api-endpoint-catalog.md           # Symlink to openldr-query-api's catalog
│   └── tb-reference-patterns.md          # Extracted conventions from the TB dashboard
└── scripts/
    └── scaffold-dashboard.sh             # Bootstrap new app in the monorepo
```

## SKILL.md — Entry Point

### Frontmatter

```yaml
---
name: openldr-dashboard
description: >
  Use when building, maintaining, or improving dashboards in the OpenLDR
  turborepo monorepo. Scaffolds new dashboard apps, adds reports/visualizations,
  fixes bugs, and improves UX. Works across apps/ and packages/ (design_system,
  auth, ai, utilities).
  TRIGGER: user mentions dashboard, create dashboard, new dashboard, add report,
  fix dashboard, improve dashboard, dashboard component, dashboard page,
  turborepo app, monorepo app.
metadata:
  author: openldr
  version: "1.0"
---
```

### Process Flow

```
User request → Announce → Resolve monorepo → Detect intent → Load guide → Execute → Verify
```

1. **Announce** — "I'm using the openldr:dashboard skill to [scaffold/add report/improve] the dashboard."
2. **Resolve working directory** — The monorepo lives at `../openldr/openldr-monorepo/` relative to the openldr-skills repo (i.e., sibling directory `openldr/openldr-monorepo`). Resolve the absolute path from the skills repo location. If not found at that path, ask the user for the monorepo location.
3. **Detect intent** — Match keywords to determine which guide to load:
   - Scaffold → load `references/scaffold-guide.md`
   - Report → load `references/report-guide.md`
   - Maintain → load `references/maintenance-guide.md`
4. **Context gathering** — Read relevant files in the target dashboard (or monorepo root for scaffold). For report/maintain modes, read existing patterns first.
5. **Execute** — Follow the loaded guide's workflow.
6. **Verify** — Confirm the change works (dev server boots, no type errors).

### Anti-Rationalization

| Temptation | Reality |
|---|---|
| "I'll just write the code without reading existing patterns" | Always read existing reports/components first. Context-driven. |
| "I don't need the scaffold script for a new app" | Use the scaffold. Manual setup misses configuration. |
| "This change is small, no need to check downstream impact" | If touching packages/, always check which apps are affected. |
| "I'll skip i18n for now" | All UI text goes through i18n from day one. Portuguese default. |
| "I'll use a different chart library" | Follow what the target dashboard already uses. |

## Scaffold Guide

The `scaffold-guide.md` handles creating a brand new dashboard app in `apps/<name>/`.

### Process

1. **Gather requirements** — Dashboard name, which API module(s) it consumes, navigation sections (e.g., lab/clinic/patients), number of initial reports.
2. **Scaffold the app** via `scaffold-dashboard.sh`:
   - Validates app name doesn't already exist in `apps/`
   - Creates full directory structure (see below)
   - Generates `package.json` with workspace dependencies
   - Generates template files following TB patterns (clean templates, not copies)
   - Prints next steps
3. **Generate navigation** — Based on sections specified, create navbar options and route group folders.
4. **Verify** — Run `pnpm install` from monorepo root, then `pnpm dev --filter=<app-name>`.

### Scaffolded Structure

```
apps/<app-name>/
├── app/
│   ├── (auth)/sign-in/page.tsx
│   ├── (auth)/sign-in/client.tsx
│   ├── (auth)/sign-up/page.tsx
│   ├── (auth)/sign-up/client.tsx
│   ├── (auth)/layout.tsx
│   ├── (dashboard)/layout.tsx
│   ├── (dashboard)/(index)/page.tsx
│   ├── (dashboard)/<section>/page.tsx       # one per section
│   ├── layout.tsx
│   ├── page.tsx
│   └── client.tsx
├── config/api.ts
├── context/
├── hooks/useLayoutSettings.ts
├── themes/dark.ts
├── themes/light.ts
├── components/ui/
├── public/
├── messages/pt.json                         # i18n Portuguese (default)
├── messages/en.json                         # i18n English (skeleton)
├── i18n.ts
├── middleware.ts
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── postcss.config.mjs
├── eslint.config.mjs
├── components.json
├── .env.local.template
└── package.json
```

### Package Dependencies

Workspace: `@repo/design_system`, `@repo/auth`, `@repo/ai`, `@repo/utilities`

Runtime: Next.js 15, React 18, `@clerk/nextjs`, Axios, Recharts, ApexCharts, Zustand, `next-intl`, `next-themes`, `@tanstack/react-table`, `xlsx`, `html2canvas`, Tailwind CSS 4, Radix UI primitives, Lucide React icons

### Key Wiring Patterns

- **Root layout:** `ClerkProvider` + `ThemeProvider` (`next-themes`)
- **Dashboard layout:** `AppProvider` (design system themes) → `AIChatProvider` (with `dashboard` prop) → `DashboardLayout` (sidebar, navbar, user menu)
- **Auth middleware:** Clerk's `clerkMiddleware` protecting all routes except `(auth)/*`
- **API client:** Axios instance in `config/api.ts` using `NEXT_PUBLIC_OPENLDR_API` base URL with Bearer token
- **State:** Zustand via `useLayoutSettings` hook for UI settings (compact mode, panel sizes, theme)
- **Themes:** Separate `themes/dark.ts` and `themes/light.ts`, consumed by `AppProvider`

### Scaffold Does NOT

- Create reports (that's the report guide's job)
- Populate translations beyond skeleton keys
- Configure specific API endpoints

## Report Guide

The `report-guide.md` handles adding, modifying, or removing reports within an existing dashboard.

### Adding a New Report

1. **Read existing patterns** — Scan target dashboard's existing reports to detect the established file structure. If no reports exist, default to TB 6-file pattern.
2. **Identify the API endpoint** — Load `api-endpoint-catalog.md` to match the user's request to the correct endpoint path, parameters, and response shape.
3. **Determine placement** — Which section/route group does this report belong to?
4. **Generate report files** following the detected pattern.
5. **Wire the report** — Import report component into the parent section's `page.tsx`, add to grid layout.
6. **Verify** — Confirm dev server renders the new report without errors.

### Default 6-File Report Structure (from TB)

| File | Purpose |
|---|---|
| `index.tsx` | Main React component — chart + table + filters, uses design system components, Zustand for state |
| `actions.ts` | API fetch functions, data transformation, type definitions, parameter builders |
| `constants.ts` | `API_CONFIG` (endpoint URL, timeout), `DEFAULTS` (time interval, facility type), `CHART_CONFIG` (colors, dimensions) |
| `excel-export-utils.ts` | Excel export with `xlsx` — column mapping, formatting, filename generation |
| `chart-export-utils.ts` | PNG export via `html2canvas` — chart element capture, download trigger |
| `docs.tsx` | In-app documentation component in Portuguese — describes what the report shows and how to interpret it |

### Standard Report Capabilities

- Date range filtering (default: last 12 months)
- Facility hierarchy drill-down (province → district → clinic → patients)
- Tab switching when multiple result types exist
- Excel and PNG export
- In-app documentation popup
- Suggestion/feedback submission
- Reset to defaults

### Modifying Existing Reports

Read the current report files first. Small changes (update a label, change colors, add a filter) — act directly. Structural changes (change chart type, restructure data flow) — propose before acting.

## Maintenance Guide

The `maintenance-guide.md` handles improvements, bug fixes, refactoring, and optimization.

### Contextual Approach

| Change Size | Behavior |
|---|---|
| Small/clear — fix a bug, update a label, adjust styling, add a filter | Read relevant files, make the change directly |
| Large/structural — restructure navigation, add a new section, refactor patterns, change state management | Read code, propose changes, wait for approval, then implement |

### Process

1. **Identify scope** — What dashboard and which files are affected? Read them.
2. **Detect change size** — Small (single file or isolated) vs. large (multiple files, cross-cutting, architectural).
3. **For small changes:** Apply directly, verify dev server still works.
4. **For large changes:** Present what will change and why, get approval, then implement.

### Scope Coverage

| Target | Examples |
|---|---|
| `apps/<dashboard>/` | Fix report bug, add filter, update chart colors, improve responsiveness |
| `packages/design_system/` | Create new UI component, modify existing component, add theme tokens |
| `packages/ai/` | Update AI chat context, add new agent capabilities, fix AI integration |
| `packages/auth/` | Modify Clerk config, update middleware, adjust auth flow |
| `packages/utilities/` | Add shared helper functions, update existing utilities |

### Guardrails

- Never modify `packages/` without understanding downstream impact — check which apps import the affected code
- When modifying design system components, verify the change works across all apps that consume it
- When modifying auth, test that sign-in/sign-out flows still work
- Always preserve existing i18n structure when editing UI text

## Reference Files

### `tb-reference-patterns.md`

Distilled guide of conventions extracted from the TB dashboard. Not a copy of TB code — abstracted pattern guide with annotated snippets adaptable to any domain. Contains:

- Dashboard layout wiring pattern (DashboardLayout + AppProvider + AIChatProvider)
- Report component anatomy (standard hooks, state shape, JSX structure)
- `actions.ts` patterns (API param building, fetch functions, type definitions)
- Chart integration patterns (Recharts + ApexCharts usage, config objects)
- Export patterns (Excel via `xlsx`, PNG via `html2canvas`)
- Theming pattern (dark/light mode objects, `useTheme` from `next-themes`)
- Zustand store pattern (settings hook, panel resize state)
- Clerk auth patterns (middleware, `useUser`/`useAuth` in layout)
- i18n patterns (next-intl structure, Portuguese defaults)

### `api-endpoint-catalog.md`

Symlinked from `openldr-query-api/references/api-endpoint-catalog.md`. Full list of 126+ endpoints with paths, parameters, and response shapes. Used to generate correct `actions.ts` and `constants.ts` files.

## `scaffold-dashboard.sh` Script

### Usage

```bash
scripts/scaffold-dashboard.sh <app-name> [--sections "section1,section2,section3"]
```

### Example

```bash
scripts/scaffold-dashboard.sh hivvl --sections "summary,lab,clinic,patients"
```

### Behavior

1. **Validate** — App name doesn't exist in `apps/`, monorepo root is reachable
2. **Create directory structure** — Full scaffold as defined above
3. **Generate `package.json`** — With workspace dependencies and standard runtime deps
4. **Generate template files** — Minimal working versions following TB patterns
5. **Print next steps** — `pnpm install` and `pnpm dev --filter=<app-name>`

### Does NOT

- Generate reports
- Populate translations
- Configure specific API endpoints

## Changes to Existing Skills

### `openldr/SKILL.md`

Add to routing table:

| User Intent | Skill to Invoke |
|---|---|
| Build, create, modify, or improve dashboards in the turborepo monorepo | `openldr:dashboard` |

Add to "When to Use Each Skill":

**`openldr:dashboard`** — User mentions: create dashboard, new dashboard, build dashboard for, add report, add chart, add page, fix dashboard, improve dashboard, update dashboard, dashboard component, monorepo app, turborepo app.

Add to "How to Invoke":

```
Skill: openldr:dashboard
```

### No changes to other skills

The dashboard skill operates independently. `openldr-report` remains separate (standalone HTML files, not dashboard pages).
