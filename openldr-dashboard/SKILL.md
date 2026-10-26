---
name: openldr-dashboard
description: >
  Use when building, migrating, deploying, or maintaining dashboard apps in the
  OpenLDR monorepo (apps/tb, apps/vl, and new ones such as EID, CD4, CrAg,
  TB-LAM). TRIGGER: user mentions dashboard, migrate dashboard, new dashboard,
  EID dashboard, port legacy dashboard, openldr-frontend, openldr-dashboard,
  add report, add card, add page, fix dashboard, release page, deploy
  dashboard, Coolify app, vl.openldr.org.mz, tb.openldr.org.mz, turborepo app.
metadata:
  author: openldr
  version: "2.0"
---

# Build, Migrate & Maintain OpenLDR Dashboards

Two production dashboards already exist in the monorepo and are the source of truth:

- **TB** (`apps/tb`, tb.openldr.org.mz): the first app. It set the shell, the `MainCard` card, the menu options, `CardDocs` and the drill-down. Its cards are single 300–800-line components with no tests.
- **VL** (`apps/vl`, vl.openldr.org.mz): migrated from the legacy dashboard in October 2026. It keeps TB's look and splits each card into pure `actions.ts` functions plus shared hooks and cards, with tests.

**Core rule: a new dashboard copies the VL structure and the TB/VL look, and reuses code instead of duplicating it.** Read the real files in both apps. These guides tell you where to look; they do not replace reading the code.

**Announce:** "I'm using the openldr:dashboard skill to [migrate/scaffold/add a card/fix/deploy] …"

## Pick the workflow

| Request | Guide |
|---|---|
| Move a legacy dashboard (`openldr-frontend`, `openldr-dashboard`, legacy APIs) into the monorepo, e.g. EID | `references/migration-guide.md`. It calls the next three guides in order. |
| Create a new, empty app | `references/scaffold-guide.md` |
| Add or change a card or page | `references/report-guide.md` |
| Fix, refactor, improve, or change a shared package | `references/maintenance-guide.md` |
| Deploy, release a hidden page, add a domain, or Coolify questions | `references/deploy-guide.md` |
| Which app to copy for what, and where the shared code lives | `references/reference-apps.md` |
| Something fails in a way that looks environmental or strange | `references/pitfalls.md`, read before debugging |

`references/api-endpoint-catalog.md` lists the API endpoints. Confirm them against `api_openldr_python` routes before relying on them.

## Locations

| What | Path |
|---|---|
| Monorepo (pnpm 9 + turbo, Next 15.5, React 18, Tailwind v4, Clerk) | `openldr-monorepo/` (sibling of `api_openldr_python/` under the OpenLDR projects folder) |
| Analytics API (Flask, `/hiv/vl`, `/hiv/eid`, `/tb/gx`, …) | `api_openldr_python/` |
| Monorepo rules (read first) | `openldr-monorepo/CLAUDE.md`, `apps/tb/CLAUDE.md` |
| Past specs and plans to model on | `openldr-monorepo/docs/superpowers/specs/2026-10-12-vl-dashboard-migration-design.md`, `plans/2026-10-13-vl-dashboard-app.md`, `plans/2026-10-13-vl-deploy-cutover.md`, `specs/2026-10-14-platform-foundation-shell-design.md` |

**Baseline:** run `git fetch origin` and read and branch from **`origin/main`**. The local `main` and the main checkout can be months behind. For new work, create a worktree from `origin/main`. Other worktrees under `.claude/worktrees/` may hold unmerged work; ask before building on them. New apps under `apps/*` are picked up by `pnpm-workspace.yaml` and need no `turbo.json` entry.

## Verify (every change)

```bash
pnpm --filter=<app> test                 # vitest (VL-style apps; TB has no tests)
pnpm --filter=<app> exec tsc --noEmit
pnpm --filter=<app> lint
pnpm turbo run build --filter=<app>      # also --filter=tb and --filter=vl when packages/ changed
```

The turbo task is `check-types`, not `typecheck`. Run `pnpm install --frozen-lockfile` only, never a plain `pnpm install` (see pitfalls). For visual work, also start the app (`pnpm --filter=<app> dev`) and look at the page.

## Hard rules

- **API first.** A page ships only after its endpoints exist in `api_openldr_python` and return correct numbers. Never add features to the legacy `openldr-api`/`openldr-backend`.
- **Parity with legacy numbers.** Fix a legacy bug only when it is clearly a bug, and document it in the spec and the card docs.
- **All UI text is in Portuguese**, matching the TB/VL wording ("Exportar para Excel", "Últimos 12 meses", "Sem dados para o período e filtros seleccionados.").
- **No duplicated generic code.** If you need a VL file outside `lib/vl/<domain>` (exports, request gate, report hooks, `ReportCard`, `CardMessage`), move it to `packages/` first. Never fork a third copy.
- **Unfinished pages stay hidden in production** through the app's `UNRELEASED_PAGES` list. A new dashboard stays `ready: false` in `packages/design_system/src/dashboards.ts` until it is live.
- **Outward-facing steps need the user's go-ahead:** push, PR, merge, deploy, DNS, Coolify changes, emails. The user merges PRs.
- **Secrets:** never print, commit, or read `.env.local` or credentials. Ask the user to set Coolify variables.

## Common mistakes

| Mistake | Instead |
|---|---|
| Starting with the UI while the endpoint parity is unknown | Build the parity table first (migration guide, phase 1) |
| Copying a TB card monolith | Use the VL card folder: `constants.ts`, `actions.ts`, `actions.test.ts`, `docs.tsx`, and a thin `index.tsx` |
| Copying `apps/vl/lib/vl/export/*` into a new app | Move it to a shared package, then import it |
| Guessing the auth or deploy setup | Read `middleware.ts`, `config/api.ts`, the Dockerfile and `deploy-guide.md` |
| Declaring a page done because it renders | Run the data review checklist in `report-guide.md` |
| Releasing the dashboard before the production API has the endpoints | Deploy the API to production first (it does not auto-deploy), then release the dashboard |
