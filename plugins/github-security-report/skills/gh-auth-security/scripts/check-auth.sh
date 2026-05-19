#!/usr/bin/env bash
# Print JSON auth summary for security alert APIs.
set -euo pipefail

ORG="${ORG-}"
REPO="${REPO-}"

if ! auth_json="$(gh auth status --json hosts 2>&1)"; then
	jq -n \
		--arg err "${auth_json}" \
		'{
      ok: false,
      host: null,
      account: null,
      scopes: [],
      hints: ["gh auth status failed — run: gh auth login", $err]
    }'
	exit 0
fi

account="$(jq -r '.hosts["github.com"][] | select(.active == true) | .login' <<<"${auth_json}" | head -1)"
scopes_csv="$(jq -r '.hosts["github.com"][] | select(.active == true) | .scopes' <<<"${auth_json}" | head -1)"
scopes_json="$(printf '%s' "${scopes_csv}" | tr ',' '\n' | sed 's/^ *//' | jq -R . | jq -s .)"

hints=()
for need in repo read:org; do
	if ! printf '%s' "${scopes_csv}" | tr ',' '\n' | sed 's/^ *//' | grep -qx "${need}"; then
		hints+=("Missing scope: ${need}")
	fi
done
if ! printf '%s' "${scopes_csv}" | tr ',' '\n' | sed 's/^ *//' | grep -qx 'security_events'; then
	hints+=("Optional scope security_events not present — org-wide alert APIs may still work with repo + read:org if you are org owner or security manager")
fi

auth_ok=true
if [[ -n ${ORG} ]]; then
	if ! gh api "/orgs/${ORG}" --jq '.login' >/dev/null 2>&1; then
		hints+=("Cannot read org ${ORG} — check ORG spelling and membership")
		auth_ok=false
	fi
fi
if [[ -n ${REPO} ]]; then
	if ! gh api "/repos/${REPO}" --jq '.full_name' >/dev/null 2>&1; then
		hints+=("Cannot read repo ${REPO} — check REPO=owner/name and access")
		auth_ok=false
	fi
fi

hints_json="$(printf '%s\n' "${hints[@]-}" | jq -R . | jq -s 'map(select(length > 0))')"
for hint in "${hints[@]-}"; do
	if [[ ${hint} == Missing\ scope:* ]]; then
		auth_ok=false
		break
	fi
done
if [[ ${auth_ok} == true ]]; then
	ok_json=true
else
	ok_json=false
fi

jq -n \
	--argjson ok "${ok_json}" \
	--arg host "github.com" \
	--arg account "${account}" \
	--argjson scopes "${scopes_json}" \
	--argjson hints "${hints_json}" \
	'{ok: $ok, host: $host, account: (if $account == "" then null else $account end), scopes: $scopes, hints: $hints}'
