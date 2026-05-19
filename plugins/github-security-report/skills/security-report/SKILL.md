---
name: security-report
description: Full org security report (Dependabot, code scanning, secret scanning). Use when the user wants an organization security overview or open-alert summary.
argument-hint: [org-login]
arguments: [org]
disable-model-invocation: true
context: fork
agent: security-report-orchestrator
allowed-tools: Bash(gh *) Bash(jq *) Read
license: Apache-2.0
---

# Security report: $org

1. Set `ORG=$org`, `STATE=open`, `SUMMARY_ONLY=true`, `TOP_REPOS_N=10`.
2. From the plugin root, run `scripts/run-report.sh --quiet` (or `2>/dev/null` without `--quiet`).
3. If any source has non-empty `errors[]`, run `skills/gh-auth-security/scripts/check-auth.sh` with the same `ORG` and explain 403 vs 404 using [github-api-rules.md](../../references/github-api-rules.md).
4. Return **Markdown** (use [report-template.md](../aggregate-security-report/references/report-template.md)) plus a compact JSON block with `totals` and `top_repos` only—do not paste full `alerts[]`.
