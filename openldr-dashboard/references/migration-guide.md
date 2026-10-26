# Migration Guide: Legacy Dashboard → Monorepo App

This guide is based on the VL migration, October 2026. Model every new migration (EID, CD4, CrAg, TB-LAM) on it:
- spec: `openldr-monorepo/docs/superpowers/specs/2026-10-12-vl-dashboard-migration-design.md`
- plan: `plans/2026-10-13-vl-dashboard-app.md`
- cutover plan: `plans/2026-10-13-vl-deploy-cutover.md`

Read the spec before writing yours. It is the template.

**REQUIRED:** use superpowers:brainstorming for the spec, then superpowers:writing-plans for the plan. A migration is architectural work.

## Phase 0: Find what is live

The legacy apps under the OpenLDR projects folder:

| App | Stack | Notes |
|---|---|---|
| `openldr-frontend` | CRA, React 16, chart.js 2 | The legacy VL UI was here |
| `openldr-dashboard` | Next 12 Pages Router, MUI 5, chart.js 3 | Has `pages/eid`, `reports/eid/{summary,clinic,lab}`; calls `BACKEND_API` (the legacy TS API) |
| `openldr-backend` | Node/Express | Legacy VL API |
| `openldr-api` | TS/Express (`api-ts.openldr.org.mz`) | Legacy EID API |

Ask the user which legacy UI and domain users really use. Don't assume from the code. Commented-out cards and out-of-scope modules (for example COVID) are dropped. List what you drop in the spec.

## Phase 1: Inventory and endpoint parity

Before any UI work, produce two tables in the spec.

1. **Card inventory.** One row per live card:
   - page
   - card title (in Portuguese, exactly as shown)
   - chart type
   - filters
   - menu options
   - drill-down
   - legacy endpoint and parameters

   VL had 26 live cards.
2. **Endpoint parity.** For each legacy call:
   - the matching `api_openldr_python` route (`hiv/<module>/routes`)
   - its status: exists / missing / different
   - the field-name differences

   Keep the Python response key names and adapt the frontend to them.

Missing or different endpoints become an **API piece** that is delivered first. Check:
- the module's SQL-compile tests (`tests/test_<module>_*_sql.py`)
- a parity script like `tools/vl_parity_check.py`, which compares legacy and new numbers on the same filters
- real HTTP status codes, not error dicts returned with 200
- Swagger docs on every endpoint

**Parity rule:** match the legacy numbers. When the legacy code is clearly wrong, fix it, mark the item ✱ in the spec and the card docs, and say what changed. Examples from VL: rejection = OR of both rejection codes with an inclusive end date; no 90-day TAT cap.

**Security review of the legacy flow.** VL found two problems:
- the API decoded JWTs without checking the signature
- the legacy patient search sent a client-built SQL `WHERE` clause

Both were fixed before the UI was built. Check the new module for the same problems, and only ever send bound parameters.

## Phase 2: Split into pieces

One branch and one PR per piece, merged in order:

| Piece | Repo | Ships |
|---|---|---|
| 0 | API | Security fixes, if any |
| 1 | API | Endpoint parity + tests, merged to `dev` (auto-deploys to dev.openldr.org.mz) |
| 2 | monorepo | The app (scaffold → `lib/<domain>` core → shared card UI → one task per page → patients → gates, Docker, docs) |
| 3 | both | Deploy and cutover (`deploy-guide.md`) |

Write down your decisions as numbered rulings in the plan, the way VL's P1–P13 are written (plan lines 47–63). Rulings from VL that carry over:
- **Admin status** comes from an API probe, never Clerk metadata.
- **Month labels include the year** (`Out/25`), because 12 months span 13 calendar months.
- **One export implementation**, shared by every card.
- **Map**: use `InteractiveSvgMap` plus the province maps, not `MapCard`.
- **Lab filter**: the dialog must return lab codes when the API expects `lab_code`. The shared `LabDialog` returns districts.

## Phase 3: Build

1. Scaffold: `scaffold-guide.md`. Before copying any generic VL file, check whether it is already in `packages/`. If it isn't, move it there first (`reference-apps.md` lists what to move).
2. Cards: `report-guide.md`, one plan task per page. Keep each page behind `UNRELEASED_PAGES` until it passes the data review.
3. Test against `dev.openldr.org.mz` with `NEXT_PUBLIC_OPENLDR_API` set at startup. Delete `apps/<app>/.next` whenever you change it (see pitfalls).
4. Before production, review every page against the checklist in `report-guide.md`:
   - totals add up at every drill level
   - names match the map
   - empty, error and zero states
   - exports
   - legacy parity

## Phase 4: Deploy and cutover

Follow `deploy-guide.md`. Order matters:
1. Production API.
2. Dashboard app on its own subdomain (users can test it there).
3. Sign-off checklist with the user (one row per card).
4. Optional switch of the legacy domain.

Write down the rollback before switching DNS.

## Done means

- Every card in the inventory is either built or dropped with a documented reason.
- Each page has passed the data review on production data.
- The dashboard is `ready: true` in `packages/design_system/src/dashboards.ts`.
- The default 12-month requests are added to the API's report cache seeds (`tools/report_cache_seeds.py`).
