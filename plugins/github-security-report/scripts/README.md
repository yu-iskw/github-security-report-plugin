# Plugin scripts

## Full report (recommended)

```bash
export ORG=your-org-login
export SUMMARY_ONLY=true
./scripts/run-report.sh --quiet
```

Runs three fetch skills in parallel, then aggregates. Resolves paths from this script’s location (safe for agents regardless of cwd).

- **`--quiet`** — JSON on stdout only (no progress on stderr; safe to pipe to `jq`).

## Workflow slash commands

| Command                 | Skill directory                |
| ----------------------- | ------------------------------ |
| `/security-report`      | `skills/security-report/`      |
| `/security-repo-report` | `skills/security-repo-report/` |
| `/security-auth`        | `skills/security-auth/`        |

In Claude Code with the plugin enabled, commands may appear namespaced (e.g. `github-security-report:security-report`).

## Per-skill scripts

Executable scripts also live **inside each skill** so they work when a single skill is installed via `gh skill install`.

| Skill                          | Script                                                  |
| ------------------------------ | ------------------------------------------------------- |
| `gh-auth-security`             | `skills/gh-auth-security/scripts/check-auth.sh`         |
| `fetch-dependabot-alerts`      | `skills/fetch-dependabot-alerts/scripts/fetch.sh`       |
| `fetch-code-scanning-alerts`   | `skills/fetch-code-scanning-alerts/scripts/fetch.sh`    |
| `fetch-secret-scanning-alerts` | `skills/fetch-secret-scanning-alerts/scripts/fetch.sh`  |
| `aggregate-security-report`    | `skills/aggregate-security-report/scripts/aggregate.sh` |
