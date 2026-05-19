# GitHub API rules for security fetch scripts

Apply these rules for **any** organization or repository.

1. **GET with query string** — Use `gh api "/orgs/${ORG}/dependabot/alerts?state=open"`. Never use `gh api -f state=open` on list endpoints (sends POST and often returns 404).

2. **Pagination** — Use `--paginate` for org-wide lists.

3. **Org-wide access** — `/orgs/{org}/.../alerts` requires organization **owner** or **security manager**. On 404, try repo-scoped `/repos/{owner}/{repo}/.../alerts` when `REPO` is set.

4. **No hardcoded org** — Always pass `ORG` (and optional `REPO`) via environment variables at runtime.

See [envelope-schema.md](envelope-schema.md) for the output JSON contract.
