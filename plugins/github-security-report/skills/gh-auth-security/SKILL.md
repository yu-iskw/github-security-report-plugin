---
name: gh-auth-security
description: Check GitHub CLI authentication and scopes for security alert APIs. Use when gh api security endpoints return 403/404 or before fetching Dependabot, code scanning, or secret scanning alerts.
compatibility: Requires gh CLI. Network access to github.com.
license: Apache-2.0
---

# GitHub Auth for Security APIs

Verify that `gh` is authenticated and has scopes needed for organization and repository security alert endpoints.

## Inputs

- None required. Optionally run when the user reports permission errors on fetch skills.

## Output

Return a short JSON-shaped summary:

```json
{
  "ok": true,
  "host": "github.com",
  "account": "example-user",
  "scopes": ["repo", "read:org"],
  "hints": []
}
```

Set `ok` to `false` when `gh auth status` fails or recommended scopes are missing. Add human-readable strings to `hints`.

## Scope vs role vs HTTP status

| Symptom                                | Likely cause                                                                                    | What to check                                                                   |
| -------------------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **403** on org/repo security endpoints | Token missing scopes or insufficient repo access                                                | `gh auth status` scopes; refresh with recommended scopes below                  |
| **404** on **org-wide** list endpoints | Wrong HTTP method (`gh api -f` → POST), org login typo, or **not** org owner / security manager | Use GET + `?state=open`; verify `ORG`; try repo-scoped fetch if `REPO` is known |
| **404** on **repo** endpoint           | Repo not found, alerts not enabled, or no access to that repo                                   | Confirm `REPO=owner/name` and repository visibility                             |
| Empty `[]` with **200**                | No open alerts for that source                                                                  | Valid — `summary.total` = 0                                                     |

### Token scopes

| Scope             | Required?                     | Purpose                                                                                |
| ----------------- | ----------------------------- | -------------------------------------------------------------------------------------- |
| `repo`            | Yes (typical)                 | Repository security alert APIs                                                         |
| `read:org`        | Recommended                   | Organization metadata and some org APIs                                                |
| `security_events` | **Recommended, not required** | Documented for security APIs; many users can list alerts with `repo` + `read:org` only |

### Organization role

Separate from token scopes.

| Role                                           | Org-wide Dependabot / code scanning / secret scanning lists  |
| ---------------------------------------------- | ------------------------------------------------------------ |
| Organization **owner** or **security manager** | Usually allowed                                              |
| Member without security role                   | Often **404** on org endpoints — use **repo-scoped** fetches |

Do not confuse **403** (token/scope) with **404** (role, wrong method, or unknown org).

## Run

```bash
export ORG=your-org-login   # optional: also checks org/repo reachability
./scripts/check-auth.sh
```

## Behavior

1. Run `./scripts/check-auth.sh` (wraps `gh auth status --json`) and capture host, account, and token scopes.
2. Check for recommended scopes: `security_events`, `read:org`, `repo` (note `security_events` is recommended, not strictly required).
3. If scopes are missing, append to `hints` (do **not** run refresh without user consent):

   ```bash
   gh auth refresh -h github.com -s security_events,read:org,repo
   ```

4. On org-wide **404**, add a hint that the user may need **org owner** or **security manager**, or should retry with `REPO=owner/name` (do not guess org names).

## Success criteria

- `gh auth status` exits 0.
- Caller receives `ok`, `scopes`, and any `hints` for missing scopes.

## Optional / Related

- After fixing auth, use `fetch-dependabot-alerts`, `fetch-code-scanning-alerts`, or `fetch-secret-scanning-alerts` with a user-supplied `ORG`.
- `security-report-orchestrator` may suggest this skill when fetch skills record 403/404 errors.
