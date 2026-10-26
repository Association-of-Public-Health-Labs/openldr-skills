# Maintenance Guide: Fix, Improve, Refactor

## 1. Scope

- Read the files involved and their tests.
- Check `git log --oneline -10 -- <file>`.
- Check the worktrees (`git worktree list`). The newest code may be on an unmerged branch.
- For bugs, use superpowers:systematic-debugging, and check `pitfalls.md` first.

## 2. Size

| Small: do it | Large: propose the files and approach, wait for approval |
|---|---|
| A label, colour or spacing; one card's bug; one filter option; one endpoint path | A new page or route group; a change to a shared package's props; auth; drill-down structure; state management; moving code between apps and packages |

Redesign requests change **visuals only**. Props, cards, menus, exports, data flow and routes stay the same, and existing tests pass unchanged.

## 3. Shared packages

Before you edit `packages/*`, find every consumer:

```bash
grep -rl "@repo/design_system/<path>" apps/ packages/ --include=*.ts --include=*.tsx
```

- Add optional props. Never rename or remove a prop without updating every consumer in the same PR.
- Inside packages, use relative imports. `@/` means the importing app's root.
- Apps never import `@repo/design_system_mui` (ESLint error). Re-export what they need through `@repo/design_system`.
- shadcn components exist only in `packages/design_system/src/components/ui/`.
- `@repo/auth` changes: test sign-in and sign-out in every app. `@repo/ai`: test the chat in TB.
- After a package change, build every app: `pnpm turbo run build --filter=tb --filter=vl --filter=<others>`. Run the package's own tests, and the apps' tests.

## 4. Verify

Run the commands in SKILL.md. For anything visual, look at the page in the running app, in light and dark mode.

## Common tasks

- **Endpoint changed:** update `constants.ts` `ENDPOINT` and `types.ts`, then `actions.test.ts`. Check the response on dev.
- **New filter option:** change it in the card's hook or wrapper, never in one card's copy.
- **Slow page:** look at the API time in the network tab first. The default 12-month requests should come from the API's report cache. Add missing ones to `tools/report_cache_seeds.py` in `api_openldr_python`.
- **Release a hidden page:** follow `deploy-guide.md` → "Releasing a page".
