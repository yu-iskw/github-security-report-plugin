---
name: security-report-orchestrator
description: Produce an integrated GitHub organization security report for any org the user specifies. Applies fetch-* skills and aggregate-security-report. Use when the user asks for a security overview, alert summary, or org/repo security report.
---

# Security Report Orchestrator

Compose primitive fetch skills into one org- or repo-scoped security report. **Never assume or default an organization name** — always take `ORG` from the user (or derive it from `REPO`).

## Role

Orchestrate data collection and aggregation only. Invoked by **`/security-report`** and **`/security-repo-report`** workflow skills (forked sub-agent). Prefer **`plugins/github-security-report/scripts/run-report.sh`** (one command, parallel fetches, temp files). Otherwise run each skill’s **`scripts/*.sh`** — never invent ad-hoc `gh api` one-liners (especially `gh api -f`, which breaks list endpoints).

## Inputs

| Input   | Required                  | Default                                         |
| ------- | ------------------------- | ----------------------------------------------- |
| `ORG`   | Yes, unless `REPO` is set | —                                               |
| `REPO`  | No                        | — (`owner/name` limits all fetches to one repo) |
| `STATE` | No                        | `open`                                          |

If the user omits `ORG`, ask which GitHub organization to report on before fetching.

## Execution checklist

Follow these steps in order.

### 1. Resolve scope

- Set `ORG` from the user message (never hardcode an org in this repo).
- If `REPO` is provided, set `ORG` to the owner segment (`${REPO%%/*}`) for aggregation.
- Export for all fetch scripts:

```bash
export ORG="<user-supplied-org-login>"
export STATE="${STATE:-open}"
export SUMMARY_ONLY=true          # org-wide: always true unless user asks for full alert export
export TOP_REPOS_N="${TOP_REPOS_N:-10}"
# Optional: export REPO=owner/name for repo-scoped fetches
# Optional: export TOOL_NAME=CodeQL for code scanning
```

### 2. API rules (mandatory)

See [github-api-rules.md](../references/github-api-rules.md):

1. **GET** with query strings (`?state=open`). **Never** `gh api -f state=open` on list endpoints.
2. Use skill scripts (they call `gh api ... --paginate` with temp files + `jq -s`).

### 3. Fetch and aggregate (preferred)

From the repository root (or any cwd — the script resolves its own path):

```bash
export ORG="<user-supplied-org-login>"
export SUMMARY_ONLY=true
plugins/github-security-report/scripts/run-report.sh --quiet
```

This runs three fetches in parallel, writes temp JSON files, and prints the merged report on stdout. Use `--quiet` when piping to `jq`; without it, progress lines go to stderr.

**Manual alternative** — run each `./scripts/fetch.sh` under the fetch skills and pass file paths to `aggregate.sh`. Do **not** hold large JSON in shell variables when `SUMMARY_ONLY=false`; write files directly.

| Skill                          | Script                                                 |
| ------------------------------ | ------------------------------------------------------ |
| `fetch-dependabot-alerts`      | `skills/fetch-dependabot-alerts/scripts/fetch.sh`      |
| `fetch-code-scanning-alerts`   | `skills/fetch-code-scanning-alerts/scripts/fetch.sh`   |
| `fetch-secret-scanning-alerts` | `skills/fetch-secret-scanning-alerts/scripts/fetch.sh` |

Save each JSON envelope (stdout) to a variable or temp file.

### 4. Handle partial failure

- If any envelope has non-empty `errors[]`, include them in the final report.
- If all org fetches return errors (404/403), run `skills/gh-auth-security/scripts/check-auth.sh` with `ORG` set and suggest repo-scoped retry when `REPO` is known.
- Still pass partial envelopes to aggregate (zeros for failed sources).

### 5. Present results

If you used `run-report.sh`, the JSON summary is already on stdout. Otherwise aggregate with `aggregate.sh` on temp files (not `echo` into variables).

Produce **JSON summary** plus **Markdown** using [report-template.md](../skills/aggregate-security-report/references/report-template.md).

### 6. Output limits

- Do not paste full `alerts[]` unless the user asked for export (`SUMMARY_ONLY=false`).
- Show totals, severity rollup, top repositories, and sample alert URLs only if helpful.

## Skills used

| Skill                          | Purpose                                |
| ------------------------------ | -------------------------------------- |
| `fetch-dependabot-alerts`      | Dependency / GHSA alerts               |
| `fetch-code-scanning-alerts`   | CodeQL / SAST alerts                   |
| `fetch-secret-scanning-alerts` | Secret scanning alerts                 |
| `aggregate-security-report`    | Merge envelopes → report               |
| `gh-auth-security`             | Optional, on 403/404 permission errors |

## References

- [Envelope schema](../references/envelope-schema.md)
- [GitHub API rules](../references/github-api-rules.md)

## Examples

- User: "Security report for org **acme-corp**" → `ORG=acme-corp`, `SUMMARY_ONLY=true`, run three fetch scripts, aggregate.
- User: "Dependabot and secrets for **acme-corp/web-app**" → `REPO=acme-corp/web-app`, repo-scoped fetch scripts, aggregate.

## Success criteria

- Report references the user-supplied `ORG` (not a hardcoded org).
- `summary.total` in each fetch envelope is correct even when `SUMMARY_ONLY=true`.
- Totals and top repos are present in Markdown and JSON.
- Errors from fetch skills are surfaced when present.
