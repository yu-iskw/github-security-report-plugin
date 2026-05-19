---
name: aggregate-security-report
description: Merge normalized envelopes from fetch-dependabot-alerts, fetch-code-scanning-alerts, and fetch-secret-scanning-alerts into one JSON summary and Markdown report. Use after fetch skills complete. Does not call gh.
compatibility: Requires jq when merging via shell.
license: Apache-2.0
---

# Aggregate Security Report

Combine fetch skill outputs into a single integrated report. This skill does **not** call `gh` or GitHub APIs.

## Inputs

Provide one or more JSON envelopes (files or stdin) from:

- `fetch-dependabot-alerts`
- `fetch-code-scanning-alerts`
- `fetch-secret-scanning-alerts`

Optional: `TOP_N` (default `10`) for the top-repositories table.

## Run

Save envelopes to files (any subset allowed), then from this skill directory:

```bash
export TOP_N=10
./scripts/aggregate.sh dependabot.json code_scanning.json secret_scanning.json
```

Prefer merging **in memory** when the agent holds all three envelopes; use files only when outputs are large.

Do not use `add` on `by_severity` objects — overlapping keys would be overwritten instead of summed (the script sums by key).

## References

- [Envelope schema](../../references/envelope-schema.md)
- [Markdown template](references/report-template.md)

## Output

Present JSON from `aggregate.sh` plus Markdown using [report-template.md](references/report-template.md).

Do not dump full `alerts[]` unless the user requests export.

## Success criteria

- `org` in the report matches the user-supplied organization.
- `totals` reflect sum of input envelopes.
- Markdown and JSON summary are both returned.

## Optional / Related

- Run after `security-report-orchestrator` fetch phase.
- Individual fetch skills can be run alone without aggregation.
