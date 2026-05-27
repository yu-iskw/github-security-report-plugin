# GitHub Security Report plugin

This repository ships the **[`github-security-report`](plugins/github-security-report/)** plugin for AI coding assistants: **agent skills**, a **sub-agent** orchestrator, and optional hooks/MCP. It provides org-agnostic GitHub security alerting via the [`gh`](https://cli.github.com/) CLI.

Works with **Claude Code**, **Cursor**, **Codex**, **GitHub Copilot**, and **Gemini CLI** (installation steps differ slightly per host). The repo is a small monorepo: marketplace manifests at the root and the plugin under `plugins/github-security-report/` (see [Repository layout](#repository-layout)).

## Prerequisites

| Tool                                         | Purpose                               |
| -------------------------------------------- | ------------------------------------- |
| [GitHub CLI (`gh`)](https://cli.github.com/) | Calls GitHub security REST APIs       |
| [`jq`](https://jqlang.org/)                  | Normalizes API output in fetch skills |
| `gh auth login`                              | Authenticated GitHub access           |

Recommended token scopes for security APIs:

```bash
gh auth refresh -h github.com -s security_events,read:org,repo
```

Org-wide alert listing typically requires **organization owner** or **security manager**. Without that role, use **repo-scoped** fetches (`REPO=owner/name`) documented in each fetch skill.

---

## Plugins in this repository

| Plugin                                                      | Description                                                                    |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [`github-security-report`](plugins/github-security-report/) | Fetch Dependabot, code scanning, and secret scanning alerts; aggregate reports |

---

## Installation

### Identifiers

| Term           | Value                                                  |
| -------------- | ------------------------------------------------------ |
| GitHub repo    | `yu-iskw/github-security-report-plugin`                |
| Marketplace ID | `github-security-report-plugin`                        |
| Plugin ID      | `github-security-report`                               |
| Install target | `github-security-report@github-security-report-plugin` |

**Claude Code scopes** (`-s`): `project` (shared via `.claude/settings.json`), `user` (all your projects), `local` (you only, this repository).

**Clone (optional):** for local paths, clone and `cd` into the repo. Use `--from-local` with `gh skill install` and do not pass `OWNER/REPO` on those commands.

```bash
git clone https://github.com/yu-iskw/github-security-report-plugin.git
cd github-security-report-plugin
```

### Option A — Install skills only (`gh skill install`)

Best when your host does not load full plugins, or you want selected skills in a project.

**Local — all skills** (from repository root after clone):

```bash
gh skill install ./plugins/github-security-report --from-local \
  --agent cursor \
  --scope project
```

Add `--allow-hidden-dirs` only if you install from paths under hidden directories (for example `.claude/skills/`).

**Local — one skill** (faster on large repos):

```bash
gh skill install ./plugins/github-security-report/skills/fetch-dependabot-alerts \
  --from-local --agent github-copilot --scope project
```

Use `--agent` for your host:

| Host           | `--agent` value  |
| -------------- | ---------------- |
| GitHub Copilot | `github-copilot` |
| Claude Code    | `claude-code`    |
| Cursor         | `cursor`         |
| Codex          | `codex`          |
| Gemini CLI     | `gemini-cli`     |

Use `--scope user` to install under your home directory instead of the project.

**Remote — one skill** (no clone). The second argument is the path inside the repository:

```bash
gh skill install yu-iskw/github-security-report-plugin \
  plugins/github-security-report/skills/fetch-dependabot-alerts \
  --agent codex --scope project
```

**All skills remotely:** run `gh skill install yu-iskw/github-security-report-plugin` and use the interactive picker, or repeat install with each path under `plugins/github-security-report/skills/<skill-name>/`.

See [`gh skill install`](https://cli.github.com/manual/gh_skill_install) for pins, versions, and updates (`gh skill update`).

### Option B — Full plugin (Claude Code)

Installs skills **and** sub-agents from the marketplace manifest.

#### Remote (no clone)

```bash
claude plugin marketplace add yu-iskw/github-security-report-plugin
claude plugin install -s project github-security-report@github-security-report-plugin
# In chat: /reload-plugins
claude plugin list
```

#### Local checkout (repository root)

```bash
claude plugin marketplace add "$(pwd)"
claude plugin install -s project github-security-report@github-security-report-plugin
# In chat: /reload-plugins
claude plugin list
```

**UI:** run `/plugin` → Discover → install `github-security-report` from marketplace `github-security-report-plugin`.

**Dev without installing:** load the plugin for one session:

```bash
claude --plugin-dir ./plugins/github-security-report
```

If marketplace add fails, point at the manifest directory:

```bash
claude plugin marketplace add ./.claude-plugin
```

Use `-s user` to install for your user instead of the project.

#### Contributors (auto-load in this repo)

[`.claude/settings.local.json`](.claude/settings.local.json) registers the in-repo marketplace and enables the plugin:

- Marketplace: `github-security-report-plugin` (directory source: repo root)
- Plugin: `github-security-report@github-security-report-plugin`

1. Open this repository in Claude Code.
2. Restart Claude Code or reload the window after pulling changes.
3. Verify: `/plugin` in chat or `claude plugin list` — you should see `github-security-report`.
4. Smoke test: ask the agent to use `security-report-orchestrator` for an organization you can access (for example `acme-corp`).

**CLI fallback** if settings do not load the marketplace:

```bash
claude plugin marketplace add "$(pwd)"
claude plugin install -s local github-security-report@github-security-report-plugin
/reload-plugins
```

### Option C — Full plugin (Cursor)

**Local checkout** (fastest for development):

```bash
mkdir -p ~/.cursor/plugins/local
ln -sf "$(pwd)/plugins/github-security-report" ~/.cursor/plugins/local/github-security-report
```

Run **Developer: Reload Window** (or restart Cursor). Components are discovered from `.cursor-plugin/plugin.json` and default folders (`skills/`, `agents/`, etc.).

**In-editor:** use the marketplace panel or `/add-plugin`. See [Cursor plugin docs](https://cursor.com/docs/plugins).

**Team marketplace** (Teams / Enterprise): admins import this GitHub repo under **Dashboard → Settings → Plugins → Team Marketplaces**. Developers install from the marketplace panel.

**Monorepo catalog:** [`.cursor-plugin/marketplace.json`](.cursor-plugin/marketplace.json) (`github-security-report-plugin`) lists plugins under `plugins/`.

### Option D — Codex

Codex discovers marketplace catalogs at [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) (legacy-compatible) or `.agents/plugins/marketplace.json`. This repo provides `.claude-plugin/` at the root; [`.codex-plugin/marketplace.json`](.codex-plugin/marketplace.json) mirrors the same catalog for packaging validation, not Codex auto-discovery.

**Remote:**

```bash
codex plugin marketplace add yu-iskw/github-security-report-plugin
```

**Local:**

```bash
codex plugin marketplace add .
```

Then open Codex → `/plugins` → marketplace `github-security-report-plugin` → install `github-security-report`.

**Fallback:** Option A with `--agent codex` (skills often land in `.agents/skills` at project scope).

### Migration (Claude Code)

If you previously used marketplace `claude-plugin-template`:

```bash
claude plugin marketplace remove claude-plugin-template
claude plugin marketplace add yu-iskw/github-security-report-plugin
claude plugin install -s project github-security-report@github-security-report-plugin
/reload-plugins
```

Update personal `enabledPlugins` keys to `github-security-report@github-security-report-plugin` if you pinned the old `@claude-plugin-template` suffix.

### Option E — GitHub Copilot

**Skills:** Option A with `--agent github-copilot`. Copilot discovers skills under project paths such as `.github/skills`, `.agents/skills`, or user `~/.copilot/skills` depending on scope.

**Manual copy** (equivalent to installing one skill):

```bash
mkdir -p .github/skills
cp -R plugins/github-security-report/skills/fetch-dependabot-alerts .github/skills/
```

**Sub-agents:** Copilot cloud agent and Copilot CLI can use repository skill layouts; the orchestrator workflow in [`security-report-orchestrator.md`](plugins/github-security-report/agents/security-report-orchestrator.md) is applied by asking Copilot to follow that agent’s instructions, or by installing the full plugin where your Copilot version supports bundled agents. See [Adding agent skills for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills).

### Option F — Gemini CLI

**Skills:** Option A with `--agent gemini-cli`, or:

```bash
gemini skills install ./plugins/github-security-report/skills/fetch-dependabot-alerts --scope workspace
```

List and enable skills in the CLI with `/skills list`. See [Gemini CLI skills](https://geminicli.com/docs/cli/skills/).

---

## Using `github-security-report`

### Concepts

| Component        | What it does                                                                                                                              |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Agent skill**  | Single job (e.g. list Dependabot alerts). Invoked by the model when relevant, or manually with `/skill-name` where your host supports it. |
| **Sub-agent**    | Coordinates **multiple skills** for one integrated goal.                                                                                  |
| **Orchestrator** | [`security-report-orchestrator`](plugins/github-security-report/agents/security-report-orchestrator.md) — full org/repo security report.  |

Always pass the **organization login** at runtime (for example `acme-corp`). The plugin does not hardcode any org.

### Slash commands (workflow skills)

User-invoked only (`disable-model-invocation: true`). In Claude Code they may appear namespaced (e.g. `github-security-report:security-report`).

| Command                                | Purpose                                        |
| -------------------------------------- | ---------------------------------------------- |
| `/security-report` `[org-login]`       | Full org report (forks orchestrator sub-agent) |
| `/security-repo-report` `[owner/name]` | One-repo report (all three alert types)        |
| `/security-auth` `[org-login]`         | Check `gh` auth and org access before fetching |

Primitive skills (`fetch-dependabot-alerts`, etc.) remain available for model auto-invoke and power users.

### Sub-agent: full security report

Available as a bundled **sub-agent** when you install the full plugin (Claude Code / Cursor). In chat, ask explicitly, for example:

```text
Use the security-report-orchestrator to generate a security report for organization acme-corp.
Include open Dependabot, code scanning, and secret scanning alerts.
```

Optional: limit to one repository:

```text
Security report for REPO acme-corp/api-service (open alerts only).
```

Prefer **`/security-report acme-corp`** or `scripts/run-report.sh --quiet`. The orchestrator should:

1. Run `plugins/github-security-report/scripts/run-report.sh --quiet` with `ORG` set (or repo-scoped fetches when `REPO` is set). See [`agents/security-report-orchestrator.md`](plugins/github-security-report/agents/security-report-orchestrator.md).
2. Return a short **Markdown** summary plus **JSON** totals (not full alert dumps unless you ask).

### Primitive skills (use individually)

| Skill                          | Use when                                   |
| ------------------------------ | ------------------------------------------ |
| `gh-auth-security`             | `gh` returns 403/404 on security endpoints |
| `fetch-dependabot-alerts`      | Dependency / GHSA / CVE alerts             |
| `fetch-code-scanning-alerts`   | CodeQL / code scanning alerts              |
| `fetch-secret-scanning-alerts` | Secret scanning alerts                     |
| `aggregate-security-report`    | Merge fetch outputs (no `gh` calls)        |

**Example prompts:**

```text
Run fetch-dependabot-alerts for organization acme-corp, state open.
```

```text
Run fetch-code-scanning-alerts for organization acme-corp with TOOL_NAME CodeQL.
```

```text
I have three JSON envelopes from the fetch skills — aggregate them with aggregate-security-report.
```

### CLI sanity check (no AI host)

Full report in one command:

```bash
export ORG=your-org-login
export SUMMARY_ONLY=true
plugins/github-security-report/scripts/run-report.sh --quiet
```

Single-source check:

```bash
export ORG=your-org-login
export SUMMARY_ONLY=true
plugins/github-security-report/skills/fetch-dependabot-alerts/scripts/fetch.sh \
  | jq '.summary.total'
```

Auth check:

```bash
export ORG=your-org-login
plugins/github-security-report/skills/gh-auth-security/scripts/check-auth.sh
```

Merge three saved envelopes:

```bash
export TOP_N=10
plugins/github-security-report/skills/aggregate-security-report/scripts/aggregate.sh \
  dependabot.json code_scanning.json secret_scanning.json
```

Use **query strings** on GET requests (`?state=open`). Do not use `gh api -f state=open` on list endpoints (that sends POST and often returns 404). See [`plugins/github-security-report/references/github-api-rules.md`](plugins/github-security-report/references/github-api-rules.md) and [`envelope-schema.md`](plugins/github-security-report/references/envelope-schema.md).

Skill `SKILL.md` files document inputs and point to per-skill scripts: [`plugins/github-security-report/skills/`](plugins/github-security-report/skills/).

---

## Troubleshooting

- **`gh api -f state=open` returns 404** — List endpoints are **GET** with query strings (`?state=open`). `-f` sends POST and breaks org/repo alert lists. Use `./scripts/fetch.sh` in each fetch skill (or see [github-api-rules.md](plugins/github-security-report/references/github-api-rules.md)).
- **Org-wide fetch returns 404 but repo works** — You may lack **organization owner** or **security manager** role. Retry with `REPO=owner/name`, or run `skills/gh-auth-security/scripts/check-auth.sh` with `ORG` set.
- **Agent reports 403 on all sources but `gh` works in your terminal** — The agent sandbox may block GitHub API calls. Allow `gh api` / plugin script execution with network, or run `scripts/run-report.sh` locally and paste the JSON summary.
- **Agent reinvents `gh api` instead of scripts** — Point it at `scripts/run-report.sh` or per-skill `scripts/fetch.sh`; inline `gh api -f` often returns 404 on list endpoints.
- **Huge responses / context limits** — For org-wide reports, set `SUMMARY_ONLY=true` (orchestrator default). Counts and `top_repos` stay accurate; `alerts[]` is omitted.
- **Example counts (e.g. 587 / 6 / 0)** — Numbers from a specific test org are **examples only**. Your org’s totals depend on enabled features and open alerts.

---

## Managing plugins and skills in the UI

| Host                  | Where to manage                                                       |
| --------------------- | --------------------------------------------------------------------- |
| **Cursor**            | Settings → Rules / Skills; marketplace panel for installs             |
| **Claude Code**       | `claude plugin list`, plugin settings in the app                      |
| **Copilot (VS Code)** | Copilot skill discovery; project `.github/skills` or `.agents/skills` |
| **Gemini CLI**        | `/skills list`, `/skills enable` / `disable`                          |

---

## Repository layout

```text
.
├── plugins/
│   ├── github-security-report/   # Security skills + orchestrator agent
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .cursor-plugin/plugin.json
│   │   ├── agents/
│   │   └── skills/
├── .claude-plugin/marketplace.json
├── .cursor-plugin/marketplace.json
├── .codex-plugin/marketplace.json
└── integration_tests/
```

---

## Development (contributors)

```bash
make lint
make test-integration-docker   # manifest + component discovery + plugin install (Claude CLI)
./integration_tests/run.sh --skip-loading
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for pull request expectations.

### Adding a plugin

Follow the [standard plugin layout](https://code.claude.com/docs/en/plugins-reference#standard-plugin-layout): `plugins/<name>/.claude-plugin/plugin.json`, `skills/`, `agents/`, etc. Register the plugin in each marketplace JSON you support.

---

## License

Apache License 2.0. See [LICENSE](LICENSE).
