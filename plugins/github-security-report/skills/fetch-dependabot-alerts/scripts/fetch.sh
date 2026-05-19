#!/usr/bin/env bash
set -euo pipefail

format_api_error() {
	local msg="$1"
	if [[ ${msg} == *Forbidden* ]]; then
		echo "HTTP 403 Forbidden — check token scopes (repo, read:org) and org role (owner or security manager). Run gh-auth-security/scripts/check-auth.sh with ORG set."
	elif [[ ${msg} == *"Not Found"* ]]; then
		echo "HTTP 404 Not Found — use GET with ?state= (not gh api -f), verify ORG, or set REPO=owner/name."
	else
		echo "${msg}"
	fi
}

STATE="${STATE:-open}"
SUMMARY_ONLY="${SUMMARY_ONLY:-false}"
TOP_REPOS_N="${TOP_REPOS_N:-10}"

if [[ -n ${REPO-} ]]; then
	ORG="${ORG:-${REPO%%/*}}"
	GH_API_PATH="/repos/${REPO}/dependabot/alerts?state=${STATE}"
	SCOPE="repo"
else
	ORG="${ORG:?set ORG to the target organization login}"
	GH_API_PATH="/orgs/${ORG}/dependabot/alerts?state=${STATE}"
	SCOPE="org"
fi

summary_only_json=$([[ ${SUMMARY_ONLY} == "true" ]] && echo true || echo false)

tmp="$(mktemp)"
err="$(mktemp)"
trap 'rm -f "$tmp" "$err"' EXIT

if ! gh api "${GH_API_PATH}" --paginate >"${tmp}" 2>"${err}"; then
	err_raw=$(head -c 500 <"${err}" | tr '\n' ' ')
	err_msg=$(format_api_error "${err_raw}")
	jq -n \
		--arg org "${ORG}" \
		--arg scope "${SCOPE}" \
		--arg state "${STATE}" \
		--arg repo "${REPO-}" \
		--arg err "${err_msg}" \
		'{
      source: "dependabot",
      org: $org,
      scope: $scope,
      state: $state,
      repo: (if $scope == "repo" then $repo else null end),
      fetched_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
      alerts: [],
      summary: { total: 0, by_severity: {} },
      top_repos: [],
      errors: [$err]
    }'
	exit 0
fi

jq -s \
	--arg org "${ORG}" \
	--arg scope "${SCOPE}" \
	--arg state "${STATE}" \
	--arg repo "${REPO-}" \
	--argjson top_n "${TOP_REPOS_N}" \
	--argjson summary_only "${summary_only_json}" \
	'
  def map_alert($org):
    {
      source: "dependabot",
      org: $org,
      repo: (.repository.full_name // (if $scope == "repo" then $repo else null end)),
      id: .number,
      severity: .security_vulnerability.severity,
      title: .security_vulnerability.package.name,
      external_id: .security_advisory.ghsa_id,
      created_at: .created_at,
      url: .html_url
    };
  def by_severity($alerts):
    ($alerts | group_by(.severity) | map({(.[0].severity): length}) | add // {});
  def top_repos($alerts; $n):
    ($alerts | group_by(.repo) | map({repo: .[0].repo, count: length}) | sort_by(-.count) | .[0:$n]);
  (add // []) as $raw
  | ($raw | map(map_alert($org))) as $alerts
  | {
      source: "dependabot",
      org: $org,
      scope: $scope,
      repo: (if $scope == "repo" then $repo else null end),
      state: $state,
      fetched_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
      summary: { total: ($alerts | length), by_severity: by_severity($alerts) },
      top_repos: top_repos($alerts; $top_n),
      alerts: (if $summary_only then [] else $alerts end),
      errors: []
    }
  ' "${tmp}"
