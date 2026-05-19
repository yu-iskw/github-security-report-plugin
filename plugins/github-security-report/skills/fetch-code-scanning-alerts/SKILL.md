---
name: fetch-code-scanning-alerts
description: List and normalize code scanning alerts (CodeQL, SARIF) for a GitHub organization or repository using gh api. Use when the user asks for code scanning, SAST, or CodeQL alerts for an org or repo.
compatibility: Requires gh CLI and jq. Network access to github.com.
license: Apache-2.0
---

# Fetch Code Scanning Alerts

Fetch open (or filtered) code scanning alerts and return a normalized JSON envelope on stdout.

## Inputs

| Input          | Required | Description                                         |
| -------------- | -------- | --------------------------------------------------- |
| `ORG`          | Yes\*    | Organization login                                  |
| `REPO`         | No       | Full repo name `owner/name`                         |
| `STATE`        | No       | Default `open`                                      |
| `TOOL_NAME`    | No       | Filter by tool (e.g. `CodeQL`)                      |
| `SUMMARY_ONLY` | No       | Default `false`. Set `true` to omit full `alerts[]` |
| `TOP_REPOS_N`  | No       | Default `10`                                        |

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

Optional CodeQL filter:

```bash
export TOOL_NAME=CodeQL
./scripts/fetch.sh
```

## References

- [Envelope schema](../../references/envelope-schema.md)
- [GitHub API rules](../../references/github-api-rules.md)
- [API rules snippet](references/api-rules-snippet.md)
- [Example output](references/example-envelope.json)

## Success criteria

- JSON envelope parses; `org` matches supplied `ORG` (or repo owner when only `REPO` is set).
- `summary.total` is correct when `SUMMARY_ONLY=true`.

## Optional / Related

- `gh-auth-security`
- `aggregate-security-report`
