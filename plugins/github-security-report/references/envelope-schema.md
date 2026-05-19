# Security alert envelope schema

Every fetch skill returns one JSON object on stdout with this shape. The `org` field must match the caller’s `ORG` environment variable (illustrative examples use `acme-corp` only).

## Envelope fields

| Field        | Type   | Description                                                       |
| ------------ | ------ | ----------------------------------------------------------------- |
| `source`     | string | `dependabot`, `code_scanning`, or `secret_scanning`               |
| `org`        | string | Organization login                                                |
| `scope`      | string | `org` or `repo`                                                   |
| `repo`       | string | Present when `scope` is `repo`                                    |
| `state`      | string | Alert state filter used (e.g. `open`)                             |
| `fetched_at` | string | ISO-8601 UTC timestamp                                            |
| `summary`    | object | `{ "total": number, "by_severity": { "high": number, ... } }`     |
| `top_repos`  | array  | `{ "repo": "owner/name", "count": number }`, sorted by count desc |
| `alerts`     | array  | Normalized alerts; empty when `SUMMARY_ONLY=true`                 |
| `errors`     | array  | Human-readable error strings from `gh` failures                   |

## Normalized alert (item in `alerts[]`)

```json
{
  "source": "dependabot",
  "org": "acme-corp",
  "repo": "acme-corp/api-service",
  "id": 42,
  "severity": "high",
  "title": "example-package",
  "external_id": "GHSA-xxxx-xxxx-xxxx",
  "created_at": "2026-01-15T10:00:00Z",
  "url": "https://github.com/acme-corp/api-service/security/dependabot/42"
}
```

`severity` may be `null` for secret scanning alerts.

## Minimal envelope example

```json
{
  "source": "dependabot",
  "org": "acme-corp",
  "scope": "org",
  "state": "open",
  "fetched_at": "2026-01-15T12:00:00Z",
  "summary": { "total": 0, "by_severity": {} },
  "top_repos": [],
  "alerts": [],
  "errors": []
}
```
