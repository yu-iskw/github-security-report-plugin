# API rules (snippet)

1. **GET + query string** — `gh api "/orgs/${ORG}/code-scanning/alerts?state=open"`. Never `gh api -f state=open` on list endpoints.
2. **Pagination** — `--paginate` for org-wide lists.
3. **Roles** — Org endpoints need org owner or security manager; on 404, try `REPO=owner/name`.

Full details: plugin [github-api-rules.md](../../../references/github-api-rules.md) when the full plugin is installed.
