# Scaffold Guide: Create a New Dashboard App

There is no generator script. Copy the **VL** app's skeleton and remove what is VL-specific; it is the newest app and matches production. Paths are relative to `openldr-monorepo/`. `<id>` is the short id (`eid`, `cd4`, …).

## 1. Collect inputs (ask for any that are missing)

| Input | Example |
|---|---|
| id (lowercase, `^[a-z][a-z0-9-]*$`, must not exist in `apps/`) | `eid` |
| Name and portal title (Portuguese) | "Diagnóstico Precoce Infantil", "Portal de DPI" |
| Primary colour (must differ from VL `#00B000` and TB `#FF3030`) | ask |
| API base path | `/hiv/eid` |
| Pages (nav labels in Portuguese) | from the migration spec |
| Production domain | `eid.openldr.org.mz` |

## 2. Copy the skeleton from `apps/vl`

Copy these, then rename every `vl`/`VL`:
- `package.json`: name `<id>`; keep the same scripts (`dev --turbopack`, `build`, `start`, `lint`, `test`). Pass a free port with `-p` when you run it next to TB and VL.
- `tsconfig.json`, with `@/*` → `./*`.
- `next.config.ts`, `postcss.config.mjs`, `eslint.config.mjs`, `components.json`, `tailwind.config.ts`, `theme.config.ts`, `vitest.config.ts`, `middleware.ts`, `Dockerfile` (change `--filter=vl` to `--filter=<id>`).
- `config/api.ts`.
- `app/layout.tsx`: `<html data-dashboard="<id>">` and `<PlatformThemeProvider dashboard="<id>">`.
- `app/globals.css`: it imports `packages/design_system/src/styles/theme.css` and declares the `@source` paths.
- `app/(auth)/*`.
- `app/(dashboard)/{layout,loading,error}.tsx`.
- `lib/<id>/{api,nav,admin-probe,admin}.ts(x)` and their tests: change the base path, the probe endpoint and the page list.

Generic VL code (hooks, `ReportCard`, `CardMessage`, export, request gate, dates, format, drill) is **not copied**. It is imported from a shared package. If it hasn't been moved yet, moving it is the first task (`reference-apps.md`, last section).

Don't copy `.env.local`. Write a `.env.example` with only the variable names (`deploy-guide.md`).

## 3. Register the dashboard in the shared shell

- `packages/design_system/src/dashboards.ts`:
  - add `<id>` to `DashboardId`
  - add an entry with `ready: false`
  - add a literal `process.env.NEXT_PUBLIC_DASHBOARD_URL_<ID>` read in `ENV_OVERRIDES`
- `packages/design_system/src/styles/theme.css`: add a `[data-dashboard="<id>"]` block for the primary colour.
- Update the `dashboards.ts` tests if any exist. TB and VL now list the new dashboard as "Em breve" until it is `ready`.

## 4. Nav and pages

- In `lib/<id>/nav.ts`, list the pages with Portuguese labels. Put every page in `UNRELEASED_PAGES` until it passes the data review.
- Create one `page.tsx` per page with the empty grid (`w-full @container`, `grid grid-cols-1 @[840px]:grid-cols-2 gap-6`).

## 5. Install and verify

```bash
pnpm install --frozen-lockfile     # if the lockfile must change for the new workspace, tell the user
pnpm --filter=<id> test
pnpm --filter=<id> exec tsc --noEmit
pnpm --filter=<id> lint
pnpm turbo run build --filter=<id> --filter=vl --filter=tb
NEXT_PUBLIC_OPENLDR_API=https://dev.openldr.org.mz pnpm --filter=<id> dev -p <port>
```

Adding a workspace means `pnpm-lock.yaml` must change, so `--frozen-lockfile` will refuse to install. Tell the user before updating the lockfile. Check that the lockfile diff only adds the new app's entry. If it re-resolves other packages (it has re-resolved `csstype` and broken TB's tsc before), revert and pin them.

The user signs in. Never type passwords. Check that the shell, the nav, the dashboard switcher and the theme colour work. Then go to `report-guide.md`.
