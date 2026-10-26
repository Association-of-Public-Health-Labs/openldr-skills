# Deploy Guide: Coolify, Env Vars, Release and Cutover

All apps run on the OpenLDR Coolify instance. Use the `coolify-openldr` MCP:
- `list_applications` finds apps.
- `diagnose_app <domain>` checks one.
- `deploy` (`force: true` is a no-cache rebuild) and `deployment`/`application_logs` follow a deploy.

The MCP cannot exec into containers. **Ask the user before** any create, deploy, environment-variable or domain change. Look up uuids with the MCP; don't hardcode them.

## Environments

| App | Coolify name / domain | Branch | Deploys on merge? |
|---|---|---|---|
| Python API, dev | dev.openldr.org.mz | `dev` | yes |
| Python API, prod | api.openldr.org.mz ("OpenLDR - API - Production") | `master` | **no**, deploy manually after merging `dev` → `master` |
| TB dashboard | tb.openldr.org.mz | monorepo `main` | yes (no watch paths: every `main` merge redeploys TB) |
| VL dashboard | vl.openldr.org.mz | monorepo `main` | was created through the API; check whether merges trigger it, and deploy manually if not |

## Dockerfile (copy `apps/vl/Dockerfile`)

- `node:22`, `corepack enable`.
- `mkdir /app && chown node` before `WORKDIR`. `COPY --chown` does not chown the WORKDIR itself.
- `COPY --chown=node:node . .`, `USER node`.
- `pnpm install --frozen-lockfile --prod=false`, then `pnpm turbo run build --filter=<id>`.
- `CMD pnpm --filter=<id> start`, port 3000.
- Coolify uses build pack `dockerfile`, base directory `/` (the repo root is the build context), Dockerfile `/apps/<id>/Dockerfile`.
- Set `watch_paths` to `apps/<id>/**`, `packages/**`, the lockfile and the root config, so other apps' merges don't rebuild it.
- Health check: `/sign-in` returns 200. `/` returns a 307 redirect to sign-in.

## Environment variables (names only; the user enters the values)

| Variable | Build time | Runtime |
|---|---|---|
| `NEXT_PUBLIC_OPENLDR_API` (dev or prod API URL) | **yes** | yes |
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | **yes** | yes |
| `NEXT_PUBLIC_DASHBOARD_URL_<ID>` (optional overrides) | **yes** | yes |
| `CLERK_SECRET_KEY` | no | yes |
| `RESEND_API_KEY`, `SUGGESTION_EMAILS`, `DASHBOARD_EMAIL` (suggestions) | no | yes |

`NEXT_PUBLIC_*` values are **inlined at build time**. Changing one needs a rebuild (`force: true`), not a restart. A deploy started before the variables exist fails with a 500 ("Missing publishableKey").

The API side needs these on its Coolify app:
- `CLERK_ISSUER` and `CLERK_JWTS_URL`. Without them every request returns 401, which the UI shows as "sessão expirou".
- The database bind variables for every database the module uses. A database on a different server needs its own host, user and password variables (the ReportData case in `pitfalls.md`).

## New app checklist

1. DNS: an A record `<id>` → the Coolify server. Without it, the wildcard record captures the name and Let's Encrypt fails. Check with `dig`.
2. Ask the user, then create the app with `application create_github` (GitHub app `aphl-projects`, same project, environment, server and destination as VL; copy them from `get_application` on VL).
3. Settings: build pack, Dockerfile, base directory, port, domain, `watch_paths`, health check (above).
4. Ask the user to add the env variables (build-time ones marked as build-time). Then deploy.
5. Verify:
   - `curl -sI https://<domain>/` returns 307
   - `/sign-in` returns 200
   - the served JS chunks contain the expected API host
   - the user signs in and checks one page

## Releasing a page or a dashboard to production

1. **API first:**
   - merge the API PRs to `dev` and verify on dev
   - open a `dev` → `master` release PR containing only the needed PRs; the user merges it
   - the user adds any new production variables
   - deploy production and verify: endpoint without a token → 401; with the user's session token → data
2. **Then the dashboard:**
   - a PR that removes the page from `UNRELEASED_PAGES` (and updates `nav.test.ts`), or sets `ready: true` in `dashboards.ts` for a new dashboard; the user merges it
   - deploy if the merge doesn't trigger one
   - check the page on the production domain, then check TB still works, because every `main` merge redeploys it
3. Add the page's default requests to the API's report cache seeds (`tools/report_cache_seeds.py`). The cache is warmed at 05:00 and 13:00 Maputo time.

## Cutover from a legacy domain (when replacing a live legacy app)

1. Production API parity is deployed. Run the parity script against production.
2. The user signs off one row per card.
3. Clerk accounts are prepared, and admins have `role='Admin'` in the API users table. The announcement is sent by the user.
4. Lower the DNS TTL. **Write down the rollback.** Switch the legacy name to the new app, add both domains to the Coolify app, and redeploy.
5. Retire the legacy hosting after a grace period.

## Pull requests

The local `origin` URL of the monorepo is stale since the transfer to Association-of-Public-Health-Labs, so `gh pr create` fails. Use:

```bash
gh api -X POST repos/Association-of-Public-Health-Labs/openldr-monorepo/pulls \
  -f head=<branch> -f base=main -f title="…" -f body="…"
```
