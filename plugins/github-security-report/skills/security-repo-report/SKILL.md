---
name: security-repo-report
description: Security report for one repository (all three alert types). Use when the user names owner/repo.
argument-hint: [owner/name]
arguments: [repo]
disable-model-invocation: true
context: fork
agent: security-report-orchestrator
allowed-tools: Bash(gh *) Bash(jq *) Read
license: Apache-2.0
---

# Security report: $repo

1. Set `REPO=$repo`, `ORG` from the owner segment (`${REPO%%/*}`), `STATE=open`, `SUMMARY_ONLY=true` (use `false` only if the user asks for sample alert URLs).
2. Run `scripts/run-report.sh --quiet` from the plugin root (supports `REPO`; see [run-report.sh](../../scripts/run-report.sh)).
3. If any `errors[]`, run `skills/gh-auth-security/scripts/check-auth.sh` with `ORG` set.
4. Return **Markdown** (use [report-template.md](../aggregate-security-report/references/report-template.md)) plus compact JSON (`totals`, `top_repos` only).
