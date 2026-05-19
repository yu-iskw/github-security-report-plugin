---
name: security-auth
description: Check gh auth and org access before security fetches. Use when gh returns 403/404 or before first report on an org.
argument-hint: [org-login]
arguments: [org]
disable-model-invocation: true
allowed-tools: Bash(gh *) Bash(jq *) Read
license: Apache-2.0
---

# Auth check: $org

Run:

```bash
export ORG=$org
${CLAUDE_SKILL_DIR}/../gh-auth-security/scripts/check-auth.sh
```

Summarize `ok`, `scopes`, and `hints` in plain language. If `ok` is false, suggest `gh auth refresh -h github.com -s security_events,read:org,repo` only with user consent.
