# Security report: {org}

Generated: {generated_at}

## Totals

| Source          |              Open alerts |
| --------------- | -----------------------: |
| Dependabot      |      {totals.dependabot} |
| Code scanning   |   {totals.code_scanning} |
| Secret scanning | {totals.secret_scanning} |
| **All**         |         **{totals.all}** |

## Top repositories (by alert count)

| Repository | Alerts |
| ---------- | -----: |
| ...        |    ... |

## Errors

{errors or "None"}

Replace placeholders from `aggregate.sh` JSON output. Do not dump full `alerts[]` unless the user requests export.
