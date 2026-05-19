#!/usr/bin/env bash
set -euo pipefail

TOP_N="${TOP_N:-10}"

if [[ $# -eq 0 ]]; then
	echo "Usage: aggregate.sh envelope.json [envelope2.json ...]" >&2
	exit 1
fi

jq -s --argjson top_n "${TOP_N}" '
  def total($src): ([.[] | select(.source == $src) | .summary.total] | add // 0);
  def repo_weights:
    if ((.alerts // []) | length) > 0 then
      (.alerts[] | {repo: .repo, weight: 1})
    else
      (.top_repos[]? | {repo: .repo, weight: .count})
    end;
  {
    org: ([.[].org] | map(select(. != null)) | .[0] // "unknown"),
    generated_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    totals: {
      dependabot: total("dependabot"),
      code_scanning: total("code_scanning"),
      secret_scanning: total("secret_scanning"),
      all: (total("dependabot") + total("code_scanning") + total("secret_scanning"))
    },
    severity: (
      [.[] | .summary.by_severity // {} | to_entries[]]
      | group_by(.key)
      | map({key: .[0].key, value: (map(.value) | add)})
      | from_entries
    ),
    top_repos: (
      [.[] | repo_weights]
      | group_by(.repo)
      | map({repo: .[0].repo, count: (map(.weight) | add)})
      | sort_by(-.count)
      | .[0:$top_n]
    ),
    errors: ([.[] | .errors[]?] | unique),
    sources: ([.[] | {source, scope, total: .summary.total, fetched_at}])
  }
' "$@"
