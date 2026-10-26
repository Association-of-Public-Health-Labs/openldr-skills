# Pitfalls: Symptom → Cause → Fix

These come from building TB and VL. Check this table before debugging from scratch.

| Symptom | Cause | Fix |
|---|---|---|
| "A sua sessão expirou. Inicie sessão novamente." on every card | The API returns 401: `CLERK_ISSUER`/`CLERK_JWTS_URL` are missing on the API (often a local API with an empty `.env`) | Point the app at dev.openldr.org.mz, or have the user configure the API's env. Check the API response body |
| "Não foi possível contactar o servidor" after changing the API URL | Turbopack/`.next` cache still has the old inlined `NEXT_PUBLIC_OPENLDR_API` | Stop dev, `rm -rf apps/<id>/.next`, restart with the variable set |
| Production still calls the old API host, or Clerk shows "Missing publishableKey" | `NEXT_PUBLIC_*` are inlined at build time | Set them as build-time variables in Coolify and rebuild with `force: true` |
| API 500 "Cannot open database X (4060)" | That database lives on a different SQL Server from the bind's default host (ReportData is on a different server from the dev databases) | Give the database its own `*_HOST/_USER/_PASSWORD` settings in `configs/paths.py` and set them in Coolify |
| "Não foi possível exportar a imagem" | html2canvas cannot parse `oklch()`/`oklab()`/`lab()`/`color()` from Tailwind v4 | Use the shared export, which replaces modern colours on the clone (`image-colors.ts`). Log the real error with `console.error` |
| Exported map image has a background or the hints in it | The whole card was captured | Pass `imageTargetId` for the map element; export with `backgroundColor: null` + trim |
| ApexCharts crashes or shows "null" bars | A null category from the API | Filter null names in `toChart`, or group them as "Sem …" |
| Selected district on a province map is drawn with a huge outline | `stroke-width` set from a CSS height | Use a numeric stroke width (fixed in Zambézia) |
| Map label sits on the wrong spot (for example Pemba) | SVG label position | Use the label position overrides (`packages/design_system_mui/src/atoms/maps/provinces/district-fixes.ts`) |
| District missing from the map | No geometry for it in the map file (for example Mecufi) | Known limit; list it in the card docs |
| Hovering a chart redraws it, or hover marks don't line up | The parent re-renders the chart | `memo` the chart and track hover with refs. Align overlays with Apex `w.globals.translateX`/`gridWidth` |
| Clicks are swallowed while hovering the province map | The map re-injects its SVG when props change | Keep the props stable (`useMemo`/`useCallback`) |
| `next build` fails on `new Resend()`/`new OpenAI()` | A client created at module level runs at build time | Create the client inside the handler |
| TB `tsc` breaks after an install | A plain `pnpm install` re-resolved `csstype` | `pnpm install --frozen-lockfile` only; revert lockfile drift |
| Container can't write to `/app` | `COPY --chown` doesn't chown the WORKDIR | `mkdir /app && chown node` before `WORKDIR` |
| New subdomain gets no certificate | The wildcard DNS captures names without an A record | Add an A record, check with `dig`, redeploy |
| API 500 on repeated `interval_dates`, or wrong results | The endpoint expects one comma-separated string | Send `"start,end"` once; check each route |
| Everyone appears as admin in the UI | The admin probe reads 400 as admin. An API that validates parameters before the role would return 400 to everyone | Keep the API's role check first. The API still returns 403 for the data |
| `gh pr create` fails | Stale `origin` URL after the repo transfer | `gh api -X POST repos/Association-of-Public-Health-Labs/<repo>/pulls -f head=… -f base=…` |
| `pgrep -f`/`pkill -f` kills your own shell | The pattern matches the command running it | Find the port's process with `lsof -i :<port>` or `ss -ltnp` instead |
| Coolify build dies mid-install with no error | A flaky build | Retry once. Look at the deployment logs before changing anything |
| Week numbers off by one | OpenLDR weeks run Sunday–Saturday | Use `@repo/design_system/lib/weeks` |
