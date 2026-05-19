#!/usr/bin/env bash
# End-to-end org/repo security report: three fetches (parallel) + aggregate.
# Usage: ORG=your-org-login ./scripts/run-report.sh [--quiet]
#   --quiet  JSON on stdout only (no progress on stderr; safe to pipe to jq)
set -euo pipefail

QUIET=false
if [[ ${1-} == --quiet ]]; then
	QUIET=true
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ORG="${ORG-}"
if [[ -z ${ORG} && -n ${REPO-} ]]; then
	ORG="${REPO%%/*}"
fi
ORG="${ORG:?set ORG to the target organization login (or set REPO=owner/name)}"

export ORG
export STATE="${STATE:-open}"
export SUMMARY_ONLY="${SUMMARY_ONLY:-true}"
export TOP_REPOS_N="${TOP_REPOS_N:-10}"
[[ -n ${REPO-} ]] && export REPO
[[ -n ${TOOL_NAME-} ]] && export TOOL_NAME

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

fetch() {
	local name="$1"
	local script="$2"
	"${script}" >"${tmpdir}/${name}.json"
}

if [[ ${QUIET} != true ]]; then
	echo "Fetching Dependabot, code scanning, and secret scanning for org=${ORG} (SUMMARY_ONLY=${SUMMARY_ONLY})..." >&2
fi

fetch dependabot "${ROOT}/skills/fetch-dependabot-alerts/scripts/fetch.sh" &
pid_db=$!
fetch code_scanning "${ROOT}/skills/fetch-code-scanning-alerts/scripts/fetch.sh" &
pid_cs=$!
fetch secret_scanning "${ROOT}/skills/fetch-secret-scanning-alerts/scripts/fetch.sh" &
pid_ss=$!

for pid in "${pid_db}" "${pid_cs}" "${pid_ss}"; do
	wait "${pid}"
done

if [[ ${QUIET} != true ]]; then
	for f in dependabot code_scanning secret_scanning; do
		jq -c --arg f "${f}" '{file: $f, source, total: .summary.total, errors}' "${tmpdir}/${f}.json"
	done >&2
fi

"${ROOT}/skills/aggregate-security-report/scripts/aggregate.sh" \
	"${tmpdir}/dependabot.json" \
	"${tmpdir}/code_scanning.json" \
	"${tmpdir}/secret_scanning.json"
