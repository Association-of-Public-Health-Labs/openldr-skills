# Maintenance Guide — Improve & Fix Existing Dashboards

This guide covers the process for improving, fixing, refactoring, and optimizing existing dashboards and shared packages in the OpenLDR turborepo monorepo. Follow every step in order. Do not skip verification.

---

## Process

### Step 1: Identify Scope

Determine exactly what is affected by the change:

1. Read the file(s) the user referenced or described
2. Identify which app(s) under `$MONOREPO/apps/` are affected
3. Check if any shared packages under `$MONOREPO/packages/` are involved
4. Read related files (imports, parent components, sibling routes) to understand the surrounding context
5. Read recent git history for the affected files: `git log --oneline -10 -- <file>`

### Step 2: Detect Change Size

Classify the change as **small** or **large** using this table:

| Criteria | Small | Large |
|----------|-------|-------|
| Files affected | Single file or isolated module | Multiple files across directories |
| Scope | Contained within one component/page | Architectural or cross-cutting |
| Package impact | No shared package changes | Modifies `packages/` code |
| Action | Execute directly | Propose plan first, get approval |

**Small change examples:**

- Fix a report rendering bug
- Update a label or translation string
- Change chart colors or styling
- Add a filter option to an existing filter component
- Fix CSS layout or spacing issues
- Update an API endpoint URL

**Large change examples:**

- Add a new navigation section or route group
- Restructure report organization or folder layout
- Change state management approach
- Create a new design system component
- Modify the authentication flow
- Refactor drill-down interaction patterns
- Add a new AI agent capability

### Step 3: Execute

**Small changes** — execute directly. Make the fix, update the code, and move to verification.

**Large changes** — propose first:

1. Write a short plan listing every file that will be created, modified, or deleted
2. Describe the rationale for the approach
3. Get user approval before making any edits
4. Execute the approved plan step by step

### Step 4: Verify

Every change, regardless of size, must pass these checks before completion:

1. **Dev server boots** — `pnpm dev --filter=<app-name>` starts without errors
2. **No type errors** — `pnpm check-types` passes with zero errors
3. **Build succeeds** — `pnpm build` completes without failures
4. **No regressions** — if tests exist, they still pass

<HARD-GATE>
Do not declare the task complete until the dev server boots without errors and TypeScript check passes with zero errors.
</HARD-GATE>

---

## Working with Shared Packages

<HARD-GATE>
Before modifying any file under `packages/`, check downstream impact. A change to a shared package can silently break multiple apps.
</HARD-GATE>

### Check Downstream Impact

Before editing a shared package, run these commands to find every app that imports from it:

```bash
# Find consumers of the design system
grep -r "from '@repo/design_system" "$MONOREPO/apps/" --include="*.ts" --include="*.tsx" -l

# Find consumers of the AI package
grep -r "from '@repo/ai" "$MONOREPO/apps/" --include="*.ts" --include="*.tsx" -l

# Find consumers of the auth package
grep -r "from '@repo/auth" "$MONOREPO/apps/" --include="*.ts" --include="*.tsx" -l

# Find consumers of the utilities package
grep -r "from '@repo/utilities" "$MONOREPO/apps/" --include="*.ts" --include="*.tsx" -l
```

### Package-Specific Rules

| Package | Rules |
|---------|-------|
| `design_system` | Never change existing component props without checking all consumers. Prefer adding optional props over modifying required ones. Changing a prop name or removing a prop is a breaking change. |
| `ai` | `AIChatProvider` changes affect all dashboards that use AI features. After any change, test the AI chat in each consuming app. |
| `auth` | Test both sign-in and sign-out flows after any change. Never break SSO. Auth regressions lock users out of every app. |
| `utilities` | Low-risk in general, but verify exported types are still correct. Run `pnpm check-types` across the entire monorepo after changes. |

### Verification Commands for Package Changes

```bash
# Type-check the entire monorepo
pnpm check-types

# Build all apps to catch downstream breakage
pnpm build

# Test a specific app after package changes
pnpm dev --filter=<app-name>
```

---

## i18n Maintenance

When editing any user-facing text, follow these five rules:

1. **Never hardcode UI text directly in components.** Always use translation keys that resolve from the locale files.

2. **Check existing translation files first.** Before adding a new key, search `pt.json` and `en.json` to see if a suitable key already exists.

3. **Update both locale files.** Every text change must be reflected in both `pt.json` (Portuguese) and `en.json` (English). Never update one without the other.

4. **Portuguese is the primary language.** Write the Portuguese translation first and ensure it is accurate. The Portuguese text is what most users will see.

5. **Use consistent key naming.** Follow the existing key naming convention in the translation files. Group keys by feature or page using dot notation (e.g., `reports.vlSuppression.title`).

---

## Common Maintenance Tasks

### 1. Updating API Endpoints

When an API endpoint URL, payload, or response shape changes:

1. **Find all references** to the endpoint in the affected app:
   ```bash
   grep -r "old-endpoint-path" "$MONOREPO/apps/<app-name>/" --include="*.ts" --include="*.tsx" -l
   ```

2. **Read the API response type** definition and compare it with the new response shape. Update the TypeScript interface or type alias to match.

3. **Update the fetch/query call** with the new URL, headers, or parameters. If using a centralized API client or constants file, update it there instead of in each component.

4. **Update any data transformation logic** that maps the API response to component props. If field names changed, update the mapping.

5. **Verify** by running the dev server and confirming the data loads correctly. Check the browser network tab to confirm the correct endpoint is being called with the expected payload.

### 2. Adding a Filter

When adding a new filter option to an existing filter bar or panel:

1. **Read the existing filter component** to understand the pattern — how filters are stored in state, how they are passed to API calls, and how they render.

2. **Add the filter state** in the same location and style as existing filters. If filters use a shared state object, add the new field there.

3. **Add the filter UI element** (dropdown, checkbox, date picker) following the design system components already in use. Match the layout and spacing of existing filters.

4. **Wire the filter to the data query** so that changing the filter value triggers a re-fetch or re-filter with the new parameter included.

### 3. Fixing Chart Display Issues

When a chart renders incorrectly, is missing data, or has visual defects:

1. **Reproduce the issue** by running the dev server and navigating to the affected chart. Note the exact symptoms — missing bars, wrong colors, truncated labels, empty chart, etc.

2. **Check the data** being passed to the chart component. Add a temporary `console.log` or use the browser debugger to inspect the data shape. Confirm the data matches what the chart expects.

3. **Check the chart configuration** — axis labels, scales, legend options, tooltip formatters, and responsive settings. Compare against a working chart in the same app for differences.

4. **Fix and verify** — make the correction, reload the page, and confirm the chart renders correctly. Test with different data scenarios (empty data, single data point, large datasets) if applicable.

### 4. Improving Performance

When a dashboard page is slow to load or interact with:

1. **Check data fetching** — are API calls being made redundantly? Look for fetches inside render loops, missing caching, or queries that fetch more data than needed. Optimize by adding caching, pagination, or reducing payload size.

2. **Check component re-renders** — use React DevTools Profiler to identify components that re-render excessively. Apply `React.memo`, `useMemo`, or `useCallback` where appropriate, but only where profiling confirms a real problem.

3. **Check bundle size** — run `pnpm build` and inspect the output. Look for large dependencies that could be lazy-loaded or replaced with lighter alternatives. Use dynamic `import()` for heavy components that are not needed on initial load.

4. **Check image and asset loading** — ensure images use optimized formats and appropriate sizes. Use Next.js `Image` component for automatic optimization. Lazy-load below-the-fold content.
