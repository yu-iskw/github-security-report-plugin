---
name: fetch-dependabot-alerts
description: List and normalize Dependabot alerts for a GitHub organization or repository using gh api. Use when the user asks for dependency vulnerabilities, Dependabot alerts, GHSA, or CVE data for an org or repo.
compatibility: Requires gh CLI and jq. Network access to github.com.
license: Apache-2.0
---

# Fetch Dependabot Alerts

Fetch open (or filtered) Dependabot alerts and return a normalized JSON envelope on stdout.

## Inputs

| Input          | Required | Description                                                                     |
| -------------- | -------- | ------------------------------------------------------------------------------- |
| `ORG`          | Yes\*    | Organization login (e.g. user-provided `acme-corp`)                             |
| `REPO`         | No       | Full repo name `owner/name` — if set, use repo endpoint only                    |
| `STATE`        | No       | Default `open`. Comma-separated: `open`, `fixed`, `dismissed`, `auto_dismissed` |
| `SUMMARY_ONLY` | No       | Default `false`. Set `true` to omit full `alerts[]`                             |
| `TOP_REPOS_N`  | No       | Default `10`                                                                    |

\*If only `REPO` is given, org is derived from the owner segment of `REPO`.

**Do not hardcode any organization name in commands.**

## Run

From this skill directory:

```bash
export ORG=your-org-login
export STATE=open
export SUMMARY_ONLY=true
./scripts/fetch.sh
```

Repo-scoped:

```bash
export REPO=acme-corp/api-service
export STATE=open
./scripts/fetch.sh
```

## References

- [Envelope schema](../../references/envelope-schema.md)
- [GitHub API rules](../../references/github-api-rules.md)
- [API rules snippet](references/api-rules-snippet.md) (standalone install)
- [Example output](references/example-envelope.json)

## Error handling

| HTTP / outcome | Meaning                      | Action                                                 |
| -------------- | ---------------------------- | ------------------------------------------------------ |
| 404 on org     | Wrong method, role, or scope | GET + query string; try repo scope; `gh-auth-security` |
| 403            | Permission denied            | `errors[]` populated                                   |
| Empty `[]`     | No alerts                    | Valid: `summary.total` = 0                             |

On `gh` failure, the script returns `errors[]` without jq parse errors.

## Success criteria

- JSON envelope parses; `org` matches supplied `ORG` (or repo owner).
- `summary.total` is correct even when `SUMMARY_ONLY=true`.

## Optional / Related

- `gh-auth-security` — 403/404 on org endpoints.
- `aggregate-security-report` — merge envelopes from fetch skills.
